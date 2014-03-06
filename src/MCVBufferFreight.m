// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import "MCVBufferFreight.h"
#import "TGLDevice.h"
#import "NSObject+SimpleArchiver.h"

@interface MCVBufferFreightSaved : NSObject
@property (nonatomic, readwrite) CGSize size;
@property (nonatomic, readwrite) GLenum internal_format;
@property (nonatomic, readwrite) NSData *data;
@property (nonatomic, readwrite) BOOL smooth;
@property (nonatomic, readwrite) BOOL repeat; // TODO: care this

@end

@implementation MCVBufferFreightSaved

@end

@interface MCVBufferFreight() {
}
@property (nonatomic, readwrite) TGLMappedTexture2D *plane;
@property (nonatomic, readwrite) CGSize size;
@property (nonatomic, readwrite) GLenum internal_format;
@end

@implementation MCVBufferFreight

+ (instancetype)createWithSize:(CGSize)size withInternalFormat:(GLenum)internal_format withSmooth:(BOOL)smooth
{
    MCVBufferFreight *obj = [[[self class] alloc] init];

    obj.plane = [TGLMappedTexture2D createWithSize:size withInternalFormat:internal_format withSmooth:smooth];
    obj.size = size;
    obj.internal_format = internal_format;

    return obj;
}

+ (instancetype)createWithTexture:(TGLMappedTexture2D *)texture
{
    MCVBufferFreight *obj = [[[self class] alloc] init];

    obj.plane = texture;
    obj.size = texture.size;
    obj.internal_format = texture.internal_format;

    return obj;
}

+ (instancetype)createFromSaved:(NSString *)name
{
    MCVBufferFreightSaved *saved = [MCVBufferFreightSaved simpleUnarchiveForKey:name];

    MCVBufferFreight *obj = [[self class] createWithSize:saved.size withInternalFormat:saved.internal_format withSmooth:saved.smooth];

    [obj.plane useWritable:^(void *buf) {
        memcpy(buf, saved.data.bytes, saved.data.length);
    }];

    return obj;
}

- (BOOL)save:(NSString *)name
{
    // TODO: Better to be implemented in GLBufferFreighSaved factory

    MCVBufferFreightSaved *saved = [MCVBufferFreightSaved new];
    saved.size = _size;
    saved.internal_format = _internal_format;
    saved.data = [NSMutableData dataWithBytes:[_plane lockReadonly] length:_plane.num_bytes];
    saved.smooth = _plane.smooth;
    saved.smooth = _plane.repeat;

    [_plane unlockReadonly];

    return [saved simpleArchiveForKey:name];
}

- (UIImage *)uiImage
{
    return [_plane toUIImage];
}
@end

