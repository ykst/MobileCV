// Copyright (c) 2014 Yohsuke Yukishita
// This software is released under the MIT License: http://opensource.org/licenses/mit-license.php
#extension GL_EXT_shader_framebuffer_fetch : require
precision mediump int;
varying highp vec2 textureCoord;
varying mediump float clusterId;
varying mediump vec2 centroid;

uniform sampler2D locationTexture;
uniform sampler2D classifiedTexture;
uniform sampler2D accumulationTexture;

uniform mediump float clearValue;
uniform mediump int mode;
uniform highp float threshold;

mediump vec2 pack_float(const in highp float val)
{
    mediump float sub = fract(val * 256.0);
    return vec2(sub, fract(val) - sub/256.0);
}

highp float unpack_float(const in mediump vec2 v)
{
    return v.y + v.x / 256.0;
}

void calc_distances()
{
    mediump vec2 location = texture2D(locationTexture, textureCoord).xy;

    highp float d = distance(centroid.xy, location.xy);
    highp float prev_di = gl_LastFragData[0].w;
    highp float min_di = min(d, prev_di);
    lowp float clusterIdToSave = d < prev_di ? clusterId : gl_LastFragData[0].z;
    gl_FragColor = vec4(location.x, location.y, clusterIdToSave, min_di);
}

void accumlate_coord()
{
    mediump vec4 location = texture2D(locationTexture, textureCoord);
    gl_FragColor = gl_LastFragData[0] + location;
}

void filter_power_coord()
{
    mediump vec4 location = texture2D(classifiedTexture, textureCoord);
    highp float d2 = location.w * location.w;
    highp float accum = gl_LastFragData[0].w;

    gl_FragColor = vec4(accum <= threshold * texture2D(accumulationTexture, vec2(0.5,0.5)).w ? location.xy : gl_LastFragData[0].xy, 0, accum + d2);
}

void accumlate_power_coord()
{
    mediump vec4 location = texture2D(classifiedTexture, textureCoord);
    highp float d2 = location.w * location.w;

    gl_FragColor = vec4(0, 0, 0, gl_LastFragData[0].w + d2);
}

void reset_fbo()
{
    gl_FragColor = vec4(0, 0, gl_LastFragData[0].z, clearValue);
}

void divide_coord()
{
    gl_FragColor = gl_LastFragData[0] / gl_LastFragData[0].w;
}

void main()
{
    if (mode == 1) {
        calc_distances();
    } else if (mode == 2) {
        accumlate_coord();
    } else if (mode == 3) {
        divide_coord();
    } else if (mode == 4) {
        accumlate_power_coord();
    } else if (mode == 5) {
        filter_power_coord();
    } else {
        reset_fbo();
    }
}

