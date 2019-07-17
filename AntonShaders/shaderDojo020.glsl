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

#define REP(p, r) (mod(p + r /2., r) - r/2.)

mat2 rot(float a)
{
  float ca = cos(a); float sa = sin(a);
  return mat2(ca,-sa,sa,ca);
}

float map(vec3 p)
{
  float dist = 1000.;
  vec3 cp = p;

  p.z += fGlobalTime;
  
  p.xy *= rot(p.z * .05);
  p.xzy = REP(p.xzy, 4.);



  p.x -= 1.5;


  dist = min(dist, length(p) - 1.);


  return dist;
}

vec3 normal(vec3 p)
{
  vec2 e = vec2(.01,0.);
  float d = map(p);
  return normalize(vec3(
  d - map(p + e.xyy),
  d - map(p + e.yxy),
  d - map(p + e.yyx)
));
}

void ray(inout vec3 cp, in vec3 rd, inout float cd, out float dist)
{
  float st = 0.;
  cd = 0.;
  dist = 0.;
  for(;st < 1.; st += 1. / 128.)
  {
    cd = map(cp);
    if(cd < .01) break;
    cp += rd * cd * .5;
    dist += cd * .5;
  }
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.,0.,-10.);
  vec3 rd = normalize(vec3(uv,1.));
  vec3 cp = ro;

  float st = 0.;
  float cd = 0.;

  float dist;

  ray(cp,rd,cd, dist);
  
  if((cd <.01))
  {
    vec3 norm = normal(cp);

    vec3 lightPos = vec3(0.,5.,-5.);
    vec3 lightDir = normalize(cp - lightPos);
    float li = dot(norm,lightDir);

    vec4 gCol = vec4(.6,.2,.7,0.);

    out_color = gCol * li;
  
    vec3 nrd = reflect(rd, norm);
    cp += nrd * .1;
    ray(cp, nrd, cd, dist);

    if(cd < .01)
    {
        norm = normal(cp);
        li = dot(norm, lightDir);
        out_color = vec4(.6,.2,.7,0.) * li ;
    }


    out_color *= 2.;
  }
}