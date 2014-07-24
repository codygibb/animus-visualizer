#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform float weight;
uniform float sharpness;

varying vec4 vertColor;
varying vec2 center;
varying vec2 pos;

void main() {  
  float len = weight/2.0 - length(pos);
  vec4 color = vec4(1.0, 1.0, 1.0, len);
  color = mix(vec4(0.0), color, sharpness);		  
  color = clamp(color, 0.0, 1.0);		
  gl_FragColor = color * vertColor; 
}