//
//  SpriteBatch.vsh
//  Freshly
//
//  Created by Jeff Wofford on 5/28/10.
//  Copyright jeffwofford.com 2010. All rights reserved.
//

uniform highp mat4 projectionMatrix;
uniform highp mat4 modelViewMatrix;
uniform mat4 textureMatrix;

attribute highp vec2 position;
attribute highp vec2 texCoord;
attribute highp vec4 color;
attribute highp vec4 additiveColor;
attribute highp mat4 ditherPattern;

varying highp vec2 fragment_screenPos;
varying highp vec2 fragment_texCoord;
varying highp vec4 fragment_color;
varying highp vec4 fragment_additiveColor;
varying highp mat4 fragment_ditherPattern;

void main()
{
	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 0.0, 1.0 );
	fragment_screenPos = position;
	fragment_texCoord = ( textureMatrix * vec4( texCoord, 0.0, 1.0 )).st;
	fragment_color = color;
	fragment_additiveColor = additiveColor;
	fragment_ditherPattern = ditherPattern;
}
