float c_gamma_pos(float z) {
  const float g = 7.0;
  const float p0 = 0.99999999999980993;
  const float p1 = 676.5203681218851;
  const float p2 = -1259.1392167224028;
  const float p3 = 771.32342877765313;
  const float p4 = -176.61502916214059;
  const float p5 = 12.507343278686905;
  const float p6 = -0.13857109526572012;
  const float p7 = 9.9843695780195716e-6;
  const float p8 = 1.5056327351493116e-7;

  z -= 1.0;
  float x = p0;
  x += p1 / (z + 1.0);
  x += p2 / (z + 2.0);
  x += p3 / (z + 3.0);
  x += p4 / (z + 4.0);
  x += p5 / (z + 5.0);
  x += p6 / (z + 6.0);
  x += p7 / (z + 7.0);
  x += p8 / (z + 8.0);

  float t = z + g + 0.5;
  return sqrt(2.0 * PI) * pow(t, z + 0.5) * exp(-t) * x;
}

float c_gamma(float z) {
  if(z < 0.5) {
    return PI /
      (sin(PI * z) * c_gamma_pos(1.0 - z));
  }
  return c_gamma_pos(z);
}