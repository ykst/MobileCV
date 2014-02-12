// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import <Foundation/Foundation.h>
#import "MCVBufferFreight.h"
#import "MCVPointFeatureFreight.h"
#import "TGLShaderWrapper.h"

@interface MCVKMeanClustering : TGLShaderWrapper

+ (MCVKMeanClustering *)createWithMaxPoints:(size_t)points;

- (BOOL)process:(MCVPointFeatureFreight *)srcdst;

@end

