//
//  SP_VectorLines.vsh
//  ld34
//
//  Created by Jeff Wofford on 12/11/15.
//  Copyright jeffwofford.com 2015. All rights reserved.
//

uniform highp mat4 projectionMatrix;
uniform highp mat4 modelViewMatrix;
uniform mat4 textureMatrix;

attribute highp vec2 position;
attribute highp vec2 texCoord;
attribute lowp vec4 color;

varying highp vec2 fragment_texCoord;
varying lowp vec4 fragment_color;

void main()
{
    gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 0.0, 1.0 );
	fragment_texCoord = ( textureMatrix * vec4( texCoord, 0.0, 1.0 )).st;
	fragment_color = color;
}
