// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import "MCVSUSANEdgeDetector.h"

@interface MCVSUSANEdgeDetector()
@property (nonatomic) GLint attribute_input_texture_coordinate;
@property (nonatomic) GLint attribute_position;

@property (nonatomic) GLint uniform_luminance_texture;

@property (nonatomic) GLint uniform_fg_texture;
@end

@implementation MCVSUSANEdgeDetector

+(instancetype)create;
{
    MCVSUSANEdgeDetector *obj = [[[self class] alloc] init];

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
    extern char susan_edge_detector_vs_glsl[];
    extern char susan_edge_detector_fs_glsl[];

    [self setupShaderWithVS:NSSTR(susan_edge_detector_vs_glsl) withFS:NSSTR(susan_edge_detector_fs_glsl)];

    [(_vao = [TGLVertexArrayObject create]) bindBlock:^{
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
                .attribute = _attribute_input_texture_coordinate,
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
    }];

    _fbo = [TGLFrameBufferObject createEmptyFrameBuffer];
}

- (BOOL)process:(MCVBufferFreight *)src to:(MCVBufferFreight *)dst
{
    BENCHMARK("susan")
    [TGLDevice runPassiveContextSync:^{
        [_program use];

        [src.plane setUniform:_uniform_luminance_texture onUnit:1];

        [_fbo bindBlock:^{
            [dst.plane attachColorFB];

            glViewport(0, 0, dst.size.width, dst.size.height);

            [_vao bindBlock:^{
                glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            }];

            [[_fbo class] discardColor];
        }];

        [TGLProgram unuse];
    }];
    
    return YES;
}

/*
- (BOOL)process:(GLBufferFreight *)src withForeGround:(GLBufferFreight *)fg to:(GLBufferFreight *)dst
{
    BENCHMARK("susan")
    [GLDevice runOnProcessQueueSync:^(EAGLContext *_) {
        [_program use];

        [src.plane setUniform:_uniform_luminance_texture onUnit:1];
        [fg.plane setUniform:_uniform_fg_texture onUnit:2];

        [_fbo bindBlock:^{
            [dst.plane attachColorFB];

            glViewport(0, 0, dst.size.width, dst.size.height);

            [_vao bindBlock:^{
                glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            }];

            [[_fbo class] discardColor];
        }];

        [GLProgram unuse];
    }];
    
    return YES;
}
 */
@end

