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

vec2 modA(vec2 p, float c)
{
  float a = atan(p.y,p.x);
  a = mod(a , c);

  return vec2(cos(a),sin(a)) * length(p);
}

float smin(float a, float b, float k)
{
  float h = clamp(.5 + .5 * (b -a)/k,0.,1.);
  return mix(b,a,h) - k * h *(1. - h);
}

mat2 rot(float a)
{
  float sa = sin(a);  float ca  = cos(a);
  return mat2(ca,-sa,sa,ca);
}

#define time (fGlobalTime)

float map(vec3 p, out float id)
{
  id = 0.;
  float dist  = 10000.;
  vec3 cp = p;
  
  p.yz = modA(p.yz, 4.);
  p.yz *= rot(p.x * .5 + time);
  p.y += 3.;
  

  float co = length(p.yz) - (1. + sin(p.x) * .8);

  p = cp;

  float ti = time;
  for(float i  = 1.; i < 5.; ++i)
  {
    p.y += (sin(ti + p.x ) + cos(ti + p.z)) * .75;
    dist = smin(length(p) - .5, dist, 1.25);
    ti += i * .2;
    p *= 1.1;
    p.xz *= rot(.25 + i);
    p.yz *= rot(i * 2.);
    p.x += .6;
  }

  if(co < .01) id = 1.;
  dist = min(dist , co);

  float sph = length(cp) - 6.;

//  dist = max(dist,sph);

  return dist;
}

float Ray(inout vec3 cp, vec3 rd, out float id)
{
  float st = 0.;
  float cd = 0.;
  for(; st < 1.; st += 1. / 128.)
  {
    cd = map(cp, id);
    if(cd < .01) break;
    cp += rd * cd * .5;
  }

  return st;
}

vec3 normal(vec3 p)
{
  float id;
  float m = map(p, id);
  vec2 e = vec2(.01,.0);
  return normalize(vec3(
  m - map(p + e.xyy, id),
  m - map(p + e.yxy, id),
  m - map(p + e.yyx, id)
));
}

vec3 LookAt(vec3 eye, vec3 sub,vec2 uv)
{
  vec3 fo = normalize(sub - eye);
  vec3 ri = cross(fo, vec3(0.,1.,0.));
  vec3 up = cross(ri,fo);
  return normalize(fo + ri * uv.x + up * uv.y);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  float di = mod(length(uv) + time * .15, 1.75);
  float f = step(di, .15);

  vec3 eye = vec3(0.,0.,-12.);
  vec3 sub = vec3(0.);
  vec3 cp = eye;

  float st = 0.;
  float id = 0.;
  vec3 rd = LookAt(eye, sub, uv);
  st = Ray(cp, rd, id);

  if(st >= 1.) return;

  vec3 ld = normalize(sub - eye);
  vec3 norm = normal(cp);
  float li = dot(ld, norm);

  if(f < .5)
  {
    li = 1. - li;
    li *= 1.5;
  }
  else
{
  li = pow(li, 2.);
}
  norm.xy *= rot(time + cp.z);
  norm.xz *= rot(time + cp.y);

  if(id > .5)
  {
    norm.yz *= rot(time + cp.x);
  }

  out_color = vec4(norm, 0.) * li;

  

  out_color *= (1. - st) * (1. + f);

}