/*
     File: MyOpenGLView.m
 Abstract:  An NSView subclass that delegates to separate "scene" 
 and "controller" objects for OpenGL rendering and input event handling.
 
  Version: 1.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
*/

#import <OpenGL/glu.h>
#import <GLUT/glut.h>

#import "MyOpenGLView.h"
#import "Texture.h"
//#import "MainController.h"
//#import "Scene.h"

@implementation MyOpenGLView

- (NSOpenGLContext*) openGLContext
{
	return openGLContext;
}

- (NSOpenGLPixelFormat*) pixelFormat
{
	return pixelFormat;
}

- (void) setMainController:(MainController*)theController;
{
	controller = theController;
}

// initialize
-(void)awakeFromNib
{
		if ( !texture1Name )
			{
			NSString *path = [[NSBundle mainBundle] pathForResource:@"glgui_texture_packer_070616" ofType:@"png"];
		//	NSString *path = [[NSBundle mainBundle] pathForResource:@"Earth" ofType:@"jpg"];
			
			
			texture1 = [ [Texture alloc] initWithPath:path];
			texture1Name = [texture1 textureName];
			}
}

- (CVReturn) getFrameForTime:(const CVTimeStamp*)outputTime
{
	// There is no autorelease pool when this method is called because it will be called from a background thread
	// It's important to create one or you will leak objects
//	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// Update the animation
	CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
//	[[controller scene] advanceTimeBy:(currentTime - [controller renderTime])];
//	[controller setRenderTime:currentTime];

#if 0
	[ theMovieLayers getFramesForTime:outputTime flagsOut:0 ];

	if (textureContext != NULL && QTVisualContextIsNewImageAvailable(textureContext, outputTime)) {
		
        // if we have a previous frame release it
		if (NULL != currentFrame) {
        	CVOpenGLTextureRelease(currentFrame);
        	currentFrame = NULL;
        }
		
        // get a "frame" (image buffer) from the Visual Context, indexed by the provided time
		OSStatus status = QTVisualContextCopyImageForTime(textureContext, NULL, outputTime, &currentFrame);
		
        // the above call may produce a null frame so check for this first
        // if we have a frame, then draw it
		if ((noErr == status) && (NULL != currentFrame)) {
        	[self drawRect:NSZeroRect];
		}
	}
	
    // give time to the Visual Context so it can release internally held resources for later re-use
	// this function should be called in every rendering pass, after old images have been released, new
    // images have been used and all rendering has been flushed to the screen.
	QTVisualContextTask(textureContext);
#endif

	[self drawView];
	
//	[pool release];
    return kCVReturnSuccess;
}

// This is the renderer output callback function
static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext)
{
    CVReturn result = [(__bridge MyOpenGLView*)displayLinkContext getFrameForTime:outputTime];
    return 0;
}

- (void) setupDisplayLink
{
	// Create a display link capable of being used with all active displays
	CVReturn	err = CVDisplayLinkCreateWithActiveCGDisplays( &displayLink );
	
	// Set the renderer output callback function
	err = CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, (__bridge void * _Nullable)(self));
	
	// Set the display link for the current renderer
	CVDisplayLinkStart(displayLink);

	// not needed...
	
//	CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
//	CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
//	err = CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext( displayLink, cglContext, cglPixelFormat);
}

- (id) initWithFrame:(NSRect)frameRect shareContext:(NSOpenGLContext*)context
{
    NSOpenGLPixelFormatAttribute attribs[] =
    	{
		kCGLPFAAccelerated,
		kCGLPFANoRecovery,
		kCGLPFADoubleBuffer,
		kCGLPFAColorSize, 24,
		kCGLPFADepthSize, 16,
		0
    	};
	
    pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
	
    if (!pixelFormat)
		NSLog(@"No OpenGL pixel format");
	
	// NSOpenGLView does not handle context sharing, so we draw to a custom NSView instead
	openGLContext = [[NSOpenGLContext alloc] initWithFormat:pixelFormat shareContext:context];
	glFrameRect = frameRect;
	if (self = [super initWithFrame:frameRect])
		{
		[[self openGLContext] makeCurrentContext];
		
		// Synchronize buffer swaps with vertical refresh rate
		GLint swapInt = 1;
		[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval]; 
		
		[self setupDisplayLink];
		
		// Look for changes in view size
		// Note, -reshape will not be called automatically on size changes because NSView does not export it to override 
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(reshape) 
													 name:NSViewGlobalFrameDidChangeNotification
												   object:self];
		}

