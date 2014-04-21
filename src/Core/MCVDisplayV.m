// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import "MCVDisplayV.h"
#import "TGLDevice.h"
#import "TGLProgram.h"
#import "TGLVertexArrayObject.h"
#import "TGLVertexBufferObject.h"
#import "TGLFrameBufferObject.h"
#import "MCVTextureRenderer.h"

@interface MCVDisplayV() 
@end

@implementation MCVDisplayV

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self _init];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];

    if (self) {
        [self _init];
	}

	return self;
}

- (void)_init
{
    self.opaque = YES;
    self.hidden = NO;
    if ([self respondsToSelector:@selector(setContentScaleFactor:)]) {
        self.contentScaleFactor = [[UIScreen mainScreen] scale];
    }

    CAEAGLLayer *eagl_layer = (CAEAGLLayer *)self.layer;
    eagl_layer.opaque = YES;
    eagl_layer.drawableProperties = @{
                                      kEAGLDrawablePropertyRetainedBacking:@(NO),
                                      kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8
                                      };

    [TGLDevice runMainThreadSync:^{
        _fbo = [TGLFrameBufferObject createOnEAGLStorage:[TGLDevice currentContext] withLayer:eagl_layer];
        _drawer = [MCVTextureRenderer create];

        [_drawer setAffineMatrix:GLKMatrix3Make(-1, 0, 1, 0, 1, 0, 0, 0, 1)];
    }];
}

- (void)setDrawer:(MCVTextureRenderer *(^)())setter
{
    [TGLDevice runMainThreadSync:^{
        _drawer = setter();
    }];
}

- (BOOL)drawBuffer:(MCVBufferFreight *)freight
{
    __block BOOL ret = NO;

    [TGLDevice runMainThreadSync:^{
        [_fbo bind];
        glViewport(0, 0, _fbo.size.width, _fbo.size.height);GLASSERT;

        ret = [_drawer process:freight];

        [[_fbo class] discardColor];
        
        [_fbo.lying_rbo bind];
        [[TGLDevice currentContext] presentRenderbuffer:GL_RENDERBUFFER];GLASSERT;
        [[_fbo.lying_rbo class] unbind];

        [[_fbo class] unbind];
    }];

    return ret;
}

@end

