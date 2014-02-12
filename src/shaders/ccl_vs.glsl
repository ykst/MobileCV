// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php
attribute vec4 position;

varying vec2 texture_coordinate;

uniform mediump mat3 mvp;

void main()
{
    vec2 p = (vec3(position.xy, 1) * mvp).xy;
    gl_Position = vec4(p, 0, 1);
    texture_coordinate = p / 2.0 + vec2(0.5, 0.5);
}

