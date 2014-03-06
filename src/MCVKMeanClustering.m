// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import "MCVKMeanClustering.h"
#import "TGLDevice.h"
#import "TGLProgram.h"
#import "TGLVertexBufferObject.h"
#import "TGLVertexArrayObject.h"
#import "TGLFrameBufferObject.h"
#import "TGLTexture2D.h"


// Algorithm inspired by:
//   http://researchweb.iiit.ac.in/~wasif.mpg08/fulltext.pdf

@interface MCVKMeanClustering() {
    TGLVertexBufferObject *_vbo_line_map;
    TGLVertexArrayObject *_vao_line_map;

    TGLVertexBufferObject *_vbo_point_map;
    TGLVertexArrayObject *_vao_point_map;

    TGLMappedTexture2D *_location_tex;
    TGLMappedTexture2D *_classified_tex;
    TGLMappedTexture2D *_centroid_tex;
    TGLTexture2D *_accumulation_tex;

    GLsizei _max_points;
}
@property (nonatomic) GLint attribute_position;

@property (nonatomic) GLint uniform_locationTexture;
@property (nonatomic) GLint uniform_classifiedTexture;
@property (nonatomic) GLint uniform_centroidTexture;
@property (nonatomic) GLint uniform_accumulationTexture;

@property (nonatomic) GLint uniform_mode;
@property (nonatomic) GLint uniform_clearValue;
@property (nonatomic) GLint uniform_classStep;
@property (nonatomic) GLint uniform_threshold;
@property (nonatomic) GLint uniform_inputClusterId;
@end

@implementation MCVKMeanClustering

// TODO: paramerize
static const int maximum_cluster_num = 14;

+ (instancetype)createWithMaxPoints:(size_t)points
{
    MCVKMeanClustering *obj = [[[self class] alloc] initWithMaxPoints:points];

    return obj;
}

- (id)initWithMaxPoints:(size_t)points
{
    self = [super init];
    if (self) {

        [TGLDevice runPassiveContextSync:^{
            _max_points = points;
            [self _setupShader];
        }];

    }
    return self;
}

- (void)_setupShader
{
    extern char kmeans_vs_glsl[];
    extern char kmeans_fs_glsl[];

    [self setupShaderWithVS:NSSTR(kmeans_vs_glsl) withFS:NSSTR(kmeans_fs_glsl)];

    _vao_line_map = [TGLVertexArrayObject create];

    [_vao_line_map bind];

    _vbo_line_map = [TGLVertexBufferObject createVBOWithUsage:GL_STATIC_DRAW
                                     withAutoOffset:YES
                                        withCommand:(struct gl_vbo_object_command[]){
                                            {
                                                .attribute = _attribute_position,
                                                .counts = 2,
                                                .type = GL_FLOAT,
                                                .elems = maximum_cluster_num * 2 + 2,
                                                .ptr = NULL
                                            },
                                            {} // centinel
                                        }];
    
    [[_vao_line_map class] unbind];

    _vao_point_map = [TGLVertexArrayObject create];

    [_vao_point_map bind];

    GLfloat *point_map = NULL;
    TALLOCS(point_map, _max_points, NSASSERT(!"OOM"));
    for (int i = 0; i < _max_points; ++i) {
        point_map[i] = ((i * 2.0 + 1.0) / (_max_points * 2.0)) * 2.0 - 1.0;
    }
    _vbo_point_map = [TGLVertexBufferObject createVBOWithUsage:GL_STATIC_DRAW
                                              withAutoOffset:YES
                                                 withCommand:(struct gl_vbo_object_command[]){
                                                     {
                                                         .attribute = _attribute_position,
                                                         .counts = 1,
                                                         .type = GL_FLOAT,
                                                         .elems = _max_points,
                                                         .ptr = point_map
                                                     },
                                                     {} // centinel
                                                 }];
    FREE(point_map);
    [[_vao_point_map class] unbind];
    
    _fbo = [TGLFrameBufferObject createEmptyFrameBuffer];

    _location_tex = [TGLMappedTexture2D createWithSize:CGSizeMake(_max_points, 1) withInternalFormat:GL_RGBA16F_EXT withSmooth:NO];

    _classified_tex = [TGLMappedTexture2D createWithSize:CGSizeMake(_max_points, 1) withInternalFormat:GL_RGBA16F_EXT withSmooth:NO];

    _centroid_tex = [TGLMappedTexture2D createWithSize:CGSizeMake(_max_points, 1) withInternalFormat:GL_RGBA16F_EXT withSmooth:NO];

    _accumulation_tex = [TGLTexture2D createWithSize:CGSizeMake(1, 1) withInternalFormat:GL_RGBA16F_EXT withSmooth:NO];

    [_program use];
    glUniform1f(_uniform_classStep, 2.0 / (GLfloat)_max_points);
    [TGLProgram unuse];
}

