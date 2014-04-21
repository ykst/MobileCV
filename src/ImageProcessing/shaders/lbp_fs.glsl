// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php
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

    // Improved LBP
    center = (center + center_top + center_bottom
           + right + right_top + right_bottom
           + left + left_top + left_bottom) / 9.0;

    int lbp = (int(center < left_top) * 128)
            + (int(center < center_top) * 64)
            + (int(center < right_top) * 32)
            + (int(center < right) * 16)
            + (int(center < right_bottom) * 8)
            + (int(center < center_bottom) * 4)
            + (int(center < left_bottom) * 2)
            + (int(center < left));

    /*
    int lbp = (int(center < left) * 128)
            + (int(center < center_top) * 64)
            + (int(center < right) * 32)
    + (int(center < center_bottom) * 16);
    //+ (int(center < right_bottom) * 8)
    //      + (int(center < left_bottom) * 2)
    //      + (int(center < right_top) * 4)
    //      + (int(center < left_top));
*/
    lowp float val = float(lbp)/255.0;
    gl_FragColor = vec4(val, val, val, 1.0);
}

