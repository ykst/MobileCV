// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import "TGLShaderWrapper.h"
#import "MCVBufferFreight.h"

@interface MCVConnectedComponent : NSObject
@property (nonatomic, readwrite) CGRect rect;
@property (nonatomic, readwrite) float density;
@property (nonatomic, readonly) CGPoint centroid;
@end

@interface MCVConnectedComponentLabeling : TGLShaderWrapper

+ (MCVConnectedComponentLabeling *)createWithSize:(CGSize)size;
- (BOOL)debugProcess:(MCVBufferFreight *)src to:(MCVBufferFreight *)dst;

// array of GLConnectedComponent
- (NSArray *)process:(MCVBufferFreight *)src;

@end

