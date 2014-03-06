// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import "MCVFreight.h"

@interface MCVPointFeatureFreight : MCVFreight<MCVVec4ArrayFreightProtocol>

@property (nonatomic, readwrite) int16_t maximum_classes;

// buf = [x, y, classes]
+ (instancetype)createWithCount:(size_t)count;

@end

