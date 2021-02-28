//
//  whole_screen.vsh
//  ExperimentShading
//
//  Created by Jeff Wofford on 5/28/10.
//  Copyright jeffwofford.com 2010. All rights reserved.
//
#ifdef GL_ES
precision highp float;
precision mediump int;
#endif

attribute vec2 position;
attribute vec2 texCoord;

varying lowp vec2 v_texCoord;
varying lowp vec4 v_blurTexCoords[7];

void main()
{
    gl_Position = vec4( position, 0.0, 1.0 );
	v_texCoord = texCoord;
	
    v_blurTexCoords[ 0 ].xy = v_texCoord + vec2( -0.04375, 0.0);
    v_blurTexCoords[ 0 ].zw = v_texCoord + vec2( -0.0375, 0.0);
    v_blurTexCoords[ 1 ].xy = v_texCoord + vec2( -0.03125, 0.0);
    v_blurTexCoords[ 1 ].zw = v_texCoord + vec2( -0.025, 0.0);
    v_blurTexCoords[ 2 ].xy = v_texCoord + vec2( -0.01875, 0.0);
    v_blurTexCoords[ 2 ].zw = v_texCoord + vec2( -0.0125, 0.0);
    v_blurTexCoords[ 3 ].xy = v_texCoord + vec2( -0.00625, 0.0);
    v_blurTexCoords[ 3 ].zw = v_texCoord + vec2( 0.00625, 0.0);
    v_blurTexCoords[ 4 ].xy = v_texCoord + vec2( 0.0125, 0.0);
    v_blurTexCoords[ 4 ].zw = v_texCoord + vec2( 0.01875, 0.0);
    v_blurTexCoords[ 5 ].xy = v_texCoord + vec2( 0.025, 0.0);
    v_blurTexCoords[ 5 ].zw = v_texCoord + vec2( 0.03125, 0.0);
    v_blurTexCoords[ 6 ].xy = v_texCoord + vec2( 0.0375, 0.0);
    v_blurTexCoords[ 6 ].zw = v_texCoord + vec2( 0.04375, 0.0);
}
