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
#define TAU (PI * 2.)

#define time (fGlobalTime)

#define RID(p, r) (floor((p + r/2.) / r))
#define REP(p, r) (mod(p + r/2., r) - r/2.)

// from https://www.shadertoy.com/view/4tdSWr
const mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );

vec2 hash( vec2 p ) {
	p = vec2(dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)));
	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise( in vec2 p ) {
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;
	vec2 i = floor(p + (p.x+p.y)*K1);	
    vec2 a = p - i + (i.x+i.y)*K2;
    vec2 o = (a.x>a.y) ? vec2(1.0,0.0) : vec2(0.0,1.0); //vec2 of = 0.5 + 0.5*vec2(sign(a.x-a.y), sign(a.y-a.x));
    vec2 b = a - o + K2;
	vec2 c = a - 1.0 + 2.0*K2;
    vec3 h = max(0.5-vec3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
	vec3 n = h*h*h*h*vec3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
    return dot(n, vec3(70.0));	
}

float fbm(vec2 n) {
	float total = 0.0, amplitude = 0.1;
	for (int i = 0; i < 2; i++) {
		total += noise(n) * amplitude;
		n = m * n;
    n += time * .5;
		amplitude *= 0.4;
	}
	return total;
}


// from https://www.shadertoy.com/view/ltl3D8
 float cubemap( in vec3 d )
{
    vec3 n = abs(d);
    vec3 v = (n.x>n.y && n.x>n.z) ? d.xyz: 
             (n.y>n.x && n.y>n.z) ? d.yzx:
                                    d.zxy;
    vec2 uv = 0.5+0.5*v.yz/v.x;

    return fbm(uv * 8.);
}

mat2 rot(float a)
{
  float ca = cos(a); float sa = sin(a);
  return mat2(ca,-sa,sa,ca);
}

// from https://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdOctahedron( in vec3 p, in float s)
{
    p = abs(p);
    return (p.x+p.y+p.z-s)*0.57735027;
}

float sdPlane(vec3 p, vec4 n)
{
  return dot(p,n.xyz) - n.w;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0))
         + min(max(d.x,max(d.y,d.z)),0.0); // remove this line for an only partially signed sdf 
}

float solid(vec3 p)
{
  float dist = -1000.;
  vec3 dir = vec3(0.,1.,0.);
  float h = 3.;
  float v = 6.;
  mat2 hr = rot(TAU / h);
  mat2 vr = rot(TAU / v);

  for(float j = 0.; j < v; ++j)
  {
    for(float i = 0.; i < h; ++i)
    {
      dist = max(dist,sdPlane(p, vec4(dir,1.)));
      dir.xz *= hr;
    }

    dir.yz *= vr;
  }

  return dist;
}

float distortion = 0;

float map(vec3 p)
{

  vec3 cp = p;

  float t = time  * 1.;

  vec3 orbit = normalize(vec3(1.,0.,1.));
  orbit.xy *= rot(t * .12);
  orbit.yz *= rot(sin(t * .23) * .2);

  vec3 distOrb = p + orbit * 2.9;
    
  distortion = clamp(1.5 - length(distOrb), 0., 1.);
  distortion*= distortion;

  p = cp;

  p *= 1.;
  float dist = 1000.;

  p.xy *= rot(-t *.05);
  p.yz *= rot(-t * .025);
  p.zx *= rot(-t * .00125);


  float diff = cubemap(normalize(p));
  diff *= 10;
  diff = 1. - exp(-.3 - diff * 1.2);
  diff *= 1.;
   
  p = p + normalize(distOrb - p) * diff * distortion;

  dist = max(sdOctahedron(p,3.5), sdBox(p,vec3(2.15))) ;


  p = cp;

  p += orbit * 4.3;

  p.xy *= rot(-t *.27);
  p.yz *= rot(-t * .135);
  p.zx *= rot(-t * .0125);
  
  diff = cubemap(normalize(p));
  diff *= 10;
  diff = 1. - exp(-.3 - diff * 1.2);
  diff *= .3;


  float octahedre = sdOctahedron(p + normalize(p) * diff * distortion, .7) ;
  dist = min(dist, octahedre);

  return dist;
}

void ray(inout vec3 cp,vec3 rd, out float st, out float cd)
{
  for(st = 0.; st < 1.; st += 1./128)
  {
    cd = map(cp);
    if(cd < .01)
      break;
    cp += rd * cd * .5;
  }
}  

vec3 normal(vec3 p)
{
  vec2 e = vec2(.01,.0);
  float d = map(p);
  return normalize(vec3(
    d - map(p + e.xyy),
    d - map(p + e.yxy),
    d - map(p + e.yyx)
  ));
}

vec3 lookAt(vec3 eye, vec3 tar, vec2 uv)
{
  vec3 fd = normalize(tar - eye);
  vec3 ri = cross(fd, vec3(0.,1.,0.));
  vec3 up = cross(ri,fd);
  return normalize(fd + ri * uv.x + up * uv.y);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 eye = vec3(0.,0.,-10.);
  vec3 tar = vec3(0.);
  vec3 rd = lookAt(eye, tar, uv);
  vec3 cp = eye;
  float st,cd;
  ray(cp,rd,st,cd);

  float dist = length(eye - cp);


  out_color = mix(vec4(1.), vec4(.6,.6,.68,1.), pow((gl_FragCoord.x / v2Resolution.x * .75 + .1), 1.2));
  if(cd < .01)
  {
    vec3 norm = normal(cp);
    vec3 ld = normalize(vec3(1.,-1.,1.));
    float li = dot(norm,ld);
    out_color = mix(
        out_color,
        mix(
          mix(vec4(.84,.84,.855,1.),
              vec4(.85,.85,.87,1.),
                1. - pow(1. - distortion, 2.)),
          vec4(.4,.4,.52,1.),
        li),
        exp(-distance(cp,eye) * .007));
  }
  
  out_color = pow(out_color, vec4(2.2));
}