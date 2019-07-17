#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D cookie;
uniform sampler2D descartes;
uniform sampler2D texNoise;
uniform sampler2D texTex2;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

#define time fGlobalTime

mat2 rot(float a) {
  float c =cos(a), s=sin(a);
  return mat2(c,s,-s,c);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  uv.y=-uv.y;

  uv.x += tan(time*.5)*.2+sin(time*.12)*.05+sin(uv.y*10.+time*.2)*.1;
  uv /= cos(time*.3);
  uv *= rot(sin(time*.2)*3.);
  vec4 c = texture(cookie, uv);
  
  out_color = c;
}