static void __sort_centroid_buf_by_x(GLhalf *buf, size_t point_count)
{
    qsort_b(buf, point_count, sizeof(GLhalf) * 4, ^(const void* a, const void* b) {
        GLfloat diff = convertHFloatToFloat(((GLhalf*)(a))[0]) - convertHFloatToFloat(((GLhalf*)(b))[0]);
        return diff > 0 ? 1 : (diff < 0 ? -1 : 0);
    });
}

- (void)_setupFixedValues
{
    glViewport(0, 0, _max_points, 1);
    glLineWidth(1.0);

    glClearColor(0, 0, 0, 0);

    glActiveTexture(GL_TEXTURE1);
    [_centroid_tex bind];
    glUniform1i(_uniform_centroidTexture, 1);GLASSERT;

    glActiveTexture(GL_TEXTURE2);
    [_location_tex bind];
    glUniform1i(_uniform_locationTexture, 2);GLASSERT;

    glActiveTexture(GL_TEXTURE3);
    [_classified_tex bind];
    glUniform1i(_uniform_classifiedTexture, 3);GLASSERT;

    glActiveTexture(GL_TEXTURE4);
    [_accumulation_tex bind];
    glUniform1i(_uniform_accumulationTexture, 3);GLASSERT;
}

- (void)_setupVBO:(int)effective_points
{
    GLKVector2 vertex_info[maximum_cluster_num * 2 + 2];

    for (int i = 0; i < maximum_cluster_num; ++i) {
        vertex_info[2*i].x = (1.0 / (_max_points * 2.0)) * 2.0 - 1.0;
        vertex_info[2*i].y = i;
        vertex_info[2*i+1].x = ((effective_points * 2.0 + 1.0) / (_max_points * 2.0)) * 2.0 - 1.0;
        vertex_info[2*i+1].y = i;
    }

    // XXX: クラスタの数だけの長さの奴をケツに同居
    vertex_info[2*maximum_cluster_num].x = (1.0 / (_max_points * 2.0)) * 2.0 - 1.0;
    vertex_info[2*maximum_cluster_num].y = 0;
    vertex_info[2*maximum_cluster_num+1].x = ((maximum_cluster_num * 2.0 + 1.0) / (_max_points * 2.0)) * 2.0 - 1.0;
    vertex_info[2*maximum_cluster_num+1].y = 0;

    [_vbo_line_map subDataOfAttribute:_attribute_position
                          withPointer:vertex_info
                            withElems:maximum_cluster_num * 2 + 2];
}

#if 0
BENCHMARK("kmeans mapping")
[_centroid_tex useWritable:^(void *buf) {
    GLhalf *centroid = buf;

    if (centroid_idx == 0) {
        int initial_centorid_idx = arc4random() % effective_points;
        centroid[0] = convertFloatToHFloat(point_buf[4*initial_centorid_idx]);
        centroid[1] = convertFloatToHFloat(point_buf[4*initial_centorid_idx+1]);
    } else {
        [_classified_tex useWritable:^(void *buf) {
            GLhalf *classified = buf;

            float sum = 0.0f;

            for (int sum_idx = 0; sum_idx < effective_points; ++sum_idx) {
                float d = convertHFloatToFloat(classified[4*sum_idx+3]);
                sum += d * d;
            }

            float target = sum * (arc4random()/(float)UINT32_MAX);

            sum = 0.0f;
            for (int seek_idx = 0; seek_idx < effective_points; ++seek_idx) {
                float d = convertHFloatToFloat(classified[4*seek_idx+3]);
                sum += d * d;
                if (sum >= target) {
                    // new centroid;
                    centroid[4 * centroid_idx] = convertFloatToHFloat(point_buf[4*seek_idx]);
                    centroid[4 * centroid_idx + 1] = convertFloatToHFloat(point_buf[4*seek_idx + 1]);
                    break;
                }
            }
        }];
    }
}];
#endif

