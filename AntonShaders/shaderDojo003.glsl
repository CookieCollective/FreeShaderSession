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

vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}

int id = 0;
float map(vec3 p)
{
  float dist = 1000.;
  float s1 = length(p) -1.;
  dist = min(dist, s1);

  vec3 ap = abs(p);
  float b1 = max(ap.x,max(ap.y,ap.z)) - 1.;
  if(b1 < .01)  id = 1;
  dist  = min(dist,b1);

  return dist;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(5.,5.,-10.);
  vec3 rd = normalize(vec3(0.,0.,0.) - ro) + vec3(uv,0.);
  vec3 cp = ro;

  float st = 0.;
  float cd = 100.;
  float acc = 0.;
  for(;st <1.; st += 1. / 128.)
  {
    float prev = cd;
    cd = map(cp);
    if(cd < .01) 
    {
      if(id == 1)
      {
        acc += st;
        cd *= 5000.;
      }
      else
      {
        break;
      }
   }
    cp += rd * cd * .25;
  }

  out_color = vec4(acc);
}