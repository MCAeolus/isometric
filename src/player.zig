const std = @import("std");
const globals = @import("globals.zig");
const sprite = @import("sprite.zig");
const rl = globals.Raylib;

pub const Player = struct {
    sprite: sprite.Sprite,
    spriteFlip: bool = false,
    // current:
    // [0,3] = idle,
    // [8,13] = walk,
    // [16,23] = jump
    velocity: rl.Vector3,
    position: rl.Vector3,
    moveSpeed: f32,
    jumping: bool = false,

    pub fn Update(player: *Player, dt: f32) void {
        //reset
        player.velocity = rl.Vector3Zero();
        player.AnimationIdle();
        player.sprite.rectSrc.width = @as(f32, @floatFromInt(player.sprite.rectW));
        player.spriteFlip = false;

        if (player.jumping and player.position.y > 1.0) {
            player.velocity.y += globals.GetGameState().gravity;
        } else {
            player.jumping = false;
            player.velocity.y = 0;
            player.position.y = 1.0;
        }

        //check for velocity;
        if (rl.IsKeyDown(rl.KEY_RIGHT)) {
            player.velocity = rl.Vector3{ .x = 1, .z = 0, .y = 0 };
        }
        if (rl.IsKeyDown(rl.KEY_LEFT)) {
            player.velocity = rl.Vector3Add(player.velocity, rl.Vector3{ .x = -1, .z = 0, .y = 0 });
            player.spriteFlip = true;
        }
        if (rl.IsKeyDown(rl.KEY_DOWN)) {
            player.velocity = rl.Vector3Add(player.velocity, rl.Vector3{ .x = 0, .z = 1, .y = 0 });
        }
        if (rl.IsKeyDown(rl.KEY_UP)) {
            player.velocity = rl.Vector3Add(player.velocity, rl.Vector3{ .x = 0, .z = -1, .y = 0 });
        }
        player.velocity = rl.Vector3Normalize(player.velocity); //normalize to unit
        player.velocity = rl.Vector3Scale(player.velocity, player.moveSpeed);

        if (rl.IsKeyPressed(rl.KEY_SPACE) and !player.jumping) {
            player.jumping = true;
            player.velocity.y = 1.0;
        } else if (player.velocity.y > 0.01 and player.jumping) {
            player.velocity.y = rl.Lerp(player.velocity.y, 0, -0.01);
        } else {
            player.velocity.y = 0;
        }

        //std.debug.print("current velocity: {any}\n", .{player.velocity});

        // update sprite keyframes
        if (@abs(player.velocity.x) > 0.01 or @abs(player.velocity.z) > 0.01) {
            player.AnimationWalk();
        }
        if (player.velocity.y > 0.01) {
            player.AnimationJump();
        }
        //std.debug.print("jump state: jumping={any}, vy={d}, py={d}\n", .{ player.jumping, player.velocity.y, player.position.y });
        //std.debug.print("total vel: {any}\n", .{player.velocity});
        //std.debug.print("sprite: {any}\n", .{player.sprite});
        //update position
        player.position = rl.Vector3Add(player.position, rl.Vector3Scale(player.velocity, dt));

        player.sprite.Update(dt);
    }

    fn AnimationIdle(player: *Player) void {
        player.sprite.SetFrameRange(0, 3, 0.2);
    }

    fn AnimationWalk(player: *Player) void {
        if (!player.spriteFlip) {
            player.sprite.SetFrameRange(8, 13, 0.1);
        } else {
            player.sprite.SetFrameRange(9, 14, 0.1); // we have to move the rectangle selector forward one frame, since it is now facing backwards
            player.sprite.rectSrc.width = -player.sprite.rectSrc.width;
        }
    }

    fn AnimationJump(player: *Player) void {
        player.sprite.SetFrameRange(16, 23, 0.1);
    }
    pub fn Draw(player: *Player, camera: rl.Camera) void {
        rl.DrawBillboardRec(camera, player.sprite.textureSheet, player.sprite.rectSrc, player.position, rl.Vector2One(), rl.WHITE);
    }

    pub fn Init(tex: rl.Texture2D, spriteWidth: u32, spriteHeight: u32, frameSpeed: f32) Player {
        return .{
            .sprite = sprite.NewSprite(tex, spriteWidth, spriteHeight, 0, frameSpeed),
            .velocity = rl.Vector3Zero(),
            .position = rl.Vector3{ .x = 0, .y = 1, .z = 0 },
            .moveSpeed = 2.0,
        };
    }
};
