//
//  SP_VectorLines.fsh
//  ld34
//
//  Created by Jeff Wofford on 12/11/15.
//  Copyright jeffwofford.com 2015. All rights reserved.
//
uniform sampler2D diffuseTexture;
uniform lowp vec4 color_multiply;

varying highp vec2 fragment_texCoord;
varying lowp vec4 fragment_color;

void main()
{
	gl_FragColor = fragment_color * color_multiply * texture2D( diffuseTexture, fragment_texCoord );
}
