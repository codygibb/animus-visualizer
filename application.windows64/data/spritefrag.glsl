#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform sampler2D sprite;
uniform float sharpness;
uniform float weight;

varying vec4 vertColor;
varying vec2 texCoord;
varying vec2 center;
varying vec2 pos;

void main() {  
	float len = weight / 2.0 - length(pos);
	vec4 color = vec4(1.0, 1.0, 1.0, len);
	color = mix(vec4(0.0), color, sharpness);
	color = clamp(color, 0.0, 1.0);
	gl_FragColor = texture2D(sprite, texCoord) * vertColor * color;

}