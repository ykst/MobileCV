// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import "MCVCameraBufferFreight.h"
#import "TGLMappedTexture2D.h"

@interface MCVCameraBufferFreight() {
    //double _roll;
    //double _pitch;
    //double _yaw;
    TGLMappedTexture2D *_subplane;
}

//@property (nonatomic, readwrite) CGSize size;
//@property (nonatomic, readwrite) TGLMappedTexture2D *plane;
//@property (nonatomic, readwrite) TGLMappedTexture2D *subplane;
//@property (nonatomic, readwrite) GLenum internal_format;

//@property (nonatomic, readwrite) double roll;
//@property (nonatomic, readwrite) double pitch;
//@property (nonatomic, readwrite) double yaw;
@end

@implementation MCVCameraBufferFreight

@synthesize subplane = _subplane;
//@synthesize roll = _roll;
//@synthesize pitch = _pitch;
//@synthesize yaw = _yaw;

- (void)refill:(CMSampleBufferRef)sample
{
    CVImageBufferRef buffer = CMSampleBufferGetImageBuffer(sample);

    NSUInteger buffer_width = CVPixelBufferGetWidth(buffer);
    NSUInteger buffer_height = CVPixelBufferGetHeight(buffer);

    _size = CGSizeMake(buffer_width, buffer_height);

    OSType pixel_format = CVPixelBufferGetPixelFormatType(buffer);

    switch (pixel_format) {
        case kCVPixelFormatType_32BGRA:

            _plane = [TGLMappedTexture2D createFromImageBuffer:buffer withSize:CGSizeMake(buffer_width, buffer_height) withPlaneIdx:0 withInternalFormat:GL_RGBA withSmooth:YES];

            _subplane = nil;

            _internal_format = GL_RGBA;

            break;
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange: /* Fallthrough */
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:

            _plane = [TGLMappedTexture2D createFromImageBuffer:buffer withSize:CGSizeMake(buffer_width, buffer_height) withPlaneIdx:0 withInternalFormat:GL_LUMINANCE withSmooth:YES];

            _subplane = [TGLMappedTexture2D createFromImageBuffer:buffer withSize:CGSizeMake(buffer_width / 2, buffer_height / 2) withPlaneIdx:1 withInternalFormat:GL_LUMINANCE_ALPHA withSmooth:YES];

            _internal_format = GL_LUMINANCE;

            break;
        default: NSASSERT(!"Unknown frame format"); break;
    }
}
/*
- (void)modifyAttitude:(double)roll :(double)pitch :(double)yaw
{
    _roll = roll;
    _pitch = pitch;
    _yaw = yaw;
}
*/
+ (MCVCameraBufferFreight *)create
{
    MCVCameraBufferFreight *obj = [[[self class] alloc] init];

    return obj;
}

@end

