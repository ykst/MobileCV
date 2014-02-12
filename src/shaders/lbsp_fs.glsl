// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php
#version 100

uniform sampler2D luminanceTexture;

varying highp vec2 left_tc;
varying highp vec2 left_top_tc;
varying highp vec2 left_bottom_tc;
varying highp vec2 center_tc;
varying highp vec2 center_top_tc;
varying highp vec2 center_bottom_tc;
varying highp vec2 right_top_tc;
varying highp vec2 right_tc;
varying highp vec2 right_bottom_tc;


// poorman's bit count and xor operator.. GLSL1.0 so sucks
mediump float bit_xor_count(in mediump float x, in mediump float y)
{
    lowp float x1 = mod(x, 2.0);
    x = floor(x / 2.0);
    lowp float x2 = mod(x, 2.0);
    x = floor(x / 2.0);
    lowp float x3 = mod(x, 2.0);
    x = floor(x / 2.0);
    lowp float x4 = mod(x, 2.0);
    x = floor(x / 2.0);
    lowp float x5 = mod(x, 2.0);
    x = floor(x / 2.0);
    lowp float x6 = mod(x, 2.0);
    x = floor(x / 2.0);
    lowp float x7 = mod(x, 2.0);
    x = floor(x / 2.0);
    lowp float x8 = mod(x, 2.0);

    lowp float y1 = mod(y, 2.0);
    y = floor(y / 2.0);
    lowp float y2 = mod(y, 2.0);
    y = floor(y / 2.0);
    lowp float y3 = mod(y, 2.0);
    y = floor(y / 2.0);
    lowp float y4 = mod(y, 2.0);
    y = floor(y / 2.0);
    lowp float y5 = mod(y, 2.0);
    y = floor(y / 2.0);
    lowp float y6 = mod(y, 2.0);
    y = floor(y / 2.0);
    lowp float y7 = mod(y, 2.0);
    y = floor(y / 2.0);
    lowp float y8 = mod(y, 2.0);

    return float(y1 == x1) +
           float(y2 == x2) +
           float(y3 == x3) +
           float(y4 == x4) +
           float(y5 == x5) +
           float(y6 == x6) +
           float(y7 == x7) +
           float(y8 == x8);
}

void main()
{
    mediump float left = texture2D(luminanceTexture, left_tc).r;
    mediump float left_top = texture2D(luminanceTexture, left_top_tc).r;
    mediump float left_bottom = texture2D(luminanceTexture, left_bottom_tc).r;

    mediump float center = texture2D(luminanceTexture, center_tc).r;
    mediump float center_top = texture2D(luminanceTexture, center_top_tc).r;
    mediump float center_bottom = texture2D(luminanceTexture, center_bottom_tc).r;

    mediump float right = texture2D(luminanceTexture, right_tc).r;
    mediump float right_top = texture2D(luminanceTexture, right_top_tc).r;
    mediump float right_bottom = texture2D(luminanceTexture, right_bottom_tc).r;

    mediump float b_left_top = left_top * 255.0;
    mediump float b_left = left * 255.0;
    mediump float b_left_bottom = left_bottom * 255.0;

    mediump float b_center_top = center_top * 255.0;
    mediump float b_center = center* 255.0;
    mediump float b_center_bottom = center_bottom * 255.0;

    mediump float b_right_top = right_top * 255.0;
    mediump float b_right = right* 255.0;
    mediump float b_right_bottom = right_bottom * 255.0;

    mediump float min_dist = 8.0;
    // min_dist = min(min_dist, bit_xor_count(b_left_top, center));
    min_dist = min(min_dist, bit_xor_count(b_center_top, center));
    //min_dist = min(min_dist, bit_xor_count(b_right_top, center));
    min_dist = min(min_dist, bit_xor_count(b_left, center));
    min_dist = min(min_dist, bit_xor_count(b_right, center));
    //  min_dist = min(min_dist, bit_xor_count(b_left_bottom, center));
    min_dist = min(min_dist, bit_xor_count(b_center_bottom, center));
    //min_dist = min(min_dist, bit_xor_count(b_right_bottom, center));
    mediump float sum_dist =  bit_xor_count(b_center_top, center) + bit_xor_count(b_left, center) + bit_xor_count(b_right, center) + bit_xor_count(b_center_bottom, center);
    lowp float val = float(min_dist <= 2.0 && sum_dist > 15.0);

    gl_FragColor = vec4(val, val, val, 1.0);
}

