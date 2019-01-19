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

float sdBox(vec3 p,vec3 b,float r)
{
  vec3 h = abs(p) - b;
  return length(max(h, 0.)) - r + min(0., max(h.x,max(h.y,h.z)));
}
float sdSphere(vec3 p,float r)
{
  return length(p) - r;
}

mat2 rot(float a)
{
  float ca = cos(a);
  float sa = sin(a);
  return  mat2(ca,-sa,sa,ca);
}

float map(vec3 p)
{
  float dist = 1000.;
  vec3 cp = p;

  p *= .35;
  for(float i = 1.; i <= 3.; i++)
  {

    p.xz *= rot(fGlobalTime);
    p.yz *= rot(fGlobalTime + i);
    p.xy *= rot(fGlobalTime + i);

    float cube = sdBox(p, vec3(1.), .25);
    float sphere = sdSphere(p,1.7);
    float shape = max(cube,-sphere);
    dist = min(dist, shape);
    p *= 1.65;


  }

  return dist;

}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);


  vec3 eye = vec3(0.,0.,-10.);
  vec3 rd = normalize(vec3(uv,1.));
  vec3 cp = eye;

  float st = 0.;
  float cd  = 0.;
  for(; st < 1.; st += 1./128.)
  {
    cd = map(cp);
    if(cd <  .01) break;
    cp += rd * cd * .25;
  }

  if(cd < .01)
  {
    out_color = vec4(1. - st);
  }
}