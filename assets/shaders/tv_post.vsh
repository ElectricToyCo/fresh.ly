//
//  tv_post.vsh
//  Megadventure
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

uniform highp int milliseconds;

varying lowp vec2 fragment_texCoord;
varying lowp vec2 fragment_texCoord_noise;

void main()
{
	float time = float( milliseconds );
	
    gl_Position = vec4( position, 0.0, 1.0 );
	fragment_texCoord = texCoord;
	fragment_texCoord_noise = texCoord + fract( vec2( time / 107.0, time / 231.0 ));
}
