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

#define REP(p,r) (mod(p  + r /2., r) - r/2.)

float cid = 0.;

float map(vec3 p)
{
  float dist = 1000.;

  float rl = 3.;
  vec2 rid = floor((p.xy + rl /2.) / rl);
  p.xy = REP(p.xy, rl);

  cid = mod(rid.x, 2.) + mod(rid.y,2.);

  dist = min(dist, length(p) -1.);

  return dist;
}


vec3 normal(vec3 p)
{
  vec2 e = vec2(.01,.0);
  float d = map(p);
  return normalize(vec3(
    d - map(p + e.xyy),
    d - map(p + e.yxy),
    d - map(p + e.yyx)
  ));
}

vec3 lookAt(vec3 p, vec3 t, vec2 uv)
{
  vec3 fd = normalize(t - p);
  vec3 ri = cross(fd, vec3(0.,-1.,0.));
  vec3 up = cross(ri,fd);
  return normalize(fd + ri * uv.x + up * uv.y);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 eye = vec3(0.,10.,-10.);
  vec3 tar = vec3(0.,0.,0.);
  vec3 cp = eye;
  vec3 rd = lookAt(eye,tar,uv);
  float st = 0.;
  float cd = 0.;
  for(;st < 1.; st += 1./128.)
  {
    cd = map(cp);
    if(cd< .01) break;
    cp += cd * rd * .5;
  }

  vec4 col = vec4(1.,0.,0.,0.);
  if(cid > .5)
  {
    col = vec4(0.,1.,0.,0.);
  }
  if(cid > 1.5)
  {
    col = vec4(0.,0.,1.,0.);
  }

  vec3 norm = normal(cp);
  float spec = dot(normalize(tar - eye), norm);

  out_color = col * spec * (1. - st);
}