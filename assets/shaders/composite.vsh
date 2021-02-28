//
//  composite.vsh
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
varying lowp vec2 fragment_texCoord_red;
varying lowp vec2 fragment_texCoord_blue;
varying lowp vec2 fragment_texCoord_pixel_bevel;

uniform float chromaticAberration;
uniform highp vec2 diffuseTextureSize;

void main()
{
	vec2 texelSize = 1.0 / diffuseTextureSize;

    gl_Position = vec4( position, 0.0, 1.0 );
	fragment_texCoord = texCoord;
	fragment_texCoord_red = texCoord + vec2( texelSize.x * chromaticAberration, 0 );
	fragment_texCoord_blue = texCoord + vec2( texelSize.x * -chromaticAberration, 0 );
	fragment_texCoord_pixel_bevel = texCoord * diffuseTextureSize;
}
