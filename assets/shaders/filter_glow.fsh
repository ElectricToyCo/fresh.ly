//
//  filter_glow.fsh
//  FreshScene2D
//
//  Created by Jeff Wofford on 08/29/15.
//  Copyright jeffwofford.com 2015. All rights reserved.
//
uniform sampler2D diffuseTexture;
uniform lowp vec4 color_multiply;
uniform lowp vec4 glowColor;

varying highp vec2 fragment_texCoord;

void main()
{
	lowp vec4 color = color_multiply * texture2D( diffuseTexture, fragment_texCoord );

	gl_FragColor = color;
}
