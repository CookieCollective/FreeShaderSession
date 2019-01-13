#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

#define PI 3.141592
#define TAU (2*PI)
#define PHI (.5*PI)

float BPM = 110; // BPM of music your DJ is playing
float NB_CHANNEL = 3;
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

float map(vec3 p)
{
  float dist = 1000.;


  // Using half channels allows you to have a nice pause between steps
  float t1 = ease(multiplex(t,0,NB_CHANNEL * 2)) * PHI / 2.;
  float t2 = ease(multiplex(t,2,NB_CHANNEL * 2)) * PHI / 2.;
  float t3 = kick((multiplex(t,4,NB_CHANNEL * 2)), .75) * PHI / 2.;

  p.xy *= rot(t1);
  p.xz *= rot(t2);
  p.yz *= rot(t3);

  p = abs(p);
  float c1 = max(p.x,max(p.y,p.z)) - 1.;
  dist = min(dist, c1);

  return dist;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 cam = vec3(0.,0.,-10.);
  vec3 rd = normalize(vec3(uv+vec2(-.4,.2),1));
  vec3 cp = cam;

  float st = 0.;
  float cd = 0.;
  
  for(;st < 1.; st += 1./128.)
  {
    cd = map(cp);
    if(cd < .01) break;
    cp += rd * cd * .5;
  }

  uv *= 10.;
  float r = ease(multiplex(uv.x, 0, NB_CHANNEL));
  float g = ease(multiplex(uv.x, 1, NB_CHANNEL));
  float b = kick(multiplex(uv.x, 2, NB_CHANNEL), .75);

  out_color = vec4(
    step(distance(r,uv.y),.02),
    step(distance(g,uv.y),.02),
    step(distance(b,uv.y),.02),
    1.
  );

  float f = step(distance(uv.x,uv.y), .02);
  if(f > .5)
  {
    out_color = vec4(1.);
  }
  vec2 grid = fract(vec2(uv.x * 3, uv.y));
  if(grid.x < .05)
    out_color += .05;
  if(fract(uv.x) < .025)
    out_color += .05;

  if(cd < .01)
  out_color = vec4(1 - st);

}