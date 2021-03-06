#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#import <GLUT/glut.h>

#include <stdlib.h>

#include "imgui.h"

#define NUM_TEST_MOVIES		6

// @RemoteImgui begin
//#include "imgui_remote.h"
#define VCANVAS_WIDTH  8192
#define VCANVAS_HEIGHT 8192
// @RemoteImgui end
#define OFFSETOF(TYPE, ELEMENT) ((size_t)&(((TYPE *)0)->ELEMENT))
static float highDpiScale = 1.0;
static bool g_mousePressed[2] = { false, false };
static float g_mouseCoords[2] = {0,0};
static clock_t g_lastClock;
static unsigned int g_windowWidth, g_windowHeight;
static unsigned int g_backingWidth, g_backingHeight;

void ImImpl_RenderDrawLists(ImDrawData* draw_data)
{
	// @RemoteImgui begin
//	ImGui::RemoteDraw(draw_data->CmdLists, draw_data->CmdListsCount);
	// @RemoteImgui end
    
    // We are using the OpenGL fixed pipeline to make the example code simpler to read!
    // A probable faster way to render would be to collate all vertices from all cmd_lists into a single vertex buffer.
    // Setup render state: alpha-blending enabled, no face culling, no depth testing, scissor enabled, vertex/texcoord/color pointers.
    glPushAttrib(GL_ENABLE_BIT | GL_COLOR_BUFFER_BIT | GL_TRANSFORM_BIT);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_CULL_FACE);
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_SCISSOR_TEST);
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    glEnable(GL_TEXTURE_2D);
    //glUseProgram(0); // You may want this if using this code in an OpenGL 3+ context

    // Setup orthographic projection matrix
    const float width = g_windowWidth;
    const float height = g_windowHeight;
    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    glOrtho(0.0f, width, height, 0.0f, -1.0f, +1.0f);
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();

    // Render command lists
#define OFFSETOF(TYPE, ELEMENT) ((size_t)&(((TYPE *)0)->ELEMENT))
    for (int n = 0; n < draw_data->CmdListsCount; n++)
    {
        const ImDrawList* cmd_list = draw_data->CmdLists[n];
        const unsigned char* vtx_buffer = (const unsigned char*)&cmd_list->VtxBuffer.front();
        const ImDrawIdx* idx_buffer = &cmd_list->IdxBuffer.front();
        glVertexPointer(2, GL_FLOAT, sizeof(ImDrawVert), (void*)(vtx_buffer + OFFSETOF(ImDrawVert, pos)));
        glTexCoordPointer(2, GL_FLOAT, sizeof(ImDrawVert), (void*)(vtx_buffer + OFFSETOF(ImDrawVert, uv)));
        glColorPointer(4, GL_UNSIGNED_BYTE, sizeof(ImDrawVert), (void*)(vtx_buffer + OFFSETOF(ImDrawVert, col)));

        for (int cmd_i = 0; cmd_i < cmd_list->CmdBuffer.size(); cmd_i++)
        {
            const ImDrawCmd* pcmd = &cmd_list->CmdBuffer[cmd_i];
            if (pcmd->UserCallback)
            {
                pcmd->UserCallback(cmd_list, pcmd);
            }
            else
            {
                glBindTexture(GL_TEXTURE_2D, (GLuint)(intptr_t)pcmd->TextureId);
                glScissor((GLint)(pcmd->ClipRect.x*highDpiScale),
                    (GLint)((height - pcmd->ClipRect.w)*highDpiScale),
                    (GLint)((pcmd->ClipRect.z - pcmd->ClipRect.x)*highDpiScale),
                    (GLint)((pcmd->ClipRect.w - pcmd->ClipRect.y)*highDpiScale));

                glDrawElements(GL_TRIANGLES, (GLsizei)pcmd->ElemCount, GL_UNSIGNED_SHORT, idx_buffer);
            }
            idx_buffer += pcmd->ElemCount;
        }
    }
#undef OFFSETOF

    // Restore modified state
    glDisableClientState(GL_COLOR_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
    glBindTexture(GL_TEXTURE_2D, 0);
    glMatrixMode(GL_MODELVIEW);
    glPopMatrix();
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    glPopAttrib();
}

void LoadFontsTexture()
{
    ImGuiIO& io = ImGui::GetIO();
// load additional fonts
    io.Fonts->AddFontDefault();

	NSArray *fontArray = [[NSBundle mainBundle] pathsForResourcesOfType:@"ttf" inDirectory:nil ];
	for (NSString *path in fontArray)
		{
		char path_s[ 512 ];
		[ path getCString:path_s maxLength:512 encoding:NSASCIIStringEncoding ];
		io.Fonts->AddFontFromFileTTF( path_s, 16.0 );
		}
	
#if 0
	NSString *path = [[NSBundle mainBundle] pathForResource:@"Karla-Regular" ofType:@"ttf"];
	char path_s[ 512 ];
	[ path getCString:path_s maxLength:512 encoding:NSASCIIStringEncoding ];
	io.Fonts->AddFontFromFileTTF( path_s, 16.0 );
 #endif
	
	unsigned char* pixels;
    int width, height;
    io.Fonts->GetTexDataAsAlpha8(&pixels, &width, &height);

    GLuint tex_id;
    glGenTextures(1, &tex_id);
    glBindTexture(GL_TEXTURE_2D, tex_id);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, width, height, 0, GL_ALPHA, GL_UNSIGNED_BYTE, pixels);

    // Store our identifier
    io.Fonts->TexID = (void *)(intptr_t)tex_id;
}

