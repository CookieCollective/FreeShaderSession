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

float smin( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

mat2 rot(float a)
{
  float ca = cos(a);
  float sa = sin(a);
  return mat2(ca,-sa,sa,ca);
}

float map(vec3 p)
{
  vec3 cp = p;
  float dist = 1000.;

  float time = fGlobalTime * .25;

  p.zx *= rot(-time * .25);

  for(float it = 0.; it < 2.; it += 1.)
{
  p.xz *= rot(sin(p.y + time + (fract(sin(it * 2369.)))) * PI / (it + 1.) * .5);

//  p.y += p.x * .125;
  p.zy *= rot(time+PI);
vec3 ap = max(vec3(0.),abs(p)) - 1.;
float cu = length(ap)-.5 + min(max(ap.x,max(ap.y,ap.z)), 0.);
  dist  =smin(dist, cu , .25);
}

  return dist;
}

float ray(inout vec3 cp, vec3 rd, out float cd)
{
  float st = 0.;
  for(;st < 1.; st += 1. /128.)
  {
    cd = map(cp);
    if(cd < .01)
    {
      break;
    }
    cp += rd * cd * .75;
  }

  return st;
}

vec3 normal(vec3 p)
{
  vec2 e = vec2(.01,.0);

  return normalize(vec3(
  map(p - e.xyy) - map(p + e.xyy),
  map(p - e.yxy) - map(p + e.yxy),
  map(p - e.yyx) - map(p + e.yyx)
));
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);
  uv *= .54;

  vec3 eye = vec3(0.,0.,-10.);
  vec3 rd = normalize(vec3(uv, 1.));
  vec3 cp = eye;

  float cd;
  float st = ray(cp, rd, cd);

  out_color = vec4(0.);
  if(cd < .01)
  {
    vec3 ld = normalize(vec3(0.,-1.,1.));
    ld.xz *= rot(fGlobalTime * .1);

    vec3 norm = normal(cp);
    float li = dot(ld, norm);

    ld.zy *= rot(fGlobalTime * .25);
    float li2 = dot(normalize(vec3(1.,0.,1.)), norm);
    

    float f = pow(max(li,li2), 2.);
    f = sqrt(f);
    vec4 col = vec4(norm, 0.);

    col.xy *= rot(fGlobalTime * .5);
    col.yz *= rot(fGlobalTime * .75);
    col.xz *= rot(fGlobalTime * .125);
    col = abs(col);
    out_color = mix(vec4(0.), col * 1.5, f);
  }

}