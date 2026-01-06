precision mediump float;

#include constants.glsl;

#include functions/gamma.glsl;
#include functions/pow.glsl;

#CONST_VIEWPORT_SCALE;
#CONST_VIEWPORT_X;
#CONST_VIEWPORT_Y;
#CONST_FALLOFF;
#CONST_WIDTH;
#CONST_HEIGHT;

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