// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php
attribute vec4 position;
attribute vec4 input_texture_coordinate;

varying vec2 texture_coordinate;

void main()
{
    gl_Position = position;
    texture_coordinate = input_texture_coordinate.xy;
}

