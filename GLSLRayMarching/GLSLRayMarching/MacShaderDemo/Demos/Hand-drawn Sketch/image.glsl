// Hand-drawn Sketch Effect, by hlorenzi

#define EDGE_WIDTH 0.15
#define RAYMARCH_ITERATIONS 40
#define SHADOW_ITERATIONS 50
#define SHADOW_STEP 1.0
#define SHADOW_SMOOTHNESS 256.0
#define SHADOW_DARKNESS 0.75

// Distance functions from www.iquilezles.org
float fSubtraction(float a, float b) {return max(-a,b);}
float fIntersection(float d1, float d2) {return max(d1,d2);}
void fUnion(inout float d1, float d2) {d1 = min(d1,d2);}
float pSphere(vec3 p, float s) {return length(p)-s;}
float pRoundBox(vec3 p, vec3 b, float r) {return length(max(abs(p)-b,0.0))-r;}
float pTorus(vec3 p, vec2 t) {vec2 q = vec2(length(p.xz)-t.x,p.y); return length(q)-t.y;}
float pTorus2(vec3 p, vec2 t) {vec2 q = vec2(length(p.xy)-t.x,p.z); return length(q)-t.y;}
float pCapsule(vec3 p, vec3 a, vec3 b, float r) {vec3 pa = p - a, ba = b - a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 ); return length( pa - ba*h ) - r;}

float distf(vec3 p)
{
	float d = 100000.0;
	
	fUnion(d, pRoundBox(vec3(0,0,10) + p, vec3(21,21,1), 1.0));
	fUnion(d, pSphere(vec3(10,10,0) + p, 8.0));
	fUnion(d, pSphere(vec3(16,0,4) + p, 4.0));
	fUnion(d, pCapsule(p, vec3(10,10,12), vec3(15,15,-6.5), 1.5));
	fUnion(d, pCapsule(p, vec3(10,10,12), vec3(5,15,-6.5), 1.5));
	fUnion(d, pCapsule(p, vec3(10,10,12), vec3(10,5,-6.5), 1.5));
	fUnion(d, pTorus(vec3(15,-15,0) + p, vec2(6,2)));
	fUnion(d, pTorus2(vec3(10,-15,0) + p, vec2(6,2)));
	fUnion(d, pRoundBox(vec3(-10,10,-2) + p, vec3(1,1,9), 1.0));
	fUnion(d, pRoundBox(vec3(-10,10,-4) + p, vec3(0.5,6,0.5), 1.0));
	fUnion(d, pRoundBox(vec3(-10,10,2) + p, vec3(6,0.5,0.5), 1.0));
	
	return d;
}


vec3 normal(vec3 p)
{
	const float eps = 0.01;
	float m;
    vec3 n = vec3( (distf(vec3(p.x-eps,p.y,p.z)) - distf(vec3(p.x+eps,p.y,p.z))),
                   (distf(vec3(p.x,p.y-eps,p.z)) - distf(vec3(p.x,p.y+eps,p.z))),
                   (distf(vec3(p.x,p.y,p.z-eps)) - distf(vec3(p.x,p.y,p.z+eps)))
				 );
    return normalize(n);
}

vec4 raymarch(vec3 from, vec3 increment)
{
	const float maxDist = 200.0;
	const float minDist = 0.001;
	const int maxIter = RAYMARCH_ITERATIONS;
	
	float dist = 0.0;
	
	float lastDistEval = 1e10;
	float edge = 0.0;
	
	for(int i = 0; i < maxIter; i++) {
		vec3 pos = (from + increment * dist);
		float distEval = distf(pos);
		
		if (lastDistEval < EDGE_WIDTH && distEval > lastDistEval + 0.001) {
			edge = 1.0;
		}
		
		if (distEval < minDist) {
			break;
		}
		
		dist += distEval;
		if (distEval < lastDistEval) lastDistEval = distEval;
	}
	
	float mat = 1.0;
	if (dist >= maxDist) mat = 0.0;
	
	return vec4(dist, mat, edge, 0);
}