#if 0
	QTOpenGLTextureContextCreate(kCFAllocatorDefault,
						[ openGLContext CGLContextObj ],			// the OpenGL context
						[ pixelFormat CGLPixelFormatObj ], 			// pixelformat object that specifies buffer types and other attributes of the context
                                 NULL,								// a CF Dictionary of attributes
                                 &textureContext
                                 );											// returned OpenGL texture context
#endif
	
  //  [self openMovie:@"/Users/richardb/Desktop/Turn screw media/001 test/001 full wall17_1 AIC.mov" ];
//    [self openMovie:@"/Users/richardb/Desktop/Turn screw media/006 turn screw export cat media/036 cloud6.mov" ];
   

	return self;
}

- (id) initWithFrame:(NSRect)frameRect
{
	self = [self initWithFrame:frameRect shareContext:nil];
	return self;
}

- (void) lockFocus
{
	[super lockFocus];
	if ([[self openGLContext] view] != self)
		[[self openGLContext] setView:self];
}

- (void) reshape
{
	// This method will be called on the main thread when resizing, but we may be drawing on a secondary thread through the display link
	// Add a mutex around to avoid the threads accessing the context simultaneously
	CGLLockContext([[self openGLContext] CGLContextObj]);
	
	// Delegate to the scene object to update for a change in the view size
//	[[controller scene] setViewportRect:[self bounds]];
	[[self openGLContext] update];
	
	CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void) drawRect:(NSRect)dirtyRect
{
	// Ignore if the display link is still running
	if (!CVDisplayLinkIsRunning(displayLink))
		[self drawView];
}

