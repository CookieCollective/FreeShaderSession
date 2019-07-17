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
#define time fGlobalTime
#define PI acos(-1.)

mat2 rot (float a)
{return mat2(cos(a),sin(a),-sin(a),cos(a));}

float sphe (vec3 p, float r)
{return length(p)-r;}

float sc (vec3 p, float d)
{
p = abs(p);
p = max(p, p.yzx);
return min(p.x, min(p.y,p.z))-d;
}

float box (vec3 p, vec3 c)
{return length(max(abs(p)-c,0.));}

float re(float p,float d){
return mod(p-d*.5,d)-d*.5;
}



void mo(inout vec2 p,vec2 d){
p=abs(p)-d;
if(p.y>p.x)p=p.yx;
}


void amod(inout vec2 p,float m){
float a=re(atan(p.x,p.y),m);
p=vec2(cos(a),sin(a))*length(p);
}


float g;
float SDF (vec3 p)
{
p.xy *= rot(time*.2);
//p.yz *= rot(time);
//p.y += 1.;
float b = box (p, vec3(0.5));

//p.x-=.9;


vec3 q=p;;
p.z=re(p.z, 2.);
amod(p.xy, 6.28/5.);
mo(p.xy, vec2(2));
p.x=abs(p.x) - 1;;
p.xy*=rot(3.14*.25);
float d = sc (p, 0.2);

p=q;

amod(p.xy, 6.28/3.);
mo(p.xy,vec2(3, 1));
amod(p.xy, 6.28/5.);
p.xy*=rot(p.z*.1);

mo(p.xy, vec2(1));
p.x=abs(p.x)-1;
p.x=abs(p.x)-.2;//p.x=abs(p.x)-1.2;
//p.y=abs(p.y)-.4;
d=min(d,length(p.xy)-.08);
g+=.01/(.01+d*d);
return d;
//return max(b,-s);
}

vec3 line (vec2 uv)
{
  uv *= rot(PI/4.);
  uv *= 10.;
  uv.y += sin(uv.x+time);
  float id = floor(uv.y);
  return (mod(id,2.)==0.)? vec3(0.) : vec3(1.);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.001,0.001, -4.+time*4.);
  vec3 p = ro;
  vec3 rd = normalize(vec3(uv ,1.));


  vec3 col = vec3(0);line(uv);
  float shad = 0.;
  bool hit= false;
float i=0.;
  for (; i<1; i+=.01)
{
float d = SDF(p);
d=max(abs(d), .002);
p += d*rd*.3;
}

//if (hit) {
col = mix(vec3(.9, .2, .1), vec3(.1, .12, .1),sin(uv.x*4.)+i);
col+=g*.01;
//}

  out_color = vec4(col,1.);
}