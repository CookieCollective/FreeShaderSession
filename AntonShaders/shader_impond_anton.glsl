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

mat2 rot(float a)
{
  float ca = cos(a);
  float sa = sin(a);
  return mat2(ca,-sa,sa,ca);
}

#define REP(p, r) (mod(p + r * .5, r) - r*.5)

float map(vec3 p)
{

  vec3 cp = p;

  p.z -= 10. - fGlobalTime * 4.;

  p.xy *= rot(sin(p.z) * .05);

  p.y += sin(fGlobalTime) * 3.;

  p = REP(p, 10.);
  p.xz *= rot(fGlobalTime);
  p.xy *= rot(sin(p.z * .1 + fGlobalTime) * .25);
  float noi = texture(texNoise, vec2(p.y + fGlobalTime,0.)).r;
  float dist = length(p) - 1. - noi * .5;




  p = cp;

  float safe = length(p) - 5.;

  dist = max(dist, -safe);
  return dist;
}

vec3 normal(vec3 p)
{
  vec2 e = vec2(.01,0.);
  float cd = map(p);
  return normalize(vec3(
    cd - map(p + e.xyy),
    cd - map(p + e.yxy),
    cd - map(p + e.yyx)
));
}

void ray(inout vec3 cp, in vec3 rd, out float st, out float cd)
{
  cd = 0.;
  st = 0.;
  for(;st < 1.; st += 1./128.)
  {
    cd = map(cp);
    if(cd < .01) break;
    cp += rd * cd;
  }
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 eye = vec3(0.,0.,0.);
  vec3 rd = normalize(vec3(uv, 1.));
  vec3 cp = eye;

  float cd,st;

  ray(cp, rd, st, cd);
  float f = (1. - st);
  if(cd < .01)
  {
    vec3 norm = normal(cp);

    vec3 ld = vec3(-1.,-1.,1.);
    ld.yz *= rot(fGlobalTime);

    float li = dot(ld, norm);
    f = li;
  
    out_color = vec4(f);
    out_color.rg *= rot(cd);
    out_color.gb *= rot(st);
    out_color.br *= rot(fGlobalTime * .1);
    
    f = 1. - clamp((length(eye - cp)/ 100.), 0., 1.);
    f = pow(f, .15);
    out_color = out_color * f;
  }

  out_color += .5 * texture(cookie, gl_FragCoord.xy / v2Resolution.xy);

  
}