- (void) drawView
{
	// This method will be called on both the main thread (through -drawRect:) and a secondary thread (through the display link rendering loop)
	// Also, when resizing the view, -reshape is called on the main thread, but we may be drawing on a secondary thread
	// Add a mutex around to avoid the threads accessing the context simultaneously
	CGLLockContext([[self openGLContext] CGLContextObj]);
	
	// Make sure we draw to the right context
	[[self openGLContext] makeCurrentContext];

#if 0
	cvTextureTarget = CVOpenGLTextureGetTarget(currentFrame);	// get the texture target (for example, GL_TEXTURE_2D) of the texture
	cvTextureName = CVOpenGLTextureGetName(currentFrame);		// get the texture target name of the texture

    [[controller scene] setCVTextureTarget:cvTextureTarget ];
    [[controller scene] setCVTextureName:cvTextureName ];
    [[controller scene] setCVTextureSize:movieSize ];

	// get the texture coordinates for the part of the image that should be displayed
//	GLfloat topLeft[2], topRight[2], bottomRight[2], bottomLeft[2];
//	CVOpenGLTextureGetCleanTexCoords(currentFrame, bottomLeft, bottomRight, topRight, topLeft);
#endif
 
	// Delegate to the scene object for rendering
 //   [[controller scene] render];
 	static	float red = 0.2;
     glClearColor( red, 0, 0, .5);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	glEnable(GL_DEPTH_TEST);
//	glEnable(GL_CULL_FACE);
//	glEnable(GL_LIGHTING);
//	glEnable(GL_LIGHT0);
	glEnable( GL_TEXTURE_RECTANGLE_EXT );
	float	width = glFrameRect.size.width, height = glFrameRect.size.height;
     glColor4f( 1, 1, 1, .5);

//	glViewport( glFrameRect.origin.x, glFrameRect.origin.y, width, height);
	
	glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
	gluOrtho2D( -2, 2, -2, 2 );
//    gluPerspective(30, width / height, 1.0, 1000.0);
	glMatrixMode( GL_MODELVIEW );

#if 0
               	glBegin(GL_QUADS);
                    glTexCoord2f( 0, 0 );
						glVertex2f(-1, -1);
						glColor4f( 1.0, 0.0, 0.0, 1.0 );
                    glTexCoord2f( 0, height );
						glVertex2f(-1,  1);
  						glColor4f( 0.0, 1.0, 0.0, 1.0 );
                    glTexCoord2f( width, height );
						glVertex2f( 1,  1);
						glColor4f( 0.0, 0.0, 1.0, 1.0 );
                    glTexCoord2f( width, 0 );
						glVertex2f( 1, -1);
						glColor4f( 0.0, 1.0, 1.0, 1.0 );
                glEnd();
#endif
#if 1
//	red += 0.01;
//	if ( red > 1.0 )
//		red = 0.;

			static	float	 animationPhase = 0;
			animationPhase += .1;
	    GLUquadric *quadric = NULL;
	//		glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);



			// Set up our single directional light (the Sun!)
	//		lightDirection[0] = cos( dtor( sunAngle ) );
	//		lightDirection[2] = sin( dtor( sunAngle ) );
	//		glLightfv(GL_LIGHT0, GL_POSITION, lightDirection);
			
			glPushMatrix();
	
	#if 1
			glBindTexture(GL_TEXTURE_RECTANGLE_EXT, texture1Name );
			float	textureWidth = [texture1 textureWidth ];
			float	textureHeight = [texture1 textureHeight ];
			glMatrixMode( GL_TEXTURE );
			glLoadIdentity();
			glScalef( textureWidth, textureHeight, 1.0 );
			glMatrixMode( GL_MODELVIEW );
	
 			glRotatef(animationPhase * 1.0, 0.0, 0.0, 1.0);
              	glBegin(GL_QUADS);
                    glTexCoord2f( 0, 0 );
						glVertex2f(-1, -1);
						glColor4f( 1.0, 0.0, 0.0, 1.0 );
                    glTexCoord2f( 0, height );
						glVertex2f(-1,  1);
  						glColor4f( 0.0, 1.0, 0.0, 1.0 );
                    glTexCoord2f( width, height );
						glVertex2f( 1,  1);
						glColor4f( 0.0, 0.0, 1.0, 1.0 );
                    glTexCoord2f( width, 0 );
						glVertex2f( 1, -1);
						glColor4f( 0.0, 1.0, 1.0, 1.0 );
                glEnd();
			glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);
	#endif
	 glutSolidTeapot( 0.5 );

	#if 0
			// Draw the Earth!
			glTranslatef(0.0, 0.0, -1.5);
			quadric = gluNewQuadric();
		//	if (wireframe)
				gluQuadricDrawStyle(quadric, GLU_LINE);
		//	gluQuadricTexture(quadric, GL_TRUE);
		//	glMaterialfv(GL_FRONT, GL_AMBIENT, materialAmbient);
		//	glMaterialfv(GL_FRONT, GL_DIFFUSE, materialDiffuse);
		//	glRotatef(rollAngle, 1.0, 0.0, 0.0);
			glRotatef(-23.45, 0.0, 0.0, 1.0); // Earth's axial tilt is 23.45 degrees from the plane of the ecliptic
			glRotatef(animationPhase * 360.0, 0.0, 1.0, 0.0);
			glRotatef(-90.0, 1.0, 0.0, 0.0);
			gluSphere(quadric, 0, 48, 24);
			gluDeleteQuadric(quadric);
			quadric = NULL;
			
			glPopMatrix();
			
			glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);
	#endif