void IMGUIExample_InitImGui()
{
    ImGuiIO& io = ImGui::GetIO();
    // Time elapsed since last frame, in seconds
    // (in this sample app we'll override this every frame because our time step is variable)

    
    io.DeltaTime = 1.0f/60.0f;
    
    io.RenderDrawListsFn = ImImpl_RenderDrawLists;
    
    LoadFontsTexture();
	// @RemoteImgui begin
//	ImGui::RemoteInit("0.0.0.0", 7002); // local host, local port
	//ImGui::GetStyle().WindowRounding = 0.f; // no rounding uses less bandwidth
	io.DisplaySize = ImVec2((float)VCANVAS_WIDTH, (float)VCANVAS_HEIGHT);
	// @RemoteImgui end
}

float	loadFloat( const char *path, float	defaultValue )
{
	float	ret = defaultValue;
 	NSUserDefaults *defaults = [ NSUserDefaults standardUserDefaults ];
	NSString	*pKey = [ NSString stringWithUTF8String: path ];
	if ( [ defaults objectForKey:pKey ] )
		{
		ret  = [ defaults floatForKey:pKey ];
		}
	return ret;
}

void	saveFloat( const char *path, float	saveValue )
{
 	NSUserDefaults *defaults = [ NSUserDefaults standardUserDefaults ];
	[defaults setFloat:saveValue forKey:[ NSString stringWithUTF8String: path ] ];
}

Boolean	loadBoolean( const char *path, Boolean	defaultValue )
{
	Boolean	ret = defaultValue;
 	NSUserDefaults *defaults = [ NSUserDefaults standardUserDefaults ];
	NSString	*pKey = [ NSString stringWithUTF8String: path ];
	if ( [ defaults objectForKey:pKey ] )
		{
		ret  = [ defaults boolForKey:pKey ];
		}
	return ret;
}

void	saveBoolean( const char *path, Boolean	saveValue )
{
 	NSUserDefaults *defaults = [ NSUserDefaults standardUserDefaults ];
	[defaults setBool:saveValue forKey:[ NSString stringWithUTF8String: path ] ];
}

static float		teapotSize = loadFloat( "teapot/size", 0.5 );
static float		teapotSize2 = loadFloat( "teapot2/size", 0.3 );
static Boolean		exampleWindowVisible = loadBoolean( "window/example/visible", false );

void IMGUIExample_Draw(double elapsedMilliseconds)
{
    ImGuiIO& io = ImGui::GetIO();
    // Setup resolution (every frame to accommodate for window resizing)
    int w,h;
    int display_w, display_h;
    display_w = g_backingWidth;
    display_h = g_backingHeight;
    w = g_windowWidth;
    h = g_windowHeight;
    highDpiScale = g_backingWidth / g_windowWidth;
    // Display size, in pixels. For clamping windows positions.
    //io.DisplaySize = ImVec2((float)g_windowWidth, (float)g_windowHeight);
    io.DisplaySize = ImVec2((float)VCANVAS_WIDTH, (float)VCANVAS_HEIGHT);
    io.DeltaTime = elapsedMilliseconds/1000.0; //convert in seconds
    // @RemoteImgui begin

//	ImGui::RemoteUpdate();
//	ImGui::RemoteInput input;
    if (0/*ImGui::RemoteGetInput(input)*/)
	{
#if 0
		for (int i = 0; i < 256; i++)
			io.KeysDown[i] = input.KeysDown[i];
		io.KeyCtrl = input.KeyCtrl;
		io.KeyShift = input.KeyShift;
		io.MousePos = input.MousePos;
        g_mouseCoords[0] = io.MousePos.x;
        g_mouseCoords[1] = io.MousePos.y;
		io.MouseDown[0] = (input.MouseButtons & 1);
		io.MouseDown[1] = (input.MouseButtons & 2) != 0;
		io.MouseWheel += input.MouseWheelDelta / highDpiScale;

        // Keyboard mapping. ImGui will use those indices to peek into the io.KeyDown[] array.
        io.KeyMap[ImGuiKey_Tab] = ImGuiKey_Tab;
        io.KeyMap[ImGuiKey_LeftArrow] = ImGuiKey_LeftArrow;
        io.KeyMap[ImGuiKey_RightArrow] = ImGuiKey_RightArrow;
        io.KeyMap[ImGuiKey_UpArrow] = ImGuiKey_UpArrow;
        io.KeyMap[ImGuiKey_DownArrow] = ImGuiKey_DownArrow;
        io.KeyMap[ImGuiKey_Home] = ImGuiKey_Home;
        io.KeyMap[ImGuiKey_End] = ImGuiKey_End;
        io.KeyMap[ImGuiKey_Delete] = ImGuiKey_Delete;
        io.KeyMap[ImGuiKey_Backspace] = ImGuiKey_Backspace;
        io.KeyMap[ImGuiKey_Enter] = 13;
        io.KeyMap[ImGuiKey_Escape] = 27;
        io.KeyMap[ImGuiKey_A] = 'a';
        io.KeyMap[ImGuiKey_C] = 'c';
        io.KeyMap[ImGuiKey_V] = 'v';
        io.KeyMap[ImGuiKey_X] = 'x';
        io.KeyMap[ImGuiKey_Y] = 'y';
        io.KeyMap[ImGuiKey_Z] = 'z';
#endif
    }
	else // @RemoteImgui end
	{
        // Setup inputs
        double mouse_x = 0, mouse_y = 0;
        mouse_x = g_mouseCoords[0];
        mouse_y = g_mouseCoords[1];
        // Mouse position, in pixels (set to -1,-1 if no mouse / on another screen, etc.)
        io.MousePos = ImVec2((float)mouse_x, (float)mouse_y);
        io.MouseDown[0] = g_mousePressed[0];

        // If a mouse press event came, always pass it as "mouse held this frame",
        // so we don't miss click-release events that are shorter than 1 frame.

        io.MouseDown[1] = g_mousePressed[1];
        
        // Keyboard mapping. ImGui will use those indices to peek into the io.KeyDown[] array.
        io.KeyMap[ImGuiKey_Tab] = 9;
        io.KeyMap[ImGuiKey_LeftArrow] = ImGuiKey_LeftArrow;
        io.KeyMap[ImGuiKey_RightArrow] = ImGuiKey_RightArrow;
        io.KeyMap[ImGuiKey_UpArrow] = ImGuiKey_UpArrow;
        io.KeyMap[ImGuiKey_DownArrow] = ImGuiKey_DownArrow;
        io.KeyMap[ImGuiKey_Home] = ImGuiKey_Home;
        io.KeyMap[ImGuiKey_End] = ImGuiKey_End;
        io.KeyMap[ImGuiKey_Delete] = ImGuiKey_Delete;
        io.KeyMap[ImGuiKey_Backspace] = 127;
        io.KeyMap[ImGuiKey_Enter] = 13;
        io.KeyMap[ImGuiKey_Escape] = 27;
        io.KeyMap[ImGuiKey_A] = 'a';
        io.KeyMap[ImGuiKey_C] = 'c';
        io.KeyMap[ImGuiKey_V] = 'v';
        io.KeyMap[ImGuiKey_X] = 'x';
        io.KeyMap[ImGuiKey_Y] = 'y';
        io.KeyMap[ImGuiKey_Z] = 'z';
    }
    // Start the frame
    ImGui::NewFrame();
//    static bool show_test_window = true;
    static bool show_another_window = false;
    static ImVec4 clear_col = ImColor(114, 144, 154);

    // 1. Show a simple window
    // Tip: if we don't call ImGui::Begin()/ImGui::End() the widgets appears in a window automatically called "Debug"
    {
        ImGui::Text("Hello, world!");
        ImGui::SliderFloat("teapot 1", &teapotSize, 0.0f, 1.0f);
        ImGui::SliderFloat("teapot 2", &teapotSize2, 0.0f, 1.0f);
        ImGui::ColorEdit3("clear color", (float*)&clear_col);
        if (ImGui::Button("Test Window")) exampleWindowVisible ^= 1;
        if (ImGui::Button("Another Window")) show_another_window ^= 1;
        ImGui::Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / ImGui::GetIO().Framerate, ImGui::GetIO().Framerate);
        ImGui::Text("Mouse X=%.1f, Y=%.1f", ImGui::GetIO().MousePos.x, ImGui::GetIO().MousePos.y);
    }

    // 2. Show another simple window, this time using an explicit Begin/End pair
    if (show_another_window)
    {
        ImGui::Begin("Another Window", &show_another_window, ImVec2(200,100));
        ImGui::Text("Hello");
        ImGui::End();
    }

    // 3. Show the ImGui test window. Most of the sample code is in ImGui::ShowTestWindow()
    if ( exampleWindowVisible )
    {
        ImGui::SetNextWindowPos(ImVec2(650, 20), ImGuiSetCond_FirstUseEver);
        ImGui::ShowTestWindow();
    }

    // Rendering
    GLsizei width  = (GLsizei)(g_backingWidth);
    GLsizei height = (GLsizei)(g_backingHeight);
    glViewport(0, 0, width, height);
    glClearColor(clear_col.x, clear_col.y, clear_col.z, clear_col.w);
    glClear(GL_COLOR_BUFFER_BIT);
	

 //   ImGui::Render();
}

