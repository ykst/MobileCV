// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php

#import "MCVGenSDFTexture.h"
#import "MCVSUSANEdgeDetector.h"

@interface MCVGenSDFTexture() {
    @protected
    MCVSUSANEdgeDetector *_susan;
    TGLMappedTexture2D *_tmp;
    CGSize _output_size;
}
@property (nonatomic, readwrite) GLint attribute_position;
@end

@implementation MCVGenSDFTexture

+ (MCVGenSDFTexture *)createWithOutputSize:(CGSize)size
{
    id obj = [[[self class] alloc] initWithSize:size];

    return obj;
}

- (id)initWithSize:(CGSize)size
{
    self = [super init];
    if (self) {
        _output_size = size;

        [TGLDevice runPassiveContextSync:^{
            _tmp = [TGLMappedTexture2D createWithSize:_output_size withInternalFormat:GL_RGBA withSmooth:NO];
            _susan = [MCVSUSANEdgeDetector create];
        }];
    }
    return self;
}

- (TGLMappedTexture2D *)process:(MCVBufferFreight *)src
{
    [_susan process:src to:[MCVBufferFreight createWithTexture:_tmp]];

    TGLMappedTexture2D *result = [TGLMappedTexture2D createWithSize:_output_size withInternalFormat:GL_LUMINANCE withSmooth:YES];

    const uint32_t *edge_buf = [_tmp lockReadonly];
    uint8_t *out_buf = [result lockWritable];

    BENCHMARK("sdf gen") {
        for (int i = 0; i < _output_size.height; ++i) {
            for (int j = 0; j < _output_size.width; ++j) {
                *out_buf = __get_SDF_radial(edge_buf, _output_size.width, _output_size.height, j, i, 32);
                
                ++out_buf;
            }
        }
    }

    [_tmp unlockReadonly];
    
    [result unlockWritable];

    return result;
}

// Source Taken from:
//   Signed Distance Bitmap Font Tool
//   Jonathan lonesock Dummer
static uint8_t __get_SDF_radial(
		const uint32_t *img,
		int w, int h,
		int x, int y,
		int max_radius )
{
	//	hideous brute force method
	float d2 = max_radius*max_radius+1.0;
	uint32_t v = img[x+y*w];
	for( int radius = 1; (radius <= max_radius) && (radius*radius < d2); ++radius )
	{
		int line, lo, hi;
		//	north
		line = y - radius;
		if( (line >= 0) && (line < h) )
		{
			lo = x - radius;
			hi = x + radius;
			if( lo < 0 ) { lo = 0; }
			if( hi >= w ) { hi = w-1; }
			int idx = line * w + lo;
			for( int i = lo; i <= hi; ++i )
			{
				//	check this pixel
				if( img[idx] != v )
				{
					float nx = i - x;
					float ny = line - y;
					float nd2 = nx*nx+ny*ny;
					if( nd2 < d2 )
					{
						d2 = nd2;
					}
				}
				//	move on
				++idx;
			}
		}
		//	south
		line = y + radius;
		if( (line >= 0) && (line < h) )
		{
			lo = x - radius;
			hi = x + radius;
			if( lo < 0 ) { lo = 0; }
			if( hi >= w ) { hi = w-1; }
			int idx = line * w + lo;
			for( int i = lo; i <= hi; ++i )
			{
				//	check this pixel
				if( img[idx] != v )
				{
					float nx = i - x;
					float ny = line - y;
					float nd2 = nx*nx+ny*ny;
					if( nd2 < d2 )
					{
						d2 = nd2;
					}
				}
				//	move on
				++idx;
			}
		}
		//	west
		line = x - radius;
		if( (line >= 0) && (line < w) )
		{
			lo = y - radius + 1;
			hi = y + radius - 1;
			if( lo < 0 ) { lo = 0; }
			if( hi >= h ) { hi = h-1; }
			int idx = lo * w + line;
			for( int i = lo; i <= hi; ++i )
			{
				//	check this pixel
				if( img[idx] != v )
				{
					float nx = line - x;
					float ny = i - y;
					float nd2 = nx*nx+ny*ny;
					if( nd2 < d2 )
					{
						d2 = nd2;
					}
				}
				//	move on
				idx += w;
			}
		}
		//	east
		line = x + radius;
		if( (line >= 0) && (line < w) )
		{
			lo = y - radius + 1;
			hi = y + radius - 1;
			if( lo < 0 ) { lo = 0; }
			if( hi >= h ) { hi = h-1; }
			int idx = lo * w + line;
			for( int i = lo; i <= hi; ++i )
			{
				//	check this pixel
				if( img[idx] != v )
				{
					float nx = line - x;
					float ny = i - y;
					float nd2 = nx*nx+ny*ny;
					if( nd2 < d2 )
					{
						d2 = nd2;
					}
				}
				//	move on
				idx += w;
			}
		}
	}
	d2 = sqrtf( d2 );
	if( v==0 )
	{
		d2 = -d2;
	}
	d2 *= 127.5 / max_radius;
	d2 += 127.5;
	if( d2 < 0.0 ) d2 = 0.0;
	if( d2 > 255.0 ) d2 = 255.0;
	return (uint8_t)(d2 + 0.5);
}
@end

