// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php
precision lowp float;
uniform sampler2D luminanceTexture;

varying highp vec2 left_tc;
varying highp vec2 left_top_tc;
varying highp vec2 left_bottom_tc;
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

    mediump float center_top = texture2D(luminanceTexture, center_top_tc).r;
    mediump float center_bottom = texture2D(luminanceTexture, center_bottom_tc).r;
    mediump float right = texture2D(luminanceTexture, right_tc).r;
    mediump float right_top = texture2D(luminanceTexture, right_top_tc).r;
    mediump float right_bottom = texture2D(luminanceTexture, right_bottom_tc).r;

    lowp float xgrad = abs(left - right);
    lowp float ygrad = abs(center_top - center_bottom);
    lowp float d1grad = abs(left_top - right_bottom);
    lowp float d2grad = abs(left_bottom - right_top);
    //lowp float factor = step(0.0, xgrad + d1grad + d2grad - 3.0 * ygrad);
    //lowp float factor = step(0.0, d1grad + d2grad - ygrad - xgrad);
    //lowp float factor = 1.0 - step(0.0, 3.0 * ygrad - xgrad - d1grad - d2grad) * step(0.0, 3.0 * xgrad - ygrad - d1grad - d2grad);
    //lowp float factor = step(0.0, xgrad + ygrad - d1grad - d2grad);
    lowp float is_feature = step(0.05, xgrad) * step(0.05, ygrad);
    ;//step(1.0, step(0.05, xgrad) + step(0.05, ygrad));
    lowp float weight = 0.0 + step(0.3, xgrad) + step(0.3, ygrad) + step(0.3, d1grad) + step(0.3, d2grad);
    //lowp float weight = 0.0 + step(0.3, d1grad) + step(0.3, d2grad);
    //lowp float weight = 0.0 + d1grad *d1grad + d2grad*d2grad;
    gl_FragColor = vec4(vec3(is_feature), 1.0);
}