#endif
	[[self openGLContext] flushBuffer];
	
	CGLUnlockContext([[self openGLContext] CGLContextObj]);
}
 
- (BOOL) acceptsFirstResponder
{
    // We want this view to be able to receive key events
    return YES;
}

- (void) keyDown:(NSEvent *)theEvent
{
    // Delegate to the controller object for handling key events
//    [controller keyDown:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    // Delegate to the controller object for handling mouse events
 //   [controller mouseDown:theEvent];
}

- (void) startAnimation
{
//	if (displayLink && !CVDisplayLinkIsRunning(displayLink))
//		CVDisplayLinkStart(displayLink);
}

- (void) stopAnimation
{
//	if (displayLink && CVDisplayLinkIsRunning(displayLink))
//		CVDisplayLinkStop(displayLink);
}

- (void) dealloc
{
	// Stop and release the display link
	CVDisplayLinkStop(displayLink);
    CVDisplayLinkRelease(displayLink);
	
	// Destroy the context
//	[openGLContext release];
//	[pixelFormat release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:NSViewGlobalFrameDidChangeNotification
												  object:self];
//	[super dealloc];
}	

#pragma mark Display Link
// getFrameForTime is called from the Display Link callback when it's time for us to check to see
// if we have a frame available to render -- if we do, draw -- if not, just task the Visual Context and split
- (CVReturn)getFrameForTime:(const CVTimeStamp*)timeStamp flagsOut:(CVOptionFlags*)flagsOut
{

#if 1
	// there is no autorelease pool when this menthod is called because it will be called from another thread
    // it's important to create one or you will leak objects
//	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	NSLog(	@"getFramesForTime" );

//	[ theMovieLayers getFramesForTime:timeStamp flagsOut:flagsOut ];
#if 0
	// check for new frame
	if (textureContext != NULL && QTVisualContextIsNewImageAvailable(textureContext, timeStamp)) {
		
        // if we have a previous frame release it
		if (NULL != currentFrame) {
        	CVOpenGLTextureRelease(currentFrame);
        	currentFrame = NULL;
        }
		
        // get a "frame" (image buffer) from the Visual Context, indexed by the provided time
		OSStatus status = QTVisualContextCopyImageForTime(textureContext, NULL, timeStamp, &currentFrame);
		
        // the above call may produce a null frame so check for this first
        // if we have a frame, then draw it
		if ((noErr == status) && (NULL != currentFrame)) {
        	[self drawRect:NSZeroRect];
		}
	}
	
    // give time to the Visual Context so it can release internally held resources for later re-use
	// this function should be called in every rendering pass, after old images have been released, new
    // images have been used and all rendering has been flushed to the screen.
	QTVisualContextTask(textureContext);
#endif
 //   [pool release];

#endif
	return kCVReturnSuccess;
}

#pragma mark Movie
// open a Movie File and instantiate a QTMovie object
-(void)openMovie:(NSString*)path
{

//		theMovieLayers = [[movieLayers alloc] initWithCGLContextObj:[ openGLContext CGLContextObj ] pixelFormat:[ pixelFormat CGLPixelFormatObj ]  ];
		NSLog(	@"opening movie layers" );
#if 0
	if (textureContext != nil)
		{
		
        // if we already have a QTMovie release it
        if (nil != movie) [movie release];
		
        movie = [[QTMovie alloc] initWithFile:path error:nil];
		
        // get the Movie size
        [[movie attributeForKey:QTMovieNaturalSizeAttribute] getValue:&movieSize];
		
        // set Movie to loop
        [movie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieLoopsAttribute];
		
        // targets a Movie to render into a visual context
        SetMovieVisualContext([movie quickTimeMovie], textureContext);
		
        // play the Movie
        [movie setRate:1.0];

		// set the window title from the Movie if it has a name associated with it
        [[self window] setTitle:[movie attributeForKey:QTMovieDisplayNameAttribute]];
    	}
#endif
}

@end
