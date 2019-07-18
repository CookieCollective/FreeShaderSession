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
  return mat2(ca,-sa,sa,ca);
}

float sdBox(vec3 p)
{
  p = abs(p);
  return max(p.x, max(p.y, p.z)) - 1.;
}

#define time (fGlobalTime * .25)

float mat = 0.;
#define PI 3.14159
float map(vec3 p)
{
  vec3 cp = p;


  float dist = 10000.;

  p.yz *= rot(time);
  p.xy *= rot(time * .8);

  float ti = time * 4.;


  float frti = sin(fract(ti) * PI - PI * .5) * .5 + .5;
  ti = floor(ti) + frti * frti * frti;

  p = abs(p);

  for(float i = 0.; i <= 6.; ++i)
  {
    p.x -= .15 + (sin(ti * .6) * .5 + .5) * .3;
    p.xy += .1;
    p.xy *= rot(ti * .95);
    p.xz *= rot(ti * 1. );
    p.zy *= rot(ti * .25);

    p.z -= .5;

    p = abs(p);
    dist = min(dist, sdBox(p));
    
    if(dist < .01)
    {
      mat = i;
      break;
    }
  }


  return dist;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.,0.,-10.);
  vec3 rd = normalize(vec3(uv, 1.));
  vec3 cp = ro;

  float cd = 0.; float st = 0.;

  for(; st < 1.; st += 1. / 64.)
  {
    cd = map(cp);
    if(cd < .01) break;
    cp += rd * cd;
  }

  out_color = mix(vec4(.4,.1,.9,0.) * .25,vec4(.99), length(uv) * 1.);

  
  if(cd < .01)
  {

  out_color = vec4(0.);
    vec3 col = vec3(1.,0.,0.);
    
    col.rg *= rot(float(mat));

    col *= 10.;

    out_color = mix(out_color, col.rgbb, st   );
  }
}