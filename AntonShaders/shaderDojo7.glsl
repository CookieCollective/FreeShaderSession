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
  float ca = cos(a);float sa = sin(a);
  return mat2(ca,-sa,sa,ca);
}

float fbm(vec2 p)
{
  mat2 m = mat2(.8,-.6,.6,.8);
  float acc = 0;
  p *= -m * m * .5;
  for(float i = 1.; i < 6.; ++i)
  {
    p += vec2(i * 1251.675, i * 6568.457) + vec2(fGlobalTime * .3);
    p *= m;
    acc += (sin(p.x * i) + cos(p.y * i)) * 1./(i * .5);
  }

  return acc;
}

float height = 0.;
int id = 0;

float map(vec3 p)
{

  p.yz *= rot(sin(fGlobalTime * .1) * .2 + .1);
  p.xz *= rot(fGlobalTime * .1);

  float dist = 1000;
  vec3 cp = p;

  p.y += fbm(p.xz * 2) * .1;
  float plan = p.y +.45;
  height = p.y + .65;
  dist = min(plan,dist);
  
  p = cp;
  float sph = length(p) - 4;
  dist = max(dist, sph);
  if(dist < .01) id = 1;

  p = cp;
  p.y += 5.;
  p.xz /= 4.;
  p.y *= 2.;
//  p.y = max(p.y, 0.);
  p = abs(p);
  float cube = max(p.x, max(p.y,p.z)) - 1.;
  dist = min(dist, cube);
  if(cube < .01) id = 2;

  return dist;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.,4.,-15.);
  vec3 rd = normalize(vec3(uv,1));
  vec3 cp = ro;
  rd.zy *= rot(-.3);


  float st = 0.;
  float cd = 0.;
  for(;st < 1.; st += 1./128.)
  {
    cd = map(cp);
    if(cd < .01) break;
    cp += rd * cd * .45;
  }

  vec4 sky = mix(vec4(0.1,0.1,.1,0.),vec4(.6,.6,.9,1.), smoothstep(-.1,-.0, rd.y));

  out_color = sky ;

  if(id == 1)
  {
    out_color = mix(vec4(.2,.3,.6,0.) * 1.5, vec4(1.) * 2.5, height * .8 + .2) * pow(1. - st,2.);
  }
  if(id == 2)
  {
    out_color = vec4(.8,.8,.6,1.) * (1. - st) * clamp(pow(length(cp.xz * .46), 1.7),0.,1.);
  }

}