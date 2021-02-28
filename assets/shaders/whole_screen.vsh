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

varying lowp vec2 fragment_texCoord;

void main()
{
    gl_Position = vec4( position, 0.0, 1.0 );
	fragment_texCoord = texCoord;
}