//------------------------------------------------------------------
// my edit text dialog
//------------------------------------------------------------------

#if 0
@interface MyEditTextWindowController ()
@property (weak) IBOutlet NSSecureTextField *passwordField;
@end

@implementation MyEditTextWindowController

- (IBAction)okCancelAction:(NSButton *)sender
{
    [NSApp stopModalWithCode:sender.tag]; // the OK button's tag should be 1
    [self.window close];
}

+ (NSString*)run
{
    MyEditTextWindowController* windowController =
        [[MyEditTextWindowController alloc] initWithWindowNibName:@"testEditText"];
    if ([NSApp runModalForWindow:windowController.window])
        return windowController.passwordField.stringValue;
    return nil;
}

@end
#endif
//------------------------------------------------------------------
// IMGUIExampleView
//------------------------------------------------------------------
#import "Texture.h"
#import "avplayerload.h"

@interface IMGUIExampleView : NSOpenGLView
{
	Texture 			*texture1;
	GLint 				texture1Name;
	Texture 			*texture2;
	GLint 				texture2Name;
	MyAVplayerload		*theAVGLPlayers[ NUM_TEST_MOVIES ];
	MyAVplayerload		*theAVGLPlayer;
	MyAVplayerload		*theAVGLPlayer2;
    NSTimer *animationTimer;
}
@end

@implementation IMGUIExampleView

-(void)animationTimerFired:(NSTimer*)timer
{
    [self setNeedsDisplay:YES];
}

-(id)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)format
{
    self = [super initWithFrame:frameRect pixelFormat:format];
    if (self)
    {
        g_lastClock = clock();
    }
    return(self);
}

