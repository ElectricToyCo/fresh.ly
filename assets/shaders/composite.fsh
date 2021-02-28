//
//  composite.fsh
//  Fresh
//
//  Created by Jeff Wofford on 2015/08/21.
//  Copyright jeffwofford.com 2015. All rights reserved.
//
#ifdef GL_ES
precision highp float;
precision mediump int;
#endif

uniform sampler2D originalTexture;
uniform sampler2D blurTexture;
uniform sampler2D pixelBevelTexture;
uniform float bloomIntensity;
uniform float bevelIntensity;

varying lowp vec2 fragment_texCoord;
varying lowp vec2 fragment_texCoord_red;
varying lowp vec2 fragment_texCoord_blue;
varying highp vec2 fragment_texCoord_pixel_bevel;

void main()
{
    // Grab each color component separately, the texcoords having been shifted
    // for color aberration in the vertex shader.
    //
    vec4 red = vec4( texture2D( originalTexture, fragment_texCoord_red.st ).r, 0.0, 0.0, 1.0 );
    vec4 green = vec4( 0.0, texture2D( originalTexture, fragment_texCoord.st ).g, 0.0, 1.0 );
    vec4 blue = vec4( 0.0, 0.0, texture2D( originalTexture, fragment_texCoord_blue.st ).b, 1.0 );
    
    // Recombine into the color for the diffuse.
    //
    vec4 diffuse = red + green + blue;
    
    vec4 bloom = texture2D( blurTexture, fragment_texCoord.st );	    
    vec4 bevel = texture2D( pixelBevelTexture, fragment_texCoord_pixel_bevel.st );    

    diffuse = mix( diffuse, diffuse * bevel, bevelIntensity );

	gl_FragColor = diffuse + bloom * bloomIntensity;
}