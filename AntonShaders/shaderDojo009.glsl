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
  float ca= cos(a); float sa = sin(a);
  return mat2(sa,-ca,ca,sa);
}

float rnd(float p)
{
  return fract(sin(p * 3669.545) );
}

#define RID(p,r) (floor((p - r/2.) / r) + r/2.)
#define REP(p,r) (mod(p + r*.5,r) - r*.5)

float map(vec3 p)
{
  float dist = 1000.;

  vec3 cp = p;

  vec2 cid = RID(p.xz,4.);
  p.xz = REP(p.xz,4.);

  float r = rnd(cid.x) + rnd(cid.y*1.1 );
  float time = fGlobalTime + r * 10000.;
  time = mod(time, 20.) + 10.;
  p.y += time - 20.;
  p.yz *= rot(fGlobalTime * (sin(r ) * 2. + 3.));


  float coin = length(p.xz) - 1.;
  coin = max(coin ,abs(p.y) - .2);

  dist = min(dist, coin);

  float col = distance(cp.xz, vec2(0.,-10.)) - 4.;
  dist = max(dist,-col);

  return dist;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.,0.,-10.);
  vec3 rd = normalize(vec3(uv,1.));
  vec3 cp = ro;
  float st; float cd = 0.;
  for(;st < 1.; st += 1. / 64.)  
  {
    cd = map(cp);
  if(cd < .01) break;
    cp += rd * cd * .125;
  }

  float dist = distance(ro,cp);

  out_color = vec4(exp(1. - dist * .25) * 10.) ;
}