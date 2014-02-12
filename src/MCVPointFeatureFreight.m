// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import "MCVPointFeatureFreight.h"

@interface MCVPointFeatureFreight()
@property (nonatomic, readwrite) size_t total_elems;
@property (nonatomic, readwrite) GLKVector4 *buf;
@end

@implementation MCVPointFeatureFreight
@synthesize effective_elems = _effective_elems;
+ (MCVPointFeatureFreight *)createWithCount:(size_t)count
{
    MCVPointFeatureFreight *obj = [[MCVPointFeatureFreight alloc] init];

    TALLOCS(obj.buf, count, NSASSERT(!"OOM"));

    obj.total_elems = count;
    obj.effective_elems = 0;

    return obj;
}

- (void)dealloc
{
    if (_buf) {
        FREE(_buf);
    }
}

@end

