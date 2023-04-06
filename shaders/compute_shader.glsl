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

    vec4 p = in_ball.pos.xyzw;
    vec4 v = in_ball.vel.xyzw;

    float pressure = 1.0;

    // Move the ball according to the current force
    //p.xyz += v.xyz;

    int ballnum = In.balls.length();
    float ballnumf = ballnum;
    // Calculate the new force based on all the other bodies
    for (int i = 0; i < ballnum; i++) {
        // If enabled, this will keep the star from calculating gravity on itself
        // However, it does slow down the calcluations do do this check.
         if (i == curBallIndex)
              continue;




        vec3 diff = p.xyz - In.balls[i].pos.xyz;
        float distsqr = (diff.x * diff.x + diff.y * diff.y + diff.z * diff.z);
        float dist = sqrt(distsqr);
        float rad = p.w*2.0;
        /*if (dist == 0.0){
            v.x += i * 0.001;

        }
        else*/
        if(dist < rad*2.0) {

                vec3 direction = diff / (dist + curBallIndex * 0.0000001);
                float diffdist = rad*2.0 - dist;
                pressure += diffdist;
            if (dist < rad * 1.0) {
                diffdist = rad - dist;

                //distsqr = dist * dist;
                //vec3 rediff = direction * ((distsqr * 0.01) - 0.0);
                vec3 force = direction * (diffdist);

                //vec3 force = rediff / (ballnum);
                float pressurediff = In.balls[i].vel.w / v.w;

                v.xyz += force * .5 * pressurediff;
                //if(dist < 30)

                float pressuresum = In.balls[i].vel.w + v.w;
                float selfmul = (v.w / pressuresum);
                float othermul = 1.0 - selfmul;//0.01;//In.balls[i].vel.w/pressuresum;
                v.xyz = v.xyz * selfmul + In.balls[i].vel.xyz * othermul;
            }
        }


    }


    if (p.x < 0) {
        p.x = 0;
        v.x = abs(v.x);
    }
    if (p.y < 0) {
        p.y = 0;
        v.y = abs(v.y);
    }
    if (p.z < 0)p.z = 0;


    if (p.x > screen_size.x) {
        p.x = screen_size.x;
        v.x = abs(v.x) * -1;
    }
    if (p.y > screen_size.y) {
        p.y = screen_size.y;
        v.y = abs(v.y) * -1;

    }
    if (p.z > 1000)p.z = 999;

    vec3 other = vec3(mouse_pos.x, mouse_pos.y, 0);

    vec3 diff = p.xyz - other;//In.balls[i].pos.xyz;
    float distsqr = (diff.x * diff.x + diff.y * diff.y + diff.z * diff.z);
    float dist = sqrt(distsqr);
    if (dist < 500) {

        vec3 direction = diff / (dist );

        vec3 rediff = direction * ((dist) - 500.0 * rmb);

        vec3 force = rediff;

        force *= lmb;

        vec3 force2 = vec3(force.y*-0.1, force.x, force.z);
        force += force2;

        v.xyz += force * -0.001;
    }




    v.xyz*= 0.999-(0.10*mmb);

    v.y+=-0.01;
    v.w = pressure;

    float speed = sqrt(v.x*v.x+v.y*v.y);
//    if (speed > 4){
//        vec3 direc = v.xyz/speed;
//        v.xyz = direc * 4.0;
//    }


    Ball out_ball;
    out_ball.pos.xyzw = p.xyzw;
    out_ball.vel.xyzw = in_ball.vel.xyzw;
    out_ball.veldup.xyzw = v.xyzw;

    vec4 c = in_ball.color.xyzw;
    out_ball.color.xyzw = c.xyzw;
    out_ball.color.x = 0.001 * pressure;
    out_ball.color.y = 0.1 * speed;
    out_ball.color.z = 0.5;


    Out.balls[curBallIndex] = out_ball;
}
