// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import "MCVConnectedComponentLabeling.h"
#import "TGLDevice.h"

struct label_def {
    uint16_t min_x;
    uint16_t min_y;
    uint16_t max_x;
    uint16_t max_y;
    uint32_t cnt;
    uint32_t mark;
};

#define MAX_LABELS 1024
@interface MCVConnectedComponentLabeling() {
    CGSize _size;
    NSMutableData *_tmp;
    struct label_def _defs[MAX_LABELS];
}

@property (nonatomic, readwrite) GLint attribute_position;
@property (nonatomic, readwrite) GLint uniform_image_tex;
@property (nonatomic, readwrite) GLint uniform_mode;
@property (nonatomic, readwrite) GLint uniform_mvp;
@end

@implementation MCVConnectedComponentLabeling

+(MCVConnectedComponentLabeling *)createWithSize:(CGSize)size
{
    id obj = [[[self class] alloc] initWithSize:size];

    return obj;
}

- (id)initWithSize:(CGSize)size
{
    self = [super init];
    if (self) {
        _size = size;

        // we do not make a fully labeled image but its logical blob informations. so 1 line of working buffer is suffice
        _tmp = [NSMutableData dataWithLength:(size.width * sizeof(uint16_t))];
        memset(_tmp.mutableBytes, 0x00, _tmp.length);

        [TGLDevice runPassiveContextSync:^{
            [self _setupShader];
        }];
    }
    return self;
}

- (void)_setupShader
{
    extern char ccl_vs_glsl[];
    extern char ccl_fs_glsl[];

    [self setupShaderWithVS:NSSTR(ccl_vs_glsl) withFS:NSSTR(ccl_fs_glsl)];

    [(_vao = [TGLVertexArrayObject create]) bindBlock:^{
        _vbo = [TGLVertexBufferObject createVBOWithUsage:GL_STATIC_DRAW withAutoOffset:YES withCommand:(struct gl_vbo_object_command []){
            { // TRIANGLE_FAN and LINE_LOOP
                .attribute = _attribute_position,
                .counts = 2,
                .type = GL_FLOAT,
                .elems = 4,
                .ptr = (GLfloat []) {
                    -1, -1,
                    1, -1,
                    1, 1,
                    -1, 1
                }
            },
            {}
        }];
    }];

    _fbo = [TGLFrameBufferObject createEmptyFrameBuffer];
}

static inline int __filter_blobs(
                                   struct label_def defs[MAX_LABELS],
                                   int max_label)
{
    int copy_idx = 0;

    for (int i = 1; i <= max_label; ++i) {
        int ww = defs[i].max_x - defs[i].min_x;
        int hh = defs[i].max_y - defs[i].min_y;

        if ((defs[i].mark == i) &&
            (ww > 2 && hh > 2) &&
            (ww < 100  && hh < 100)) {
            defs[copy_idx++] = defs[i];
        }
    }

    return copy_idx;
}

// ref: A Simple and Efficient Connected Components Labeling Algorithm
// http://www.researchgate.net/publication/3820852_A_simple_and_efficient_connected_components_labeling_algorithm/file/60b7d51496cb6be714.pdf
// TODO: 微妙に間違ってるけど、性能は悪くないので放置している
static inline int __extract_blobs(
                                   struct label_def defs[MAX_LABELS],
                                   const uint8_t * restrict img,
                                   uint16_t * restrict tmp,
                                   int w,
                                   int h)
{
    // 4-neighbour connection
    //    p
    //  q o
    uint16_t *p; // label(q) is cached

    uint16_t label_idx = 0;
    struct label_def *odef = NULL;

    img += w * 4;

    for (int i = 1; i < h; ++i) {
        p = tmp + 1;
        uint16_t lq = 0;

        img += 4;

        for (int j = 1; j < w; ++j) {
            uint16_t lo = 0;

            if (*img) {
                uint16_t lp = *p;

                if (!lp && !lq) {
                    if (label_idx >= MAX_LABELS - 1) {
                        return label_idx;
                    }

                    lo = ++label_idx;

                    struct label_def *ndef = &defs[lo];

                    ndef->min_x = j;
                    ndef->max_x = j;
                    ndef->min_y = i;
                    ndef->mark = lo;
                    ndef->cnt = 0;

                    odef = ndef;

                } else if (lp && lq && defs[lp].mark != defs[lq].mark) {
                    struct label_def *qdef = &defs[lq];
                    struct label_def *pdef = &defs[lp];

                    defs[lp].mark = defs[lq].mark;

                    qdef->min_x = MIN(qdef->min_x, pdef->min_x);
                    qdef->min_y = MIN(qdef->min_y, pdef->min_y);
                    qdef->max_x = MAX(qdef->max_x, pdef->max_x);
                    qdef->max_y = MAX(qdef->max_y, pdef->max_y);
                    qdef->cnt += pdef->cnt;

                    lo = lq;
                } else if (lq) {
                    lo = lq;
                } else if (lp) {
                    lo = lp;
                    odef = &defs[lo];
                }

                odef->max_y = i;
                odef->max_x = MAX(odef->max_x, j);
                ++odef->cnt;
            }
            *p = lo;
            lq = lo;
            ++p;
            img += 4;
        }
    }

    return label_idx;
}