- (void)prepareOpenGL
{
    [super prepareOpenGL];
    
#if	1//ndef DEBUG
    GLint swapInterval = 1;
    [[self openGLContext] setValues:&swapInterval forParameter:NSOpenGLCPSwapInterval];


    if (swapInterval == 0)
    {
        NSLog(@"Error: Cannot set swap interval.");
    }
#endif
	if ( !texture1Name )
		{
		NSString *path = [[NSBundle mainBundle] pathForResource:@"glgui_texture_packer_070616" ofType:@"png"];
		
		
		texture1 = [ [Texture alloc] initWithPath:path];
		texture1Name = [texture1 textureName];

		NSString *path2 = [[NSBundle mainBundle] pathForResource:@"Earth" ofType:@"jpg"];
		texture2 = [ [Texture alloc] initWithPath:path2 ];
		texture2Name = [texture2 textureName ];

#if 1
		#define	TEST_FILE_PATH		"Macintosh HD 10_9_5:Users:richardb:Desktop:Turn screw media:001 test:001 full wall17_1 AIC.mov"
		#define	TEST_FILE_PATH2		"file:///Volumes/Macintosh%20HD%2010_9_5/Users/richardb/Desktop/Turn%20screw%20media/001%20test/001%20full%20wall17_1%20AIC.mov"
		#define	TEST_FILE_PATH3		"Macintosh HD 10_9_5:Users:richardb:Desktop:Turn screw media:001 test:001 full wall17_1 AIC.mov"
		#define	TEST_FILE_PATH4		"/Volumes/Macintosh HD 10_9_5/Users/richardb/Desktop/Turn screw media/001 test/001 full wall17_1 AIC.mov"

		theAVGLPlayer = [ [ MyAVplayerload  alloc] initWithCGLContextObj:[[self openGLContext] CGLContextObj] pixelFormat:[[self pixelFormat] CGLPixelFormatObj] fileurl:@TEST_FILE_PATH4
		 
		    ];
	//	theAVGLPlayer2 = [ [ MyAVplayerload  alloc] initWithCGLContextObj:[[self openGLContext] CGLContextObj] pixelFormat:[[self pixelFormat] CGLPixelFormatObj] fileurl:@"/Users/richardb/Desktop/Turn screw media/001 test/003     005_MainsPianiste.mov" ];
	//	theAVGLPlayer2 = [ [ MyAVplayerload  alloc] initWithCGLContextObj:[[self openGLContext] CGLContextObj] pixelFormat:[[self pixelFormat] CGLPixelFormatObj] fileurl:@"/Users/richardb/Desktop/Turn screw media/006 turn screw export cat media/049 mad test 1+blackB-Apple ProRes 422 Proxy.mov" ];
#else
#if 0
		theAVGLPlayer = [ [ MyAVplayerload  alloc] initWithCGLContextObj:[[self openGLContext] CGLContextObj] pixelFormat:[[self pixelFormat] CGLPixelFormatObj] fileurl:@"/Users/richardb/Desktop/Turn screw media/001 test/001 full wall17_1 AIC-Apple ProRes 422 LT.mov" ];
	//	theAVGLPlayer2 = [ [ MyAVplayerload  alloc] initWithCGLContextObj:[[self openGLContext] CGLContextObj] pixelFormat:[[self pixelFormat] CGLPixelFormatObj] fileurl:@"/Users/richardb/Desktop/Turn screw media/001 test/003     005_MainsPianiste.mov" ];
		theAVGLPlayer2 = [ [ MyAVplayerload  alloc] initWithCGLContextObj:[[self openGLContext] CGLContextObj] pixelFormat:[[self pixelFormat] CGLPixelFormatObj] fileurl:@"/Users/richardb/Desktop/Turn screw media/006 turn screw export cat media/049 mad test 1+blackB-Apple ProRes 422 Proxy.mov" ];
#endif
		for ( UInt32	whichMovie = 0 ; whichMovie <  NUM_TEST_MOVIES ; whichMovie ++ )
			{
			theAVGLPlayers[ whichMovie ] = [ [ MyAVplayerload  alloc] initWithCGLContextObj:[[self openGLContext] CGLContextObj] pixelFormat:[[self pixelFormat] CGLPixelFormatObj] fileurl:@"/Users/richardb/Desktop/Turn screw media/001 test/001 full wall17_1 AIC-Apple ProRes 422 LT.mov" ];
			}
#endif
		}

}

void	SetViewPortRect( CGRect fullScreen, UInt32 viewPortIndex, UInt32 widthCount, UInt32 heightCount )
{
	UInt32	totalViewPorts = widthCount * heightCount;
	div_t	viewDiv = div( viewPortIndex, widthCount );
	float	viewPortWidth = fullScreen.size.width / widthCount;
	float	viewPortHeight = fullScreen.size.height / heightCount;
	CGRect	viewPortRect = CGRectMake( viewDiv.rem * viewPortWidth, viewDiv.quot * viewPortHeight, viewPortWidth , viewPortHeight );
	glViewport( viewPortRect.origin.x , viewPortRect.origin.y, viewPortRect.size.width, viewPortRect.size.height );
}

