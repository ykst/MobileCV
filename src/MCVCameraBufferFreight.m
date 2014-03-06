// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import "MCVCameraBufferFreight.h"
#import "TGLMappedTexture2D.h"

@interface MCVCameraBufferFreight()

@property (nonatomic, readwrite) CGSize size;
@property (nonatomic, readwrite) TGLMappedTexture2D *plane;
@property (nonatomic, readwrite) TGLMappedTexture2D *subplane;
@property (nonatomic, readwrite) GLenum internal_format;

@property (nonatomic, readwrite) double roll;
@property (nonatomic, readwrite) double pitch;
@property (nonatomic, readwrite) double yaw;
@end

@implementation MCVCameraBufferFreight

- (void)refill:(CMSampleBufferRef)sample
{
    CVImageBufferRef buffer = CMSampleBufferGetImageBuffer(sample);

    int buffer_width = CVPixelBufferGetWidth(buffer);
    int buffer_height = CVPixelBufferGetHeight(buffer);

    self.size = CGSizeMake(buffer_width, buffer_height);

    OSType pixel_format = CVPixelBufferGetPixelFormatType(buffer);

    switch (pixel_format) {
        case kCVPixelFormatType_32BGRA:

            self.plane = [TGLMappedTexture2D createFromImageBuffer:buffer withSize:CGSizeMake(buffer_width, buffer_height) withPlaneIdx:0 withInternalFormat:GL_RGBA withSmooth:YES];

            _subplane = nil;

            self.internal_format = GL_RGBA;

            break;
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange: /* Fallthrough */
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:

            self.plane = [TGLMappedTexture2D createFromImageBuffer:buffer withSize:CGSizeMake(buffer_width, buffer_height) withPlaneIdx:0 withInternalFormat:GL_LUMINANCE withSmooth:YES];

            _subplane = [TGLMappedTexture2D createFromImageBuffer:buffer withSize:CGSizeMake(buffer_width / 2, buffer_height / 2) withPlaneIdx:1 withInternalFormat:GL_LUMINANCE_ALPHA withSmooth:YES];

            self.internal_format = GL_LUMINANCE;

            break;
        default: NSASSERT(!"Unknown frame format"); break;
    }
}

- (void)modifyAttitude:(double)roll :(double)pitch :(double)yaw
{
    _roll = roll;
    _pitch = pitch;
    _yaw = yaw;
}

+ (MCVCameraBufferFreight *)create
{
    MCVCameraBufferFreight *obj = [[[self class] alloc] init];

    return obj;
}

@end