static void __sort_point_buf_by_x(GLfloat *buf, size_t point_count)
{
    qsort_b(buf, point_count, sizeof(GLfloat) * 4, ^(const void* a, const void* b) {
        GLfloat diff = (((GLfloat*)(a))[0] - ((GLfloat*)(b))[0]);
        return diff > 0 ? 1 : (diff < 0 ? -1 : 0);
    });
}

- (void)_initCentroids:(GLfloat *)point_buf withEffectivePoints:(int)effective_points
{
    [_centroid_tex useWritable:^(void *buf) {
        GLhalf *bufhalf = buf;
        const GLfloat ymin = point_buf[4 * 0 + 1];
        const GLfloat ymax = point_buf[4 * (effective_points - 1) + 1];

        __sort_point_buf_by_x(point_buf, effective_points);

        const GLfloat xmin = point_buf[4 * 0 + 0];
        const GLfloat xmax = point_buf[4 * (effective_points - 1) + 0];

        const GLfloat xstep = (xmax - xmin) / (2.0 * maximum_cluster_num);

        for (int i = 0; i < maximum_cluster_num; ++i) {
            // [Cx, Ci, (no care), (no care)
            bufhalf[4*i] = convertFloatToHFloat(xmin + xstep * (2 * i + 1));
            bufhalf[4*i+1] = convertFloatToHFloat((ymax - ymin) / 2.0 + ymin);
        }
    }];

#if 0 // KMeans++。全てGPUでやったところ、serializeが酷い事になって全く速度が出なかったのでボツ
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _centroid_tex.name, 0);

    glClear(GL_COLOR_BUFFER_BIT);

    // 一つ目の重心はランダム
    [_centroid_tex useWritable:^(void *buf) {
        GLhalf *centroid = buf;

        int initial_centorid_idx = arc4random() % effective_points;
        centroid[0] = convertFloatToHFloat(point_buf[4*initial_centorid_idx]);
        centroid[1] = convertFloatToHFloat(point_buf[4*initial_centorid_idx+1]);
    }];

    // k-means++ ref: http://webcache.googleusercontent.com/search?q=cache:http://ilpubs.stanford.edu:8090/778/1/2006-13.pdf
    for (int centroid_idx = 1; centroid_idx < maximum_cluster_num; ++centroid_idx) {
        //========================
        // Phase 1: Line Mapping
        // 距離比較を行うための初期値として十分大きい値をセットする
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _classified_tex.name, 0);

        [_vao_line_map bind];
        glUniform1i(_uniform_mode, 0);GLASSERT;

        glUniform1f(_uniform_clear_value, 10.0f);GLASSERT;
        glDrawArrays(GL_LINES, 0, 2);GLASSERT;

        //========================
        // Phase 2: Line Mapping + Framebuffer Fetch
        // 各点に最も近い重心を持つクラスを選択して、_classfied_texに[Px,Py,Class,Distance]でマッピングする
        glUniform1i(_uniform_mode, 1);
        glDrawArrays(GL_LINES, 0, (centroid_idx + 1) * 2);GLASSERT;

        //========================
        // Phase 3: Point Mapping + Framebuffer Fetch
        // accumulation bufferに距離の自乗和を加算
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _accumulation_tex.name, 0);
        glClear(GL_COLOR_BUFFER_BIT);

        [_vao_point_map bind];
        glUniform1i(_uniform_mode, 4);
        glDrawArrays(GL_POINTS, 0, effective_points);GLASSERT;

        //========================
        // Phase 4: Point Mapping + Framebuffer Fetch
        // uniformに乱数を入れてもう一度自乗和を取りつつ重み付きランダムサンプリング
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _centroid_tex.name, 0);
        glUniform1f(_uniform_threshold, arc4random()/(float)UINT32_MAX);
        glUniform1f(_uniform_input_cluster_id, centroid_idx);

        glUniform1i(_uniform_mode, 5);
        glDrawArrays(GL_POINTS, 0, effective_points);GLASSERT;
    }

    [GLDevice fenceSync];

    [self _sortCentroids];
#endif
}

