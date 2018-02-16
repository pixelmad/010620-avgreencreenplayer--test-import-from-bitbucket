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
	CVOpenGLTextureRef			texture;
	}

- (id) initWithCGLContextObj:(CGLContextObj)initCGLContext pixelFormat:(CGLPixelFormatObj)initPixelFormat;
- (void) observeValueForKeyPath:(NSString*)inKeyPath ofObject:(id)inObject change:(NSDictionary*)inChange context:(void*)inContext;
- (BOOL) renderAVToTexture;
- ( CVOpenGLTextureRef )	getTexture;
-(void) stepPlay;

@end
