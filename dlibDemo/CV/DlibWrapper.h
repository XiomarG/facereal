//
//  DlibWrapper.h
//  dlibDemo
//
//  Created by Xun Gong on 2017-11-04.
//  Copyright © 2017 clarke. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@interface DlibWrapper : NSObject

- (instancetype)init;
- (void)doWorkOnSampleBuffer:(CMSampleBufferRef)sampleBuffer inRects:(NSArray<NSValue *> *)rects;
- (void)prepare;

@end
