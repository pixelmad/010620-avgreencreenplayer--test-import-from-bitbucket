//
//  avplayerload.h
//  AVGreenScreenPlayer
//
//  Created by Richard Bleasdale on 2/14/18.
//  Copyright © 2018 Apple Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface MyAVplayerload : NSObject
	{
	NSString					*path;
	AVPlayer					*player;
	AVPlayerItem				*playerItem;
	Float64						movieduration;
	CMTimeScale					movietimescale;
	NSSize						moviesize;
	AVPlayerItemVideoOutput		*playerVideoItemOutput;
	Boolean						isPrepared;
	Boolean						isReadyToPlay;
	Boolean						isNewImageAvailable;
	CVOpenGLTextureCacheRef		textureCache;
	CVOpenGLTextureRef			textureToRender;
	CVOpenGLTextureRef 			oldlocaltexture;
	//step playing
	UInt32	thisTime;
	UInt32	timeDiv;
	UInt32	currentPlaySpeed;
	}

- (id) initWithCGLContextObj:(CGLContextObj)initCGLContext pixelFormat:(CGLPixelFormatObj)initPixelFormat  fileurl:(NSString*)path;
- (void) observeValueForKeyPath:(NSString*)inKeyPath ofObject:(id)inObject change:(NSDictionary*)inChange context:(void*)inContext;
- (BOOL) renderAVToTexture;
- ( CVOpenGLTextureRef )	getTexture;
-(void) stepPlay:(UInt32 )thisPlaySpeed;

@end
