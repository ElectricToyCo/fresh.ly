//
//  SpriteBatch.fsh
//  Freshly
//
//  Created by Jeff Wofford on 5/28/10.
//  Copyright jeffwofford.com 2010. All rights reserved.
//
uniform sampler2D diffuseTexture;

varying highp vec2 fragment_screenPos;
varying highp vec2 fragment_texCoord;
varying highp vec4 fragment_color;
varying highp vec4 fragment_additiveColor;
varying highp mat4 fragment_ditherPattern;

float getDitherAlpha( vec2 pos )
{
	int x = int( mod( pos.x, 4.0 ));
	int y = int( mod( pos.y, 4.0 ));

	if( x == 0 ) 
	{
		if( y == 0 ) return fragment_ditherPattern[ 0 ][ 0 ];
		else if( y == 1 ) return fragment_ditherPattern[ 0 ][ 1 ];
		else if( y == 2 ) return fragment_ditherPattern[ 0 ][ 2 ];
		else if( y == 3 ) return fragment_ditherPattern[ 0 ][ 3 ];
	}
	else if( x == 1 )
	{
		if( y == 0 ) return fragment_ditherPattern[ 1 ][ 0 ];
		else if( y == 1 ) return fragment_ditherPattern[ 1 ][ 1 ];
		else if( y == 2 ) return fragment_ditherPattern[ 1 ][ 2 ];
		else if( y == 3 ) return fragment_ditherPattern[ 1 ][ 3 ];
	}
	else if( x == 2 )
	{
		if( y == 0 ) return fragment_ditherPattern[ 2 ][ 0 ];
		else if( y == 1 ) return fragment_ditherPattern[ 2 ][ 1 ];
		else if( y == 2 ) return fragment_ditherPattern[ 2 ][ 2 ];
		else if( y == 3 ) return fragment_ditherPattern[ 2 ][ 3 ];
	}
	else if( x == 3 )
	{
		if( y == 0 ) return fragment_ditherPattern[ 3 ][ 0 ];
		else if( y == 1 ) return fragment_ditherPattern[ 3 ][ 1 ];
		else if( y == 2 ) return fragment_ditherPattern[ 3 ][ 2 ];
		else if( y == 3 ) return fragment_ditherPattern[ 3 ][ 3 ];
	}
}

void main()
{
	float ditherAlpha = getDitherAlpha( fragment_screenPos );
	
	vec4 color = fragment_color * texture2D( diffuseTexture, fragment_texCoord );
	gl_FragColor = ditherAlpha * ( color + color.a * vec4( fragment_additiveColor.rgb, 0.0 ));
}
