//
//  vertical_blur.fsh
//  Megadventure
//
//  Created by Jeff Wofford on 2013/11/20.
//  Copyright jeffwofford.com 2013. All rights reserved.
//
#ifdef GL_ES
precision highp float;
precision mediump int;
#endif

uniform sampler2D blurTexture;

varying lowp vec2 v_texCoord;
varying lowp vec4 v_blurTexCoords[7];

void main()
{
    vec4 diffuse = texture2D( blurTexture, v_blurTexCoords[ 0 ].xy ) * 0.0044299121055113265;
    diffuse += texture2D( blurTexture, v_blurTexCoords[ 0 ].zw ) * 0.00895781211794;
    diffuse += texture2D( blurTexture, v_blurTexCoords[ 1 ].xy ) * 0.0215963866053;
    diffuse += texture2D( blurTexture, v_blurTexCoords[ 1 ].zw ) * 0.0443683338718;
    diffuse += texture2D( blurTexture, v_blurTexCoords[ 2 ].xy ) * 0.0776744219933;
    diffuse += texture2D( blurTexture, v_blurTexCoords[ 2 ].zw ) * 0.115876621105;
    diffuse += texture2D( blurTexture, v_blurTexCoords[ 3 ].xy ) * 0.147308056121;
    diffuse += texture2D( blurTexture, v_texCoord ) * 0.159576912161;
    diffuse += texture2D( blurTexture, v_blurTexCoords[ 3 ].zw ) * 0.147308056121;
    diffuse += texture2D( blurTexture, v_blurTexCoords[ 4 ].xy ) * 0.115876621105;
    diffuse += texture2D( blurTexture, v_blurTexCoords[ 4 ].zw ) * 0.0776744219933;
    diffuse += texture2D( blurTexture, v_blurTexCoords[ 5 ].xy ) * 0.0443683338718;
    diffuse += texture2D( blurTexture, v_blurTexCoords[ 5 ].zw ) * 0.0215963866053;
    diffuse += texture2D( blurTexture, v_blurTexCoords[ 6 ].xy ) * 0.00895781211794;
    diffuse += texture2D( blurTexture, v_blurTexCoords[ 6 ].zw ) * 0.0044299121055113265;
	
	gl_FragColor = diffuse;
}