- (void)_doKMeans:(GLfloat *)point_buf withEffectivePoints:(int)effective_points
{
    static const int num_iteration = 5;

    for (int i = 0; i < num_iteration; ++i) {
        //========================
        // Phase 1: ラインマッピング
        // 距離比較を行うための初期値として十分大きい値をセットする
        glUniform1i(_uniform_mode, 0);GLASSERT;

        [_vao_line_map bind];

        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _classified_tex.name, 0);

        glUniform1f(_uniform_clearValue, 10.0f);GLASSERT;
        glDrawArrays(GL_LINES, 0, 2);GLASSERT;

        //========================
        // Phase 2: Line Mapping + Framebuffer Fetch
        // 各点に最も近い重心を持つクラスを選択して、_classfied_texに[Px,Py,Class,Distance]でマッピングする
        glUniform1i(_uniform_mode, 1);

        glDrawArrays(GL_LINES, 0, maximum_cluster_num * 2);GLASSERT;

        //========================
        // Phase 3: Line Mapping + Blend(ADD)
        // 重心計算のためのaccumulation bufferとして_centroid_texを初期化する
        glUniform1i(_uniform_mode, 0);GLASSERT;

        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _centroid_tex.name, 0);

        glUniform1f(_uniform_clearValue, 0.0f);GLASSERT;

        // XXX: 最後尾に短い線を引いてあるが分かりにくい
        glDrawArrays(GL_LINES, maximum_cluster_num * 2, 2);GLASSERT;

        //========================
        // Phase 4: Point Mapping + Scattered Accumulation
        // 各クラス毎の距離の重み付き和を_centroid_texにマッピングする
        glUniform1i(_uniform_mode, 2);

        [_vao_point_map bind];

        glDrawArrays(GL_POINTS, 0, effective_points);GLASSERT;

        //========================
        // Phase 5: Line Mapping
        // 重み付き平均を_centroid_texにマッピングする。
        glUniform1i(_uniform_mode, 3);
        [_vao_line_map bind];
        glDrawArrays(GL_LINES, maximum_cluster_num * 2, 2);GLASSERT;
    }
}

- (void)_sortCentroids
{
    [_centroid_tex useWritable:^(void *buf) {
        GLhalf *bufhalf = buf;
        __sort_centroid_buf_by_x(bufhalf, maximum_cluster_num);
    }];
}

- (void)_makeLocationTexture:(GLfloat *)point_buf withEffectivePoints:(int)effective_points
{
    [_location_tex useWritable:^(void *buf) {
        GLhalf *bufhalf = buf;

        for (int i = 0; i < effective_points; ++i) {
            // [Px, Py, (no care), Weight]
            bufhalf[4*i] = convertFloatToHFloat(point_buf[4*i]);
            bufhalf[4*i + 1] = convertFloatToHFloat(point_buf[4*i + 1]);
            //bufhalf[4*i + 3] = convertFloatToHFloat(point_buf[4*i + 3]);
            bufhalf[4*i + 3] = convertFloatToHFloat(1);
        }
    }];
}

- (BOOL)process:(MCVPointFeatureFreight *)srcdst;
{
    GLfloat *point_buf = (GLfloat *)srcdst.buf;
    GLsizei effective_points = srcdst.effective_elems;

    // nothing to do when clustering target did not present
    if (effective_points < maximum_cluster_num) return YES;

    BENCHMARK("clustering")
    [TGLDevice runPassiveContextSync:^{
        [self _setupVBO:effective_points];

        [_program use];

        [_fbo bind];

        [self _setupFixedValues];

        [_vao_line_map bind];

        //BENCHMARK("kmeans++")
        [self _initCentroids:point_buf withEffectivePoints:effective_points];

        [self _makeLocationTexture:point_buf withEffectivePoints:effective_points];

        BENCHMARK("kmeans")
        [self _doKMeans:point_buf withEffectivePoints:effective_points];

        [[_vao_line_map class] unbind];

        glDiscardFramebufferEXT(GL_FRAMEBUFFER,1,(GLenum []){GL_COLOR_ATTACHMENT0});

        [[_fbo class] unbind];

        [TGLProgram unuse];
    }];

    [_classified_tex useReadOnly:^(const void * buf) {
        const GLhalf *class_buf = buf;
        for (int i = 0; i < effective_points; ++i) {
            point_buf[4*i + 2] = convertHFloatToFloat(class_buf[4*i+2]);
        }
    }];

    return YES;
}

@end