- (void)drawView
{
    clock_t thisclock = clock();
    unsigned long clock_delay = thisclock - g_lastClock;
    g_lastClock = thisclock;
    double milliseconds = ( clock_delay * 1000.0f ) / CLOCKS_PER_SEC;

	for ( UInt32	whichMovie = 0 ; whichMovie <  NUM_TEST_MOVIES ; whichMovie ++ )
		{
		[ theAVGLPlayers[ whichMovie ]  renderAVToTexture ];
		
		enum	PLAYMODE
					{
					kStepPlay = 0,
					kUseScroller,
					};
		UInt32	playMode = kStepPlay;
		switch( playMode )
			{
			case kStepPlay:
				{
				[ theAVGLPlayers[ whichMovie ]  stepPlay:2 ];
				}
				break;
			case kUseScroller:
				{
				[ theAVGLPlayers[ whichMovie ]  setCurrentFrameFromFloat:teapotSize2 ];
				}
				break;
			}

		}
#if 0
	[ theAVGLPlayer  renderAVToTexture ];
	[ theAVGLPlayer  stepPlay:2 ];
	[ theAVGLPlayer2  renderAVToTexture ];
	[ theAVGLPlayer2  stepPlay:2 ];
#endif
    IMGUIExample_Draw(milliseconds);

	if ( true )
		{
	//	glEnable( GL_DEPTH );
		static	float	animationPhase;
		animationPhase += 0.1;
			{
			glEnable( GL_TEXTURE_RECTANGLE_EXT );
			glBindTexture(GL_TEXTURE_RECTANGLE_EXT, texture2Name );
			float	textureWidth = texture2.textureWidth;
			float	textureHeight = texture2.textureHeight;
			glMatrixMode( GL_TEXTURE );
			glLoadIdentity();
			glScalef( textureWidth, textureHeight, 1.0 );
			glMatrixMode( GL_MODELVIEW );
	
 	//		glRotatef(animationPhase * 1.0, 0.0, 0.0, 1.0);
			glColor4f( 1.0, 1.0, 1.0, 1.0 );
              	glBegin(GL_QUADS);
                    glTexCoord2f( 0, 0 );
						glVertex2f(-1, -1);
			//			glColor4f( 1.0, 0.0, 0.0, 1.0 );
                    glTexCoord2f( 0, 1 );
						glVertex2f(-1,  1);
  			//			glColor4f( 0.0, 1.0, 0.0, 1.0 );
                    glTexCoord2f( 1, 1 );
						glVertex2f( 1,  1);
			//			glColor4f( 0.0, 0.0, 1.0, 1.0 );
                    glTexCoord2f( 1, 0 );
						glVertex2f( 1, -1);
			//			glColor4f( 0.0, 1.0, 1.0, 1.0 );
                glEnd();
		//	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);
			}
		if ( true )
			{
			for ( UInt32	whichMovie = 0 ; whichMovie <  NUM_TEST_MOVIES ; whichMovie ++ )
				{
				SInt32	ROW_COUNT = ( 1.0 + sqrtf( NUM_TEST_MOVIES ) );
				SetViewPortRect( CGRectMake( 0, 0, g_backingWidth, g_backingHeight ), whichMovie, ROW_COUNT, NUM_TEST_MOVIES / ROW_COUNT  );
		//		 glViewport(0, 0, 200, 200);
				glEnable( GL_TEXTURE_RECTANGLE_EXT );
		//		float	textureWidth = 1;
		//		float	textureHeight = 1;
				glPushMatrix();
				glColor4f( 1.0, 1.0, 1.0, 1.0 );
	#if 1
				CVOpenGLTextureRef		thisTexture = [ theAVGLPlayers[ whichMovie ] getTexture ];
				GLenum	cvTextureTarget = CVOpenGLTextureGetTarget( thisTexture );	// get the texture target (for example, GL_TEXTURE_2D) of the texture
				GLint	cvTextureName = CVOpenGLTextureGetName( thisTexture );		// get the texture target name of the texture
				GLfloat	lowerLeft[ 2 ], lowerRight[ 2 ], upperRight[ 2 ], upperLeft[ 2 ];
				CVOpenGLTextureGetCleanTexCoords( thisTexture,
							 lowerLeft,
							 lowerRight,
							 upperRight,
							 upperLeft );
						glBindTexture(GL_TEXTURE_RECTANGLE_EXT, cvTextureName );
				
					float textureWidth = lowerRight[ 0 ];//(int) CVPixelBufferGetWidth( thisTexture );
					float	textureHeight = lowerRight[ 1 ];//(int) CVPixelBufferGetHeight( thisTexture );

				glBindTexture(GL_TEXTURE_RECTANGLE_EXT, cvTextureName );
	#endif
				glMatrixMode( GL_TEXTURE );
				glLoadIdentity();
				glScalef( textureWidth, textureHeight, 1.0 );
				glMatrixMode( GL_MODELVIEW );
				glRotatef(animationPhase * 1.0, 0.2, .3, 1.0);
			//	glColor4f( 0.0, 0.4, .8, 1.0 );
				glutSolidTeapot( teapotSize );
				glColor4f( 0.0, 1.0, .2, .2 );
			//	glutWireTeapot( 0.5 );
				glPopMatrix();
				}
			}
		if ( false )
			{
			SetViewPortRect( CGRectMake( 0, 0, g_backingWidth, g_backingHeight ), 0, 3, 3 );
   	//		 glViewport(0, 0, 200, 200);
			glEnable( GL_TEXTURE_RECTANGLE_EXT );
	//		float	textureWidth = 1;
	//		float	textureHeight = 1;
			glPushMatrix();
			glColor4f( 1.0, 1.0, 1.0, 1.0 );
#if 1
			CVOpenGLTextureRef		thisTexture = [ theAVGLPlayer2 getTexture ];
			GLenum	cvTextureTarget = CVOpenGLTextureGetTarget( thisTexture );	// get the texture target (for example, GL_TEXTURE_2D) of the texture
			GLint	cvTextureName = CVOpenGLTextureGetName( thisTexture );		// get the texture target name of the texture
    		GLfloat	lowerLeft[ 2 ], lowerRight[ 2 ], upperRight[ 2 ], upperLeft[ 2 ];
			CVOpenGLTextureGetCleanTexCoords( thisTexture,
						 lowerLeft,
						 lowerRight,
						 upperRight,
						 upperLeft );
					glBindTexture(GL_TEXTURE_RECTANGLE_EXT, cvTextureName );
			
				float textureWidth = lowerRight[ 0 ];//(int) CVPixelBufferGetWidth( thisTexture );
				float	textureHeight = lowerRight[ 1 ];//(int) CVPixelBufferGetHeight( thisTexture );

			glBindTexture(GL_TEXTURE_RECTANGLE_EXT, cvTextureName );
#endif
			glMatrixMode( GL_TEXTURE );
			glLoadIdentity();
			glScalef( textureWidth, textureHeight, 1.0 );
			glMatrixMode( GL_MODELVIEW );
 			glRotatef(animationPhase * 1.0, 0.2, .3, 1.0);
		//	glColor4f( 0.0, 0.4, .8, 1.0 );
	 		glutSolidTeapot( teapotSize );
			glColor4f( 0.0, 1.0, .2, .2 );
		//	glutWireTeapot( 0.5 );
			glPopMatrix();
			}
		if ( false )
			{
			SetViewPortRect( CGRectMake( 0, 0, g_backingWidth, g_backingHeight ), 1, 3, 3 );
   		//	 glViewport( 200, 200, 200, 200 );
			glEnable( GL_TEXTURE_RECTANGLE_EXT );
	//		float	textureWidth = 1;
	//		float	textureHeight = 1;
			glPushMatrix();
			glColor4f( 1.0, 1.0, 1.0, 1.0 );
#if 1
			CVOpenGLTextureRef		thisTexture = [ theAVGLPlayer getTexture ];
			GLenum	cvTextureTarget = CVOpenGLTextureGetTarget( thisTexture );	// get the texture target (for example, GL_TEXTURE_2D) of the texture
			GLint	cvTextureName = CVOpenGLTextureGetName( thisTexture );		// get the texture target name of the texture
    		GLfloat	lowerLeft[ 2 ], lowerRight[ 2 ], upperRight[ 2 ], upperLeft[ 2 ];
			CVOpenGLTextureGetCleanTexCoords( thisTexture,
						 lowerLeft,
						 lowerRight,
						 upperRight,
						 upperLeft );
					glBindTexture(GL_TEXTURE_RECTANGLE_EXT, cvTextureName );
			
				float textureWidth = lowerRight[ 0 ];//(int) CVPixelBufferGetWidth( thisTexture );
				float	textureHeight = lowerRight[ 1 ];//(int) CVPixelBufferGetHeight( thisTexture );

			glBindTexture(GL_TEXTURE_RECTANGLE_EXT, cvTextureName );
#endif
			glMatrixMode( GL_TEXTURE );
			glLoadIdentity();
			glScalef( textureWidth, textureHeight, 1.0 );
			glMatrixMode( GL_MODELVIEW );
 			glRotatef(animationPhase * 1.0, 0.2, .3, 1.0);
		//	glColor4f( 0.0, 0.4, .8, 1.0 );
	 		glutSolidTeapot( teapotSize2 );
			glColor4f( 0.0, 1.0, .2, .2 );
		//	glutWireTeapot( 0.5 );
			glPopMatrix();
			}
		}

    GLsizei width  = (GLsizei)(g_backingWidth);
    GLsizei height = (GLsizei)(g_backingHeight);
    glViewport(0, 0, width, height);

	glDisable( GL_TEXTURE_RECTANGLE_EXT );
	glMatrixMode( GL_TEXTURE );
	glLoadIdentity();
	glMatrixMode( GL_MODELVIEW );
    ImGui::Render();


    [[self openGLContext] flushBuffer];
    
    if (!animationTimer)
    	{
        animationTimer = [NSTimer scheduledTimerWithTimeInterval:0.017 target:self selector:@selector(animationTimerFired:) userInfo:nil repeats:YES];
    	}
}

