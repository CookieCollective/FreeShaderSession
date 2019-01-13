#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

#define PI 3.141592
#define TAU (2*PI)
#define PHI (.5*PI)

float BPM = 110; // BPM of music your DJ is playing
float NB_CHANNEL = 9;
float t = fGlobalTime * BPM / (60. * NB_CHANNEL);

// Ease time into a nice S Curve 
// ease(int) == int
float ease(float t)
{
  return floor(t) + sin(fract(t) * PI - PHI) * .5 + .5;
}

// Transition form floor(t) to floor(t+1) with an overshoot of "b" magnitude
// kick(int) == int
float kick(float t, float b)
{
  float ft = fract(t);
  return floor(t) + ft + sin(ft * PI) * b;
}

// transition from floor(t) to floor(t+1) 
// create "n" channels who will do their transition in sequence 
// ("c" is the selected channel)
// multiplex(int,...) == int
float multiplex(float t,float c, float n)
{
  return floor(t) + clamp(fract(t) * n   - c,0,1);
}

mat2 rot(float a)
{
  float ca = cos(a);
  float sa = sin(a);
  return mat2(sa,-ca,ca,sa);
}

#define REP(p,r) (mod(p + r / 2, r) - r/ 2)

float rnd(float s)
{
  return fract(sin(s ));
}

float map(vec3 p)
{
  float dist = 1000.;

  vec3 cp = p;

  p.xy *= rot(p.z * .01);

  p.z += t * 20.;

  float cid = floor((p.x + 6) / 12) + floor((p.y + 6) / 12) * 100 + floor((p.z + 6) / 12) * 10000;
  float mt = t + rnd(cid);

  p = REP(p, 12);

  float t0 = kick(multiplex(mt,0*2,NB_CHANNEL * 2), 1);
  float t1 = kick(multiplex(mt,1*2,NB_CHANNEL * 2), 1);
  float t2 = kick(multiplex(mt,2*2,NB_CHANNEL * 2), 1);
  float t3 = kick(multiplex(mt,3*2,NB_CHANNEL * 2), 1);
  float t4 = kick(multiplex(mt,4*2,NB_CHANNEL * 2), 1);
  float t5 = kick(multiplex(mt,5*2,NB_CHANNEL * 2), 1);
  float t6 = kick(multiplex(mt,6*2,NB_CHANNEL * 2), 1);
  float t7 = kick(multiplex(mt,7*2,NB_CHANNEL * 2), 1);
  float t8 = kick(multiplex(mt,8*2,NB_CHANNEL * 2), 1);

  p.x += t0;
  p.y += t1;
  p.z += t7;
  p.x -= t3;
  p.y -= t6;
  p.xy *= rot(t4 * PHI / 2. - PI / 4.);
  p.z -= t5;
  p.xz *= rot(t2 * PHI / 2. - PI / 4.);
  p.zy *= rot(t8 * PHI / 2. - PI / 4.);
  
  p = abs(p);
  float c1 = max(p.x,max(p.y,p.z)) - 1;
  dist = min(dist, c1);
  
  p = cp;
  float tunnel = length(p.xy) - 6;
  dist = max(dist, -tunnel);

  return dist;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 cam = vec3(0.,0.,-10.);
  vec3 rd = normalize(vec3(uv, 1));
  vec3 cp = cam;

  float st = 0.;
  float cd = 0.;
  
  for(;st < 1.; st += 1./64.)
  {
    cd = map(cp);
    if(cd < .01) break;
    cp += rd * cd ;
  }

  out_color = vec4(1 - st);

}