precision highp float;

uniform vec2 u_resolution;

const int N = 20;
const int CHART_ZOOM = N*2;
const float MAX_POS = 100000.;
const float MIN_POS = -MAX_POS;
const vec3 OFFSET = vec3(0);
const int INTEGRAL = 0;

float plot(float v, float pct){
	float n = INTEGRAL>0? (0.5/float(INTEGRAL*2)) : max(0.002, 0.5/float(N*N*N));
	return step(pct-n, v) - step(pct+n, v);
}

float noise(vec3 pos){
	return fract(sin(dot(pos, vec3(13.657,9.558,11.606))) * 24097.524);
}

void main() {
	vec2 st = gl_FragCoord.xy/u_resolution.xy;

	float a;
	for (int x = 0; x < N; x++) {
		for (int y = 0; y < N; y++) {
			for (int z = 0; z < N; z++) {
				float r = noise(vec3(x,y,z)/float(N)*(MAX_POS-MIN_POS)+vec3(MIN_POS)+OFFSET);
				if (INTEGRAL > 0) r = floor(r*float(INTEGRAL)) / float(INTEGRAL) + .5/float(INTEGRAL);
				a += plot(r, st.x);
			}
		}
	}
	
	float c = noise(vec3(st,0.0)*(MAX_POS-MIN_POS)+vec3(MIN_POS)+OFFSET);
	
	gl_FragColor = vec4(vec3(c) + vec3(step(st.y, a / (INTEGRAL>0? float(N*N*N): float(N*N*N/CHART_ZOOM)))), 1);
}
