// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import "MCVTextureRenderer.h"

@interface MCVTextureRenderer()

@end

@implementation MCVTextureRenderer

+ (MCVTextureRenderer *)create
{
    MCVTextureRenderer *obj = [[[self class] alloc] init];
    return obj;
}

- (id)init
{
    self = [super init];
    if (self) {
        [TGLDevice runPassiveContextSync:^{
            [self _setupShader];
            [self _setupPostProcess];
        }];
    }
    return self;
}

- (void)_setupPostProcess
{
    // be overwritten by subclass..
}

- (void)_setupShader
{
    extern char texture_render_vs_glsl[];
    extern char passthrough_1tex_fs_glsl[];

    _uniform_affine_mat = -1;

    [self setupShaderWithVS:NSSTR(texture_render_vs_glsl) withFS:NSSTR(passthrough_1tex_fs_glsl)];

    static const GLfloat image_vertices[8] = {
        -1, -1,
        1, -1,
        -1, 1,
        1, 1
    };

    static const GLfloat texture_coordinates[8] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };

    _vao = [TGLVertexArrayObject create];

    [_vao bind];

    _vbo = [TGLVertexBufferObject createVBOWithUsage:GL_STATIC_DRAW
                                     withAutoOffset:YES
                                        withCommand:(struct gl_vbo_object_command []) {
                                            {
                                                .attribute = _attribute_position,
                                                .counts = 2,
                                                .type = GL_FLOAT,
                                                .elems = 4,
                                                .ptr = image_vertices
                                            },
                                            {
                                                .attribute = _attribute_inputTextureCoordinate,
                                                .counts = 2,
                                                .type = GL_FLOAT,
                                                .elems = 4,
                                                .ptr = texture_coordinates
                                            },
                                            {}
                                        }];

    [[_vao class] unbind];

    [self setAffineMatrix:GLKMatrix3Identity];
}

- (void)setAffineMatrix:(GLKMatrix3)mat
{
    [_program use];

    glUniformMatrix3fv(_uniform_affine_mat, 1, GL_FALSE, mat.m);

    [[_program class] unuse];
}

- (BOOL)process:(MCVBufferFreight *)src
{
    [_program use];

    [src.plane setUniform:_uniform_inputTexture onUnit:0];

    [_vao bind];
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);GLASSERT;
    [[_vao class] unbind];

    [TGLProgram unuse];

    return YES;
}

@end