float shadow(vec3 from, vec3 increment)
{
	const float minDist = 1.0;
	
	float res = 1.0;
	float t = 1.0;
	for(int i = 0; i < SHADOW_ITERATIONS; i++) {
        float h = distf(from + increment * t);
        if(h < minDist)
            return 0.0;
		
		res = min(res, SHADOW_SMOOTHNESS * h / t);
        t += SHADOW_STEP;
    }
    return res;
}

float rand(float x)
{
    return fract(sin(x) * 43758.5453);
}

float triangle(float x)
{
	return abs(1.0 - mod(abs(x), 2.0)) * 2.0 - 1.0;
}

float time;
vec4 getPixel(vec2 p, vec3 from, vec3 increment, vec3 light)
{
	vec4 c = raymarch(from, increment);
	vec3 hitPos = from + increment * c.x;
	vec3 normalDir = normal(hitPos);
	
	
	float diffuse = 1.0 + min(0.0, dot(normalDir, -light));
	float inshadow = 0.0;//(1.0 - shadow(hitPos, -light)) * SHADOW_DARKNESS;
	
	diffuse = max(diffuse, inshadow);
	
	if (c.y == 0.0) diffuse = min(pow(length(p), 4.0) * 0.125,1.0);
	
	
	float xs = (rand(time * 6.6) * 0.1 + 0.9);
	float ys = (rand(time * 6.6) * 0.1 + 0.9);
	float hatching = max((clamp((sin(p.x * xs * (170.0 + rand(time) * 30.0) +
							p.y * ys * (110.0 + rand(time * 1.91) * 30.0)) * 0.5 + 0.5) -
						   		(1.0 - diffuse), 0.0, 1.0)),
						 (clamp((sin(p.x * xs * (-110.0 + rand(time * 4.74) * 30.0) +
							p.y * ys * (170.0 + rand(time * 3.91) * 30.0)) * 0.5 + 0.5) -
						   		(1.0 - diffuse) - 0.4, 0.0, 1.0)));
	
	vec4 mCol = mix(vec4(1,0.9,0.8,1), vec4(1,0.9,0.8,1) * 0.5, hatching);
					
	return mix(mCol,vec4(1,0.9,0.8,1) * 0.5,c.z);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{	
	time = floor(iTime * 16.0) / 16.0;
	// pixel position
	vec2 q = fragCoord.xy / iResolution.xy;
	vec2 p = -1.0+2.0*q;
	p.x *= -iResolution.x/iResolution.y;
	p += vec2(triangle(p.y * rand(time) * 4.0) * rand(time * 1.9) * 0.015,
			triangle(p.x * rand(time * 3.4) * 4.0) * rand(time * 2.1) * 0.015);
	p += vec2(rand(p.x * 3.1 + p.y * 8.7) * 0.01,
			  rand(p.x * 1.1 + p.y * 6.7) * 0.01);
	
	// mouse
    vec2 mo = iMouse.xy/iResolution.xy;
	vec2 m = iMouse.xy / iResolution.xy;
	if (iMouse.x == 0.0 && iMouse.y == 0.0) {
		m = vec2(time * 0.06 + 1.67, 0.78);	
	}
	m = -1.0 + 2.0 * m;
	m *= vec2(4.0,-0.75);
	m.y += 0.75;

	// camera position
	float dist = 50.0;
	vec3 ta = vec3(0,0,0);
	vec3 ro = vec3(cos(m.x) * cos(m.y) * dist, sin(m.x) * cos(m.y) * dist, sin(m.y) * dist);
	vec3 light = vec3(cos(m.x - 2.27) * 50.0, sin(m.x - 2.27) * 50.0, -20.0);
	
	// camera direction
	vec3 cw = normalize( ta-ro );
	vec3 cp = vec3( 0.0, 0.0, 1.0 );
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
	vec3 rd = normalize( p.x*cu + p.y*cv + 2.5*cw );

	// calculate color
	vec4 col = getPixel(p, ro, rd, normalize(light));
	fragColor = col;
	
}