static inline int __ccl_process(
                                struct label_def defs[MAX_LABELS],
                                const uint8_t * restrict img,
                                uint16_t * restrict tmp,
                                int w,
                                int h)
{
    memset(tmp, 0x00, w * sizeof(*tmp));

    int max_label = __extract_blobs(defs, img, tmp, w, h);
    return __filter_blobs(defs, max_label);
}

- (BOOL)debugProcess:(MCVBufferFreight *)src to:(MCVBufferFreight *)dst
{
    int max_label = 0;

    BENCHMARK("cc labeling")
    max_label = __ccl_process(_defs, [src.plane lockReadonly], _tmp.mutableBytes, _size.width, _size.height);

    [src.plane unlockReadonly];

    [TGLDevice runPassiveContextSync:^{
        [_program use];

        glLineWidth(2);

        [src.plane setUniform:_uniform_image_tex onUnit:0];

        [_fbo bindBlock:^{
            [dst.plane attachColorFB];

            glViewport(0, 0, dst.size.width, dst.size.height);

            [_vao bindBlock:^{
                GLKMatrix3 mat = {};
                mat.m00 = 1;
                mat.m11 = 1;
                mat.m22 = 1;

                glUniformMatrix3fv(_uniform_mvp, 1, GL_FALSE, mat.m);
                glUniform1i(_uniform_mode, 0);
                glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
                glUniform1i(_uniform_mode, 1);

                for (int i = 0; i < max_label; ++i) {
                    struct label_def *p = &_defs[i];
                    int ww = p->max_x - p->min_x;
                    int hh = p->max_y - p->min_y;

                    mat.m00 = ww / _size.width;
                    mat.m02 = (2.0 * p->min_x + ww) / _size.width - 1.0;
                    mat.m11 = hh / _size.height;
                    mat.m12 = (2.0 * p->min_y + hh) / _size.height - 1.0;

                    glUniformMatrix3fv(_uniform_mvp, 1, GL_FALSE, mat.m);
                    glDrawArrays(GL_LINE_LOOP, 0, 4);
                }
            }];

            [[_fbo class] discardColor];
        }];
        
        [TGLProgram unuse];
    }];

    return YES;
}

- (NSArray *)process:(MCVBufferFreight *)src
{
    int max_label = 0;

    BENCHMARK("cc labeling")
    max_label = __ccl_process(_defs, [src.plane lockReadonly], _tmp.mutableBytes, _size.width, _size.height);

    NSMutableArray *result = [NSMutableArray arrayWithCapacity:max_label];

    for (int i = 0; i < max_label; ++i) {
        MCVConnectedComponent *c = [MCVConnectedComponent new];
        struct label_def *p = &_defs[i];

        c.rect = CGRectMake(_size.width - p->min_x, p->min_y, p->max_x - p->min_x, p->max_y - p->min_y);
        c.density = p->cnt / (float)(c.rect.size.width * c.rect.size.height);

        result[i] = c;
    }

    return result;
}

@end

@implementation MCVConnectedComponent

- (CGPoint)centroid
{
    return CGPointMake(_rect.origin.x - _rect.size.width / 2.0, _rect.origin.y + _rect.size.height / 2.0);
}
@end

