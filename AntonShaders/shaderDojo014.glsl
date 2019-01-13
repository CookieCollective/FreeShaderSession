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

#define PI 3.14159

mat2 rot(float a)
{
  float ca = cos(a); float sa = sin(a);
  return mat2(ca,-sa,sa,ca);
}

float sdTor(vec3 p, vec2 tor)
{
  vec2 r = vec2(length(p.xz) - tor.x, p.y);
  
  return length(r) - tor.y;
}

float smin(float a, float b, float r)
{
  float k = clamp(.5 + .5 * (b- a) / r,0.,1.);

  return mix(b,a,k) - k * r * (1. - k);
}

float map(vec3 p)
{
  float dist = 1000.;

  float time = fGlobalTime * .5;

  p.zy *= rot(PI * .5);
  p.y += time * 4.;
  p.y = mod(p.y + 2.5,5.)-2.5;
  

  vec2 torDef = vec2(2.,.5);
  float axz = atan(p.x,p.z);
  torDef *= rot(time + p.y * 3. + axz  );
  torDef = abs(torDef) + .2;
  float shape = sdTor(p, torDef);

  dist = min(dist, shape);

  float cy = length(p.xz) - .75;

  dist = -smin(-dist,cy, .2);

  return dist;
}

float ray(inout vec3 cp, vec3 rd, float dist)
{
  dist = 0.;
  float st = 0.;
  for(; st < 1; st += 1./256.)
  {
    dist = map(cp);
    if(dist < .01) break;
    cp += rd * dist *.125;
  }
  return st;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 eye = vec3(0.,0.,-10.);
  vec3 rd = normalize(vec3(uv, 1.));
  vec3 cp = eye;

  float dist = 0.;
  float st = ray(cp, rd, dist);

  out_color = vec4(st);
}