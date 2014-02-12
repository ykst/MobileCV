// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php
uniform sampler2D luminance_texture;

varying highp vec2 texture_coordinate;

void main()
{
    lowp float nucleous = texture2D(luminance_texture, texture_coordinate).x;
    int cnt = 0;
    for(int i = 0; i < 5; ++i) {
        mediump float step_y = float(2 * (i - 2) + 1)/960.0;
        for (int j = 0; j < 5; ++j) {
            mediump float step_x = float(2 * (j - 2) + 1)/1280.0;

            lowp float luminance = texture2D(luminance_texture, texture_coordinate + vec2(step_x, step_y)).x;

            cnt += int(abs(luminance - nucleous) < 0.05);
        }
    }
    lowp float val = float(cnt <= 21); // black foreground
    gl_FragColor = vec4(val, val, val, 1.0);
}

