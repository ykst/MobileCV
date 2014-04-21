// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php
attribute vec4 position;
attribute vec4 input_texture_coordinate;

uniform highp vec2 window;

varying vec2 left_top_tc;
varying vec2 left_bottom_tc;
varying vec2 right_top_tc;
varying vec2 right_bottom_tc;
varying vec2 center_tc;

void main()
{
    highp float hx = window.x / 2.0;
    highp float hy = window.y / 2.0;

    left_top_tc = input_texture_coordinate.xy + vec2(-hx, -hy);
    left_bottom_tc = input_texture_coordinate.xy + vec2(-hx, hy);

    right_top_tc = input_texture_coordinate.xy + vec2(hx, -hy);
    right_bottom_tc = input_texture_coordinate.xy + vec2(hx, hy);

    center_tc = input_texture_coordinate.xy;

    gl_Position = position;
}

