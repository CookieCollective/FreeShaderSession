#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texChecker;
uniform sampler2D texNoise;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

mat2 rot(float a)
{
  float ca = cos(a); float sa = sin(a);
  return mat2(sa,-ca,ca,sa);
}

float join(float d1, float d2, float k)
{
  float h = clamp(.5 + .5 *(d2 - d1) / k,0.,1.);
  return mix(d1,d2,h) * k * h;
}

float map(vec3 p)
{
  vec3 cp = p;
  float dist = 1000.;

  p.y += 10.;
  p.xy *= rot(p.z * .05);
  p.y -= 10.;

  p.xy *= rot(p.z* .5);

  float cyl = length(p.xy + .25) - .5;

  dist = min(dist, cyl);
  cyl = length(p.xy - .25) - .5;
  dist = min(dist, cyl);


  return dist;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 eye = vec3(0.,0.,-10.);
  vec3 rd = normalize(vec3(uv, 1.));
  vec3 cp = eye;
  float st = 0.; float cd = 0.;
  for(;st < 1.; st += 1./128.)
  {
    cd = map(cp);
    if(cd < .01)
    break;
    cp += cd * rd * .5;

  }

  out_color = vec4(1. - st);
}