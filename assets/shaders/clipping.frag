#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;

// Output fragment color
out vec4 finalColor;

// mask should be same size as texture0
uniform sampler2D clip;

void main()
{
	// TODO: *colDiffuse*fragColor ??
    vec4 texture_color = texture(texture0, fragTexCoord);
    float clip_a = texture(clip, fragTexCoord).a;

	finalColor = vec4(texture_color.rgb, texture_color.a * clip_a);
}
