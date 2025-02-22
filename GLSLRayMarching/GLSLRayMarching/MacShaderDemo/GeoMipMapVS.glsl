#version 430 core
layout (location = 0) in vec2 vertex;

/*
layout (std140) uniform Example
{
					// alignedsize offset
	bool b;			// 4  0
	int i;			// 4  4
	float f;		// 4  8
	vec2 v2;		// 8  12
	vec3 v3;		// 16 20 
	vec4 v4;		// 16 36
	float v[3];		// 16 42   v[0]
					// 16 58   v[1]
					// 16 64   v[2]
	mat4 m;			// 16 112  column 0 of m
	        		// 16 128  column 1 of m
					// 16 144  column 2 of m
					// 16 160  column 3 of m
}; 

struct Vertex4
{
	float px[4]; // position x
    float py[4]; // position y
};
layout(std430, binding=2) buffer VertexData
{
	Vertex4 vertices[1];
};
*/

#define USE_UNIFORM_BLOCK
#ifdef USE_UNIFORM_BLOCK
layout (std140, binding=0) uniform TransformData
{
	uniform mat4 viewTransform;
	uniform mat4 projTransform;
};  
#else
	uniform mat4 viewTransform;
	uniform mat4 projTransform;	
#endif

uniform mat4 worldTransform;
uniform vec4 colors;

uniform ivec2 offset;

uniform float patchSize;
uniform sampler2D heightMap;
uniform ivec2 heightMapSize;
uniform ivec2 splatMapSize;

out vec2 texcoord0;
out vec2 texcoord1;
out vec4 color;

void main()
{
	vec4 height = textureLod(heightMap, (offset + vertex) / heightMapSize, 0); // 0.5m per pixel

	texcoord0 = vertex / patchSize;
	texcoord1 = (offset + vertex) / splatMapSize;

	gl_Position = projTransform * viewTransform * worldTransform * 
				vec4( (vertex.x + offset.x) * 0.5, height.x*500, (vertex.y + offset.y) * 0.5, 1.0);

	vec4 ambientLightColor = vec4(0.2, 0.2, 0.2, 1.0);
	vec4 lightcolor = vec4(1.0, 1.0, 1.0, 1.0);
	vec3 lightDir = normalize(vec3(1.0, 1.0, 1.0));
	vec4 diffuseMaterial = vec4(0.8, 0.8, 0.8, 1.0);
	
	color = lightcolor * max(dot(lightDir, vec3(0.0, 1.0, 0.0)), 0) + ambientLightColor;
	color *= diffuseMaterial;
}