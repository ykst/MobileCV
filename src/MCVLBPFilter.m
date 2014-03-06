// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import "MCVLBPFilter.h"

@interface MCVLBPFilter()
@property (nonatomic) GLint attribute_position;
@property (nonatomic) GLint attribute_inputTextureCoordinate;
@property (nonatomic) GLint uniform_luminanceTexture;
@end

@implementation MCVLBPFilter

+ (instancetype)create
{
    MCVLBPFilter *obj = [[[self class] alloc] init];

    return obj;
}

- (id)init
{
    self = [super init];
    if (self) {
        [TGLDevice runPassiveContextSync:^{
            [self _setupShader];
        }];
    }
    return self;
}

- (void)_setupShader
{
    extern char window3x3_1tex_vs_glsl[];
    extern char lbp_fs_glsl[];

    [self setupShaderWithVS:NSSTR(window3x3_1tex_vs_glsl) withFS:NSSTR(lbp_fs_glsl)];

    _vao = [TGLVertexArrayObject create];
    [_vao bind];

    _vbo = [TGLVertexBufferObject createVBOWithUsage:GL_STATIC_DRAW withAutoOffset:YES withCommand:(struct gl_vbo_object_command []){
        {
            .attribute = _attribute_position,
            .counts = 2,
            .type = GL_FLOAT,
            .elems = 4,
            .ptr = (GLfloat []) {
                -1, -1,
                1, -1,
                -1, 1,
                1, 1
            }
        },
        {
            .attribute = _attribute_inputTextureCoordinate,
            .counts = 2,
            .type = GL_FLOAT,
            .elems = 4,
            .ptr = (GLfloat []){
                0.0f, 0.0f,
                1.0f, 0.0f,
                0.0f, 1.0f,
                1.0f, 1.0f,
            }
        },
        {}
    }];

    [[_vao class] unbind];

    _fbo = [TGLFrameBufferObject createEmptyFrameBuffer];
}

- (BOOL)process:(MCVBufferFreight *)src to:(MCVBufferFreight *)dst
{
    BENCHMARK("lbp")
    [TGLDevice runPassiveContextSync:^{
        [_program use];

        [_fbo bind];

        glViewport(0, 0, src.size.width, src.size.height);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, dst.plane.name, 0);

        glActiveTexture(GL_TEXTURE2);
        [src.plane bind];
        glUniform1i(_uniform_luminanceTexture, 2);

        [_vao bind];
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        [[_vao class] unbind];

        glDiscardFramebufferEXT(GL_FRAMEBUFFER,1,(GLenum []){GL_COLOR_ATTACHMENT0});

        [[_fbo class] unbind];
        
        [TGLProgram unuse];
    }];

    return YES;
}

@end