-(void)setViewportRect:(NSRect)bounds
{
    glViewport(0, 0, bounds.size.width, bounds.size.height);
    g_windowWidth = bounds.size.width;
	g_windowHeight = bounds.size.height;
    
    if (g_windowHeight == 0)
    {
        g_windowHeight = 1;
	}
    

    //ImGui::GetIO().DisplaySize = ImVec2((float)bounds.size.width, (float)bounds.size.height);
#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1070
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6)
    {
        NSRect backing = [self convertRectToBacking:bounds];
        g_backingWidth = backing.size.width;
        g_backingHeight= backing.size.height;
        if (g_backingHeight == 0)
        {
            g_backingHeight = g_windowHeight * 2;
        }
    }
    else
#endif /*MAC_OS_X_VERSION_MAX_ALLOWED*/
    {
        g_backingWidth = g_windowWidth;
        g_backingHeight= g_windowHeight;
    }
}

-(void)reshape
{
    [self setViewportRect:self.bounds];
    [[self openGLContext] update];
    [self drawView];
}

-(void)drawRect:(NSRect)bounds
{
    [self drawView];
}

#pragma mark -

-(BOOL)acceptsFirstResponder
{
    return(YES);
}

-(BOOL)becomeFirstResponder
{
    return(YES);
}

-(BOOL)resignFirstResponder
{
    return(YES);
}

// Flips coordinate system upside down on Y
-(BOOL)isFlipped
{
    return(YES);
}

#pragma mark Mouse and Key Events.
static bool mapKeymap(int* keymap)
{
    if(*keymap == NSUpArrowFunctionKey)
        *keymap = ImGuiKey_UpArrow;
    else if(*keymap == NSDownArrowFunctionKey)
        *keymap = ImGuiKey_DownArrow;
    else if(*keymap == NSLeftArrowFunctionKey)
        *keymap = ImGuiKey_LeftArrow;
    else if(*keymap == NSRightArrowFunctionKey)
        *keymap = ImGuiKey_RightArrow;
    else if(*keymap == NSHomeFunctionKey)
        *keymap = ImGuiKey_Home;
    else if(*keymap == NSEndFunctionKey)
        *keymap = ImGuiKey_End;
    else if(*keymap == NSDeleteFunctionKey)
        *keymap = ImGuiKey_Delete;
    else if(*keymap == 25) // SHIFT + TAB
        *keymap = 9; // TAB
    else
        return true;
    
    return false;
}

