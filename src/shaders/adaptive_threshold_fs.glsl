// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php
precision highp int;
precision highp float;
uniform sampler2D luminance_texture;
uniform sampler2D integral_texture;

uniform highp float area;

varying highp vec2 left_top_tc;
varying highp vec2 left_bottom_tc;
varying highp vec2 right_top_tc;
varying highp vec2 right_bottom_tc;
varying highp vec2 center_tc;

highp float unpack_32_le(highp vec4 v)
{
    // TODO: lack of precision may be disasterous here
    //return float(int(v.w * 255.0) * 256 * 256 * 256 + int(v.z * 255.0) * 256 * 256 + int(v.y * 255.0) * 256 + int(v.x * 255.0)) / float(256*256*256*255);
    return v.x;
}
void main()
{
    highp float intensity = texture2D(luminance_texture, center_tc).x * area * 1020.0;
    highp float integral =
        (texture2D(integral_texture, right_bottom_tc).x) +
        (texture2D(integral_texture, left_top_tc).x) -
        (texture2D(integral_texture, right_top_tc).x) -
        (texture2D(integral_texture, left_bottom_tc).x);

    lowp float val = float(intensity > integral);
    //gl_FragColor = vec4(unpack_32_le(vec4(0.5,0.5,0.5,0.5)),0,0,1);
    //gl_FragColor = vec4(integral, integral, integral, 1.0);
    gl_FragColor = vec4(val, val, val, 1.0);
}

