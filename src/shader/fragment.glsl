precision mediump float;

uniform float viewportScale;
uniform float viewportX;
uniform float viewportY;
uniform float width;
uniform float height;
uniform float falloff;

#include constants.glsl;

#include functions/gamma.glsl;
#include functions/pow.glsl;

float rFalloff = 1.0 / falloff;

#FN_EQ1;
#FN_EQ2;
#FN_GRADIENT;

float calc(float x, float y) {
  float valX = (x - (0.5 * width)) / width * viewportScale + viewportX;
  float valY = (y - (0.5 * height)) / height * viewportScale + viewportY;
  return rFalloff * abs(equation1(valX, valY) - equation2(valX, valY));
}
void main() {
  gl_FragColor = gradient(calc(gl_FragCoord.x, gl_FragCoord.y));
}