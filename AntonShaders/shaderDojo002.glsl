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

vec3 spherePos = vec3(0.,1.,0.);

#define REP(p, r) (mod(p + r *.5, r) - r * .5)

int id = 0;

float map(vec3 p)
{

  p = REP(p, 12.);

float dist = 1000.;

spherePos.x = cos(fGlobalTime);
spherePos.y = sin(fGlobalTime);

float s1 = distance(p,spherePos) -1.;
if(s1 < .01)
{
  id = 1;
}

dist = min(dist, s1);


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

  float st = 0.;
  float cd = 0.;
  for(;st < 1.; st += 1. / 128.) 
{
  cd = map(cp);
  if(cd < .01)
  break;
  cp += rd * cd * .25;
}

out_color = texture(texChecker, uv);

  if(id ==1)
  {
    vec3 tp = normalize(cp - spherePos);
    float x = atan(tp.z,tp.y);
    float y = atan(tp.x,tp.z);
    out_color = vec4(1.);
  }

  out_color*= (1. - st * .5);
}