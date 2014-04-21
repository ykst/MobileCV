// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import "MCVAdaptiveThreshold.h"

@interface MCVAdaptiveThreshold()
@property (nonatomic) GLint attribute_input_texture_coordinate;
@property (nonatomic) GLint attribute_position;

@property (nonatomic) GLint uniform_integral_texture;
@property (nonatomic) GLint uniform_luminance_texture;
@property (nonatomic) GLint uniform_area;
@property (nonatomic) GLint uniform_window;
@end

@implementation MCVAdaptiveThreshold

+(instancetype)createWithBias:(GLfloat)bias withScreenSize:(CGSize)screen_size withWindowSize:(CGSize)window_size

{
    MCVAdaptiveThreshold *obj = [[[self class] alloc] initWithBias:bias withScreenSize:(CGSize)screen_size  withWindowSize:window_size];

    return obj;
}

- (id)initWithBias:(GLfloat)bias withScreenSize:(CGSize)screen_size withWindowSize:(CGSize)window_size

{
    self = [super init];
    if (self) {
        [TGLDevice runPassiveContextSync:^{
            [self _setupShader];

            [_program use];
            glUniform1f(_uniform_area, window_size.width * window_size.height / (screen_size.width * screen_size.height) * bias);
            glUniform2f(_uniform_window, window_size.width / screen_size.width, window_size.height / screen_size.height);
            [[_program class] unuse];
        }];
    }
    return self;
}

- (void)_setupShader
{
    extern char adaptive_threshold_vs_glsl[];
    extern char adaptive_threshold_fs_glsl[];

    [self setupShaderWithVS:NSSTR(adaptive_threshold_vs_glsl) withFS:NSSTR(adaptive_threshold_fs_glsl)];

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

- (BOOL)process:(MCVBufferFreight *)src withIntegral:(MCVBufferFreight *)integral to:(MCVBufferFreight *)dst
{
    BENCHMARK("adaptive threshold")
    [TGLDevice runPassiveContextSync:^{
        [_program use];

        [src.plane setUniform:_uniform_luminance_texture onUnit:1];
        [integral.plane setUniform:_uniform_integral_texture onUnit:0];

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

@end

