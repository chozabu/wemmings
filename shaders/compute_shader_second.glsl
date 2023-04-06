#version 430

// Set up our compute groups
layout(local_size_x=COMPUTE_SIZE_X, local_size_y=COMPUTE_SIZE_Y) in;

// Input uniforms go here if you need them.
// Some examples:
uniform vec2 screen_size;
//uniform vec2 force;
//uniform float frame_time;

uniform vec2 mouse_pos;
uniform float lmb;
uniform float rmb;
uniform float mmb;

// Structure of the ball data
struct Ball
{
    vec4 pos;
    vec4 vel;
    vec4 veldup;
    vec4 color;
};

// Input buffer
layout(std430, binding=0) buffer balls_in
{
    Ball balls[];
} In;

// Output buffer
layout(std430, binding=1) buffer balls_out
{
    Ball balls[];
} Out;

void main()
{
    int curBallIndex = int(gl_GlobalInvocationID);

    Ball in_ball = In.balls[curBallIndex];

    Ball out_ball;
    out_ball.pos.xyz = in_ball.pos.xyz + (in_ball.veldup.xyz);
    out_ball.pos.w = in_ball.pos.w;
    out_ball.vel.xyzw = in_ball.veldup.xyzw;
    out_ball.veldup.xyzw = in_ball.veldup.xyzw;

    vec4 c = in_ball.color.xyzw;
    out_ball.color.xyzw = c.xyzw;

    Out.balls[curBallIndex] = out_ball;
}
