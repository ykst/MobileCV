//
//  MCVTexturePassthrough.m
//  Pods
//
//  Created by Yukishita Yohsuke on 2014/02/14.
//
//

#import "MCVTexturePassthrough.h"
#import "MCVTextureRenderer.h"

@interface MCVTexturePassthrough() {
    MCVTextureRenderer *_texture_renderer;
}

@end

@implementation MCVTexturePassthrough

+ (instancetype)create
{
    MCVTexturePassthrough *obj = [[[self class] alloc] init];

    return obj;
}

- (id)init
{
    self = [super init];
    if (self) {
        [TGLDevice runPassiveContextSync:^{
            [self _setupSubtasks];
            [self _setupBuffers];
        }];
    }
    return self;
}

- (void)_setupSubtasks
{
    _texture_renderer = [MCVTextureRenderer create];
}

- (void)_setupBuffers
{
    _fbo = [TGLFrameBufferObject createEmptyFrameBuffer];
}

- (BOOL)process:(MCVBufferFreight *)src to:(MCVBufferFreight *)dst
{
    [TGLDevice runPassiveContextSync:^{
        [_fbo bind];

        [dst.plane attachColorFB];

        glViewport(0, 0, dst.plane.size.width, dst.plane.size.height);

        [_texture_renderer process:src];

        [[_fbo class] discardColor];
        [[_fbo class] unbind];
    }];

    return YES;
}
@end
