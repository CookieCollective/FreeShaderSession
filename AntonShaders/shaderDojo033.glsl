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

float sdSphere(vec3 p)
{
  return length(p) - 1.;
}

float sdCube(vec3 p)
{
  p = abs(p);

  return max(p.x,max(p.y,p.z)) - 1.;
}

mat2 rot(float a)
{
  float ca = cos(a); float sa = sin(a);

  return mat2(ca, -sa, sa, ca);
}

#define iTime (fGlobalTime)

vec3 noise33(vec3 p)
{
  return fract(vec3(sin(p.x * 53.664) * 766., sin(p.y * 254.21) * 753., sin(p.z *45.12) * 452.));
}

float snoise31(vec3 p)
{
  return sin(p.x * 23.315 + 415.) * sin(p.y * 54.3 + 783.) * sin(p.z * 445.415 - 45212.) * .5 + .5;
}

float map(vec3 p)
{
  vec3 cp = p;

  p.xy *= rot(iTime * .1);
  p.xz *= rot(iTime * .01);
  p.zy *= rot(iTime * .05);

  float sph = sdSphere(p);
  float cube = sdCube(p);

  float dist = mix(sph, cube, sin(fGlobalTime) * .5 + .5);

  p = cp;

  float plane = p.y + 3.;

  dist = min(dist, plane);

  p = cp;

  float cyl = length(p.xy) - 5. + sin(p.z - iTime);

  dist = min(dist, -cyl);

  return dist;
}

void ray(inout vec3 cp, in vec3 rd, out float st, out float cd)
{
  st = 0.;
  cd = 0.;
  float len = 0.;
  for(;st < 1.; st += 1. / 128.)
  {
    cd = map(cp);
    if(cd < .01)
    {
      break;
    }

    vec3 noi = noise33(cp) * (exp(1.-len * 1.)) * .1;
    rd.yz *= rot(noi.x);
    rd.xz *= rot(noi.y);
    rd.xy *= rot(noi.z);
    
    len += cd;
    cp += rd * cd ;
  }
}

vec3 normal(vec3 p, float cd)
{
  vec2 e = vec2(.01,.0);
  return normalize(
  vec3(
  cd - map(p + e.xyy),
  cd - map(p + e.yxy),
  cd - map(p + e.yyx)
  )
);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.,0.,-10.);
  vec3 rd = normalize(vec3(uv, 1.));
  vec3 cp = ro;
  float cd,st;

  ray(cp,rd,st,cd);

  out_color = vec4(0.);

  if(cd < .01)
  {
    float len = length(cp - ro);
    float fog = exp(-len * .1);
    vec3 norm = normal(cp, cd);

    float li = dot(vec3(1.,-1.,1.), norm);

    out_color = vec4(li) * fog;
  }

}