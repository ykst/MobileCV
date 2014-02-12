// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php
precision mediump int;
attribute vec4 position;

varying vec2 textureCoord;
varying float clusterId;
varying vec2 centroid;

uniform sampler2D locationTexture;
uniform sampler2D classifiedTexture;
uniform sampler2D centroidTexture;
uniform mediump float inputClusterId;

uniform mediump int mode;
uniform highp float classStep;

void main()
{
    highp vec2 coord = vec2((position.x + 1.0) / 2.0, 0.5);
    textureCoord = coord;
    if (mode == 2) {
        mediump vec4 classified = texture2D(classifiedTexture, coord);
        gl_Position = vec4(classified.z * classStep + classStep / 2.0 - 1.0, 0.0, 1, 1);
        gl_PointSize = 1.0;
        clusterId = 0.0; // no use
        centroid = vec2(0.0,0.0); // no use
    } else if (mode == 4) {
        gl_Position = vec4(0, 0, 1, 1);
        gl_PointSize = 1.0;
    } else if (mode == 5) {
        gl_Position = vec4(inputClusterId * classStep + classStep / 2.0 - 1.0, 0.0, 1, 1);
        gl_PointSize = 1.0;
    } else {
        gl_Position = vec4(position.x, 0.0, 1, 1);
        clusterId = position.y;
        highp vec2 centroidCoord = vec2((position.y * classStep) / 2.0 + classStep / 4.0, 0.5);
        centroid = texture2D(centroidTexture, centroidCoord).xy;
    }

}

