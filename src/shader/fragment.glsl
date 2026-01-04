precision mediump float;

#include constants.glsl;

#include functions/gamma.glsl;
#include functions/pow.glsl;

#CONST_SCALE;
#CONST_FALLOFF;
#CONST_WIDTH;
#CONST_HEIGHT;

float rFalloff = 1.0 / falloff;

#FN_EQ1;
#FN_EQ2;
#FN_GRADIENT;

float calc(float x, float y) {
  return rFalloff * abs(equation1((x - (0.5 * width)) / width * scale, (y - (0.5 * height)) / width * scale) - equation2((x - (0.5 * width)) / width * scale, (y - (0.5 * height)) / width * scale));
}
void main() {
  float n = calc(gl_FragCoord.x, gl_FragCoord.y);
  gl_FragColor = gradient(n);
}