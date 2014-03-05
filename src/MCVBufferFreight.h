// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import "MCVFreight.h"
#import <AVFoundation/AVFoundation.h>
#import "TGLDevice.h"
#import "TGLMappedTexture2D.h"

@interface MCVBufferFreight : MCVFreight

@property (nonatomic, readwrite) NSArray *ext; // FIXME: bullshit
@property (nonatomic, readonly) TGLMappedTexture2D *plane;
@property (nonatomic, readonly) CGSize size;
@property (nonatomic, readonly) GLenum internal_format;
@property (nonatomic, readwrite) GLKVector3 user_accel;

+ (MCVBufferFreight *)createWithSize:(CGSize)size withInternalFormat:(GLenum)internal_format withSmooth:(BOOL)smooth;
+ (MCVBufferFreight *)createWithTexture:(TGLMappedTexture2D *)texture;
+ (MCVBufferFreight *)createFromSaved:(NSString *)name;
- (BOOL)save:(NSString *)name;
- (UIImage *)uiImage;
@end


@protocol MCVSubPlanerBufferProtocol <NSObject>
@required
@property (nonatomic, readonly) TGLMappedTexture2D *subplane;
@end

