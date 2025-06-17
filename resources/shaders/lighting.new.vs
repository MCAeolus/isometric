#version 330 core

in vec3 vertexPosition;
in vec3 vertexNormal;
in vec4 vertexColor;
in vec2 vertexTexCoord;

out vec4 fragColor;
out vec3 fragPosition;
out vec3 fragNormal;
out vec2 fragTexCoord;
out vec2 scaledUV;

uniform mat4 matModel;
//uniform mat4 matView;
//uniform mat4 matProjection;
uniform mat4 mvp;

void main() {
    float w = 32.0;
    float h = 64.0;

    scaledUV = vertexTexCoord * vec2(w, h);
    
    fragPosition = vec3(matModel * vec4(vertexPosition, 1.0));
    fragNormal = vertexNormal; // smoothing potentially needed
    fragColor = vertexColor; 
    fragTexCoord = vertexTexCoord;
    
    gl_Position = mvp * vec4(vertexPosition, 1.0);
}
