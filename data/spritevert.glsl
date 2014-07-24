#define PROCESSING_POINT_SHADER

uniform mat4 projection;
uniform mat4 modelview;
uniform mat4 transform;

uniform float weight;
 
attribute vec4 vertex;
attribute vec4 color;
attribute vec2 offset;

varying vec4 vertColor;
varying vec2 texCoord;
varying vec2 center;
varying vec2 pos;

void main() {
  vec4 pose = modelview * vertex;
  vec4 clip = projection * pose;
  
  gl_Position = clip + projection * vec4(offset, 0, 0);
  texCoord = (vec2(0.5) + offset / weight);

  center = clip.xy;
  pos = offset;
  vertColor = color;
}

