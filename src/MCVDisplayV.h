// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "MCVBufferFreight.h"
#import "MCVTextureRenderer.h"

@interface MCVDisplayV : GLKView

- (void)setDrawer:(MCVTextureRenderer *(^)())setter;
- (BOOL)drawBuffer:(MCVBufferFreight *)freight;

@end

