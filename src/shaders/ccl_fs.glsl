// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php
uniform sampler2D image_tex;
uniform int mode;
varying highp vec2 texture_coordinate;

void main()
{
    if (mode == 0) {
        gl_FragColor = texture2D(image_tex, texture_coordinate);
    } else {
        gl_FragColor = vec4(1, 0, 0, 1);
    }
}

