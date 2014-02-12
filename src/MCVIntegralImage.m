// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import "MCVIntegralImage.h"

@implementation MCVIntegralImage

+ (MCVIntegralImage *)create
{
    MCVIntegralImage *obj = [[MCVIntegralImage alloc] init];

    return obj;
}

- (BOOL)process:(MCVBufferFreight *)src to:(MCVBufferFreight *)dst
{
    const uint8_t *luminance = [src.plane lockReadonly];
    GLhalf *integral = [dst.plane lockWritable];

    const int w = dst.plane.size.width;
    const int h = dst.plane.size.height;
    uint32_t prev_integrals[w];
    //uint32_t accum = 0;

    /*
    for (int i = 0; i < w; ++i) {
        *integral++ = 0.0f;
        ++luminance;
    }
     */
    for (int i = 0; i < w; ++i) {
        integral[i] = 0;
        prev_integrals[i] = 0;//luminance[i];
    }
    for (int i = 1; i < h; ++i) {
        uint32_t accum = 0;
        for (int j = 0; j < w; ++j) {
            accum += luminance[i * w + j];
            uint32_t prev_integral = prev_integrals[j];
            prev_integrals[j] = accum + prev_integral;
            integral[i * w + j] = convertFloatToHFloat((accum + prev_integral) / (float)(w*h/4));
            //integral[i * w + j] = ((accum + prev_integral) / (float)(w*h));
        }
    }

    //memcpy(integral, integral, w *h * sizeof(float));
    /*
    for (int i = w; i < w*h; ++i) {
        if (i % w == 0) {
            accum = 0;
        }
        accum += *luminance++;
        *integral = (accum + *(integral - w)) / (GLfloat)(w*h);
        ++integral;
    }
     */

    [src.plane unlockReadonly];
    [dst.plane unlockWritable];

    return YES;
}
@end

