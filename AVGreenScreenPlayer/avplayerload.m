//
//  avplayerload.m
//  AVGreenScreenPlayer
//
//  Created by Richard Bleasdale on 2/14/18.
//  Copyright © 2018 Apple Inc. All rights reserved.
//

#import "avplayerload.h"
#import <AVFoundation/AVFoundation.h>


//https://forums.developer.apple.com/thread/27589
//AVPlayer & AVPlayerItemVideoOutput playback problem on El Capitan

const	NSString		*kStatusKey = @"hello movies";

@implementation MyAVplayerload

- (id) load
{
     // Create a player...
	
     NSURL* url = [ NSURL fileURLWithPath:@"/Users/richardb/Desktop/Turn screw media/001 test/001 full wall17_1 AIC-Apple ProRes 422 LT.mov" ];
     player = [AVPlayer playerWithURL:url];
     [ player setVolume:0.0];
	
	
     // Get metadata from its asset...
	
     playerItem = player.currentItem;
     AVAsset* asset = playerItem.asset;
	
     if (asset)
     	{
		// Duration...

		CMTime duration = asset.duration;
		movieduration = CMTimeGetSeconds( duration );
		movietimescale = duration.timescale;

		NSArray* tracks = [asset tracksWithMediaType:AVMediaTypeVideo];

		if (tracks.count > 0)
			{
			AVAssetTrack* track = [tracks objectAtIndex:0];

			// Size...

			CGSize size = track.naturalSize;
			moviesize = NSMakeSize(size.width,size.height);
		//	_physicalWidth = _logicalWidth = moviesize.width;
		//	_physicalHeight = _logicalHeight = _movieSize.height;

			// Orientation: find out if the video was shot vertically and needs to rotated to be viewed correctly...

			CGAffineTransform transform = [track preferredTransform];
			double radians = atan2(transform.b,transform.a);
			double degrees = radians * 180.0 / M_PI;
		//	_rotationOffset = -degrees;
			}
		
		}
	
     // Create a video output, and add it to the playerItem...
	
     NSDictionary* attributes =
     @{
          (NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32ARGB),
//        (NSString*)kCVPixelBufferBytesPerRowAlignmentKey: @1,
          (NSString*)kCVPixelBufferOpenGLCompatibilityKey: @YES
     };
	
     playerVideoItemOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:attributes ];
     [ playerItem addOutput:playerVideoItemOutput ];
	
     // Make sure we are notified once the player is ready for playback...
	
     [ playerItem addObserver:self forKeyPath:kStatusKey options:NSKeyValueObservingOptionInitial context:&kStatusKey];
     [ player addObserver:self forKeyPath:kStatusKey options:NSKeyValueObservingOptionInitial context:&kStatusKey];
	
     isPrepared = YES;
     return self;
}

- (void) observeValueForKeyPath:(NSString*)inKeyPath ofObject:(id)inObject change:(NSDictionary*)inChange context:(void*)inContext
{
     if (inContext == &kStatusKey)
     {
          __weak typeof(self) weakSelf = self;
          AVPlayer* player = player;
          AVPlayerItem* playerItem = playerItem;
  
          if (player.status == AVPlayerStatusReadyToPlay && playerItem.status == AVPlayerItemStatusReadyToPlay)
          	{
        //       CMTime time = CMTimeMakeWithSeconds(_inPoint,_timescale);
  
         //      [player seekToTime:time completionHandler:^(BOOL inFinished)
               {
          //          weakSelf.isReadyToPlay = YES;
               }
             //  ];
          	}
     }
     else
     {
          [super observeValueForKeyPath:inKeyPath ofObject:inObject change:inChange context:inContext];
     }
}
@end
