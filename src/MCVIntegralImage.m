// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import "MCVIntegralImage.h"

@implementation MCVIntegralImage

+ (MCVIntegralImage *)create
{
    MCVIntegralImage *obj = [[MCVIntegralImage alloc] init];

    return obj;
}

static inline void __process_luminance(const uint8_t * restrict src,
                                       GLhalf * restrict dst,
                                       const int w, const int h)
{
    uint32_t prev_integrals[w];

    const float area = (float)((w*h)/4);

    for (int i = 0; i < w; ++i) {
        dst[i] = 0;
        prev_integrals[i] = 0;//luminance[i];
    }

    for (int i = 1; i < h; ++i) {
        uint32_t accum = 0;
        for (int j = 0; j < w; ++j) {
            accum += src[i * w + j];
            uint32_t prev_integral = prev_integrals[j];
            prev_integrals[j] = accum + prev_integral;
            dst[i * w + j] = convertFloatToHFloat((accum + prev_integral) / area);
        }
    }
}

static inline void __process_rgba(const uint8_t * restrict src,
                                       GLhalf * restrict dst,
                                       const int w, const int h)
{
    uint32_t prev_integrals[w];

    const float area = (float)((w*h)/4);

    for (int i = 0; i < w; ++i) {
        dst[i] = 0;
        prev_integrals[i] = 0;//luminance[i];
    }

    // process red component only
    for (int i = 1; i < h; ++i) {
        uint32_t accum = 0;
        for (int j = 0; j < w; ++j) {
            accum += src[i * (w * 4) + (j * 4)];
            uint32_t prev_integral = prev_integrals[j];
            prev_integrals[j] = accum + prev_integral;
            dst[i * w + j] = convertFloatToHFloat((accum + prev_integral) / area);
        }
    }
}

- (BOOL)process:(MCVBufferFreight *)src to:(MCVBufferFreight *)dst
{
    NSASSERT(dst.internal_format == GL_LUMINANCE16F_EXT);

    const void *src_buf = [src.plane lockReadonly];
    GLhalf *dst_buf = [dst.plane lockWritable];

    const int w = dst.plane.size.width;
    const int h = dst.plane.size.height;

    BENCHMARK("integral")
    switch (src.internal_format) {
        case GL_LUMINANCE:
            __process_luminance(src_buf, dst_buf, w, h);
            break;
        case GL_RGBA:
            __process_rgba(src_buf, dst_buf, w, h);
            break;
        default:
            NSASSERT(!"Illegal format");
            break;
    }

    [src.plane unlockReadonly];
    [dst.plane unlockWritable];

    return YES;
}
@end

