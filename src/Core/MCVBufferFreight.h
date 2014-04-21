// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import "MCVFreight.h"
#import <AVFoundation/AVFoundation.h>
#import "TGLDevice.h"
#import "TGLMappedTexture2D.h"

@interface MCVBufferFreight : MCVFreight {
    @protected
    CGSize _size;
    TGLMappedTexture2D *_plane;
    GLenum _internal_format;
}

@property (nonatomic, readwrite) NSArray *ext; // FIXME: bullshit
@property (nonatomic, readonly) TGLMappedTexture2D *plane;
@property (nonatomic, readonly) CGSize size;
@property (nonatomic, readonly) GLenum internal_format;
@property (nonatomic, readonly) BOOL smooth;
@property (nonatomic, readwrite) GLKVector3 user_accel;

// NOTE: It assumes running under passive GL-context in all methods
+ (instancetype)createWithSize:(CGSize)size withInternalFormat:(GLenum)internal_format withSmooth:(BOOL)smooth;
+ (instancetype)createWithTexture:(TGLMappedTexture2D *)texture;
+ (instancetype)createFromSaved:(NSString *)name;
- (BOOL)save:(NSString *)name;
- (UIImage *)uiImage;
- (BOOL)resize:(CGSize)size;
@end


@protocol MCVSubPlanerBufferProtocol <NSObject>
@required
@property (nonatomic, readonly) TGLMappedTexture2D *subplane;
@end

