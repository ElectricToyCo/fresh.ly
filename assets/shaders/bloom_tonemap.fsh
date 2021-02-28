//
//  bloom_tonemap.fsh
//  Fresh
//
//  Created by Jeff Wofford on 2013/11/20.
//  Copyright jeffwofford.com 2013. All rights reserved.
//
#ifdef GL_ES
precision highp float;
precision mediump int;
#endif

uniform sampler2D diffuseTexture;

uniform float bloomBrightness;
uniform float bloomContrast;

varying vec2 fragment_texCoord;

vec4 tonemap( vec4 color )
{
	float brightness = dot( color.rgb, vec3(0.2125, 0.7154, 0.0721));
    float reranged = max(( brightness - 0.5 ) * 2.0 + bloomBrightness, 0.0 );
    float contrasted = pow( reranged, bloomContrast );
    
    return color * contrasted;
}

void main()
{
	gl_FragColor = tonemap( texture2D( diffuseTexture, fragment_texCoord ));
}
