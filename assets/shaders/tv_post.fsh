//
//  tv_post.fsh
//  Megadventure
//
//  Created by Jeff Wofford on 2013/11/20.
//  Copyright jeffwofford.com 2013. All rights reserved.
//
#ifdef GL_ES
precision highp float;
precision mediump int;
#endif

uniform sampler2D priorPass;
uniform sampler2D noiseTexture;
uniform sampler2D retainedTexture;
uniform float noiseIntensity;
uniform float burnIn;
uniform highp int milliseconds;
uniform vec4 rescanColor;
uniform float saturation;
uniform vec4 colorMultiplied;

varying lowp vec2 fragment_texCoord;
varying vec2 fragment_texCoord_noise;

#define PI 3.141592653589

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec4 tonemap( vec4 color )
{
	vec3 hsv = rgb2hsv( color.rgb );
	hsv.y *= saturation;
	return vec4( hsv2rgb( hsv ), color.a );
}

#define EDGE_SIZE 0.004

void main()
{
	float time = float( milliseconds );
	
	vec4 prior = texture2D( priorPass, fragment_texCoord );
	vec4 noise = texture2D( noiseTexture, fragment_texCoord_noise );
	
	float rescanLine = fract( time / 4000.0 );
	vec4 rescan = mix( vec4(0), rescanColor, fract( fragment_texCoord.t - rescanLine ));

	vec4 burnedIn = texture2D( retainedTexture, fragment_texCoord );

	// Edge blackening.
	highp vec4 xyxy = vec4( fragment_texCoord, fragment_texCoord );
	
	highp vec4 edgeDists = vec4( xyxy.xy - vec2( EDGE_SIZE ), vec2( 1.0 - EDGE_SIZE ) - xyxy.zw );
	edgeDists /= EDGE_SIZE;
	float edgeFade = clamp( min( min( edgeDists.x, edgeDists.y ), min( edgeDists.z, edgeDists.w )), 0.0, 1.0 );
	
	gl_FragColor = ( tonemap( mix( prior * colorMultiplied, noise + rescan, noiseIntensity ) + ( burnedIn * burnIn ))
					* vec4( edgeFade, edgeFade, edgeFade, 1.0 )
					);
}
