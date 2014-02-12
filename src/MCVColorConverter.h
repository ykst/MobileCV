// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import <Foundation/Foundation.h>
#import "MCVBufferFreight.h"
#import "TGLShaderWrapper.h"

@interface MCVColorConverter : TGLShaderWrapper

typedef NS_ENUM(NSInteger, GLColorConverterType) {
    GLCCV_TYPE_RGBA_YUV420P,
    GLCCV_TYPE_YUV420P_RGBA,
};

+ (MCVColorConverter *)createWithType:(GLColorConverterType)type;

- (BOOL)process:(MCVBufferFreight *)src to:(MCVBufferFreight *)dst;
@end