static void resetKeys()
{
    ImGuiIO& io = ImGui::GetIO();
    io.KeysDown[io.KeyMap[ImGuiKey_A]] = false;
    io.KeysDown[io.KeyMap[ImGuiKey_C]] = false;
    io.KeysDown[io.KeyMap[ImGuiKey_V]] = false;
    io.KeysDown[io.KeyMap[ImGuiKey_X]] = false;
    io.KeysDown[io.KeyMap[ImGuiKey_Y]] = false;
    io.KeysDown[io.KeyMap[ImGuiKey_Z]] = false;
    io.KeysDown[io.KeyMap[ImGuiKey_LeftArrow]] = false;
    io.KeysDown[io.KeyMap[ImGuiKey_RightArrow]] = false;
    io.KeysDown[io.KeyMap[ImGuiKey_Tab]] = false;
    io.KeysDown[io.KeyMap[ImGuiKey_UpArrow]] = false;
    io.KeysDown[io.KeyMap[ImGuiKey_DownArrow]] = false;
    io.KeysDown[io.KeyMap[ImGuiKey_Tab]] = false;
}

-(void)keyUp:(NSEvent *)theEvent
{
    NSString *str = [theEvent characters];
    ImGuiIO& io = ImGui::GetIO();
    int len = (int)[str length];
    for(int i = 0; i < len; i++)
    {
        int keymap = [str characterAtIndex:i];
        mapKeymap(&keymap);
        if(keymap < 512)
        {
            io.KeysDown[keymap] = false;
        }
    }
}

-(void)keyDown:(NSEvent *)theEvent
{
    NSString *str = [theEvent characters];
    ImGuiIO& io = ImGui::GetIO();
    int len = (int)[str length];
    for(int i = 0; i < len; i++)
    	{
        int keymap = [str characterAtIndex:i];
        if(mapKeymap(&keymap) && !io.KeyCtrl)
            io.AddInputCharacter(keymap);
        if(keymap < 512)
        	{
            if(io.KeyCtrl)
            	{
                // we must reset in case we're pressing a sequence
                // of special keys while keeping the command pressed
                resetKeys();
            	}
            io.KeysDown[keymap] = true;
        	}
    	}
}

- (void)flagsChanged:(NSEvent *)event
{
    unsigned int flags;
    flags = [event modifierFlags] & NSDeviceIndependentModifierFlagsMask;
    ImGuiIO& io = ImGui::GetIO();
    bool wasKeyShift= io.KeyShift;
    bool wasKeyCtrl = io.KeyCtrl;
    io.KeyShift     = flags & NSShiftKeyMask;
    io.KeyCtrl      = flags & NSCommandKeyMask;
    bool keyShiftReleased = wasKeyShift && !io.KeyShift;
    bool keyCtrlReleased  = wasKeyCtrl  && !io.KeyCtrl;
    if(keyShiftReleased || keyCtrlReleased)
    	{
        // we must reset them as we will not receive any
        // keyUp event if they where pressed during shift or command
        resetKeys();
    	}
}

-(void)mouseDown:(NSEvent *)theEvent
{
    int button = (int)[theEvent buttonNumber];
    g_mousePressed[button] = true;
}

-(void)mouseUp:(NSEvent *)theEvent
{
    int button = (int)[theEvent buttonNumber];
    g_mousePressed[button] = false;
}

-(void)mouseMoved:(NSEvent *)theEvent
{
    NSWindow *mainWindow = [self window];
    NSPoint mousePosition = [mainWindow mouseLocationOutsideOfEventStream];
    mousePosition = [self convertPoint:mousePosition fromView:nil];
    g_mouseCoords[ 0 ] = mousePosition.x;
    g_mouseCoords[ 1 ] = mousePosition.y - 1.0f;
}

-(void)mouseDragged:(NSEvent *)theEvent
{
    NSWindow *mainWindow = [self window];
    NSPoint mousePosition = [mainWindow mouseLocationOutsideOfEventStream];
    mousePosition = [self convertPoint:mousePosition fromView:nil];
    g_mouseCoords[0] = mousePosition.x;
    g_mouseCoords[1] = mousePosition.y - 1.0f;
}

-(void )contextMenuAction:(id)sender
{
	// sending additional information from the menu...
	//https://stackoverflow.com/questions/2824287/how-do-i-set-the-sender-on-a-nsmenuitems-action
	NSLog(@"menu action ");
    NSLog(@"The menu item's object is %@",[sender representedObject]);
}

-(void )beep:(id)sender
{
	NSLog(@"menu action 2 ");
	NSWindow	* myCustomDialog;
    if (!myCustomDialog)
		{
        [NSBundle loadNibNamed: @"testEditText" owner: self];
 		}
#if 0
    [NSApp beginSheet: myCustomDialog
            modalForWindow: _window
            modalDelegate: nil
            didEndSelector: nil
            contextInfo: nil];
#endif
    [NSApp runModalForWindow: myCustomDialog];
    // Dialog is up here.
//    [NSApp endSheet: myCustomDialog];
    [myCustomDialog orderOut: self];

}

-(void )honk:(id)sender
{
	NSLog(@"menu action 3 ");
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
    NSLog(@"entered rightMouseDown");

	//https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/MenuList/Articles/DisplayContextMenu.html
	
	if ( true )	// try popup menu
		{
		NSMenu *theMenu = [[NSMenu alloc] initWithTitle:@"Contextual Menu"];
		[theMenu insertItemWithTitle:@"Beep" action:@selector(beep:) keyEquivalent:@"" atIndex:0];
		
		NSMenuItem *item = [ theMenu insertItemWithTitle:[NSString stringWithFormat:@"%d - %@", 0, @"hello" ] action:@selector(contextMenuAction:) keyEquivalent:@"" atIndex:0 ];
		[item setTarget:self ];
   		 [item setEnabled:YES ];
		[item setRepresentedObject:@"hello data" ];
		
//		[ theMenu addItem:item ];
//		[theMenu insertItemWithTitle:@"Beep" action:@selector(beep:) keyEquivalent:@"" atIndex:0];
		
		[theMenu insertItemWithTitle:@"Honk" action:@selector(honk:) keyEquivalent:@"" atIndex:1];
	 
		[NSMenu popUpContextMenu:theMenu withEvent:theEvent forView:self];
		}
}


