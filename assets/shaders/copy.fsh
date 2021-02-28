//
//  copy.fsh
//  Megadventure
//
//  Created by Jeff Wofford on 2013/11/20.
//  Copyright jeffwofford.com 2013. All rights reserved.
//
#ifdef GL_ES
precision highp float;
precision mediump int;
#endif

uniform sampler2D diffuseTexture;

varying lowp vec2 fragment_texCoord;

void main()
{
	gl_FragColor = texture2D( diffuseTexture, fragment_texCoord );
}