- (void)scrollWheel:(NSEvent *)event
{
    double deltaX, deltaY;

#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1070
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6)
    {
        deltaX = [event scrollingDeltaX];
        deltaY = [event scrollingDeltaY];

        if ([event hasPreciseScrollingDeltas])
        {
            deltaX *= 0.1;
            deltaY *= 0.1;
        }
    }
    else
#endif /*MAC_OS_X_VERSION_MAX_ALLOWED*/
    {
        deltaX = [event deltaX];
        deltaY = [event deltaY];
    }

    if (fabs(deltaX) > 0.0 || fabs(deltaY) > 0.0)
    {
        ImGuiIO& io = ImGui::GetIO();
        io.MouseWheel += deltaY * 0.05f;
    }
}

-(void)dealloc
{
//    [animationTimer release];
  //  [super dealloc];
}

@end

//------------------------------------------------------------------
// IMGUIExampleAppDelegate
//------------------------------------------------------------------
@interface IMGUIExampleAppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, readonly) NSWindow *window;

@end

@implementation IMGUIExampleAppDelegate

@synthesize window = _window;

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

- (NSWindow*)window
{
    if (_window != nil)
        return(_window);
    
    NSRect viewRect = NSMakeRect(100.0, 100.0, 1300.0, 800.0);
    
    _window = [[NSWindow alloc] initWithContentRect:viewRect styleMask:NSTitledWindowMask|NSMiniaturizableWindowMask|NSResizableWindowMask|NSClosableWindowMask backing:NSBackingStoreBuffered defer:YES];
    [_window setTitle:@"IMGUI OSX Sample"];
    [_window setOpaque:YES];
    
    [_window makeKeyAndOrderFront:NSApp];
    
    return(_window);
}

- (void) terminateApplicationTest
{
	NSLog(@"quit?");

}

- (void)setupMenu
{
    NSMenu *mainMenuBar;
    NSMenu *appMenu;
    NSMenuItem *menuItem;
    
    mainMenuBar = [[NSMenu alloc] init];
    
    appMenu = [[NSMenu alloc] initWithTitle:@"IMGUI OSX Sample"];
//    menuItem = [appMenu addItemWithTitle:@"Quit IMGUI OSX Sample" action:@selector(terminateApplicationTest:) keyEquivalent:@"q"];
    menuItem = [appMenu addItemWithTitle:@"Quit IMGUI OSX Sample" action:@selector(terminate:) keyEquivalent:@"q"];
    [menuItem setKeyEquivalentModifierMask:NSCommandKeyMask];
    
    menuItem = [[NSMenuItem alloc] init];
    [menuItem setSubmenu:appMenu];
    
    [mainMenuBar addItem:menuItem];
    
 //   [appMenu release];
    [NSApp setMainMenu:mainMenuBar];
}

- (void)dealloc
{
  //  [_window dealloc];
 //   [super dealloc];
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
// gs doc controller not accessed  but this one is
    NSArray *docs = [[NSDocumentController sharedDocumentController] documents];
    if ( [docs count]==0 && [[NSApplication sharedApplication] keyWindow ] == nil)
    	{
		[[NSDocumentController sharedDocumentController] newDocument:0 ];
        // If no docs already open, put up open file dialog at program launch
        [ [NSDocumentController sharedDocumentController] openDocument:self ];
    	}
	
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self setupMenu];
    
    NSOpenGLPixelFormatAttribute attrs[] =
    {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFADepthSize, 32,
        0
    };
    
    NSOpenGLPixelFormat *format = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
    IMGUIExampleView *view = [[IMGUIExampleView alloc] initWithFrame:self.window.frame pixelFormat:format];
//    [format release];
#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1070
    if (floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_6)
        [view setWantsBestResolutionOpenGLSurface:YES];
#endif /*MAC_OS_X_VERSION_MAX_ALLOWED*/

    [self.window setContentView:view];
    
    if ([view openGLContext] == nil)
    	{
        NSLog(@"No OpenGL Context!");
    	}
	ImGui::CreateContext();
    IMGUIExample_InitImGui();
    // This is needed to accept mouse move events
    [self.window setAcceptsMouseMovedEvents:YES];
    // This is needed to accept mouse events before clicking on the window
    [self.window makeFirstResponder:view];

	if ( true )	//goto full screen
		{
		NSRect	screenFrame = [[NSScreen mainScreen] frame];
		[self.window setFrame:screenFrame display:YES];
		[self.window toggleFullScreen:self];
		}
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
	saveFloat( "teapot/size", teapotSize );
	saveFloat( "teapot2/size", teapotSize2 );
	saveBoolean( "window/example/visible", exampleWindowVisible );

}

@end

//------------------------------------------------------------------
// main
//------------------------------------------------------------------

int main(int argc, const char * argv[])
{
 //   [[NSAutoreleasePool alloc] init];
    NSApp = [NSApplication sharedApplication];
	
    IMGUIExampleAppDelegate *delegate = [[IMGUIExampleAppDelegate alloc] init];
    
    [[NSApplication sharedApplication] setDelegate:delegate];
    [NSApp run];
    return NSApplicationMain(argc, argv);
}
