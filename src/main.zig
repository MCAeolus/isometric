const std = @import("std");

const ArrayList = std.ArrayList;

const globals = @import("globals.zig");
const rl = globals.Raylib;
const light = @import("light.zig");
const sprite = @import("sprite.zig");
const mapController = @import("map.zig");
const playerController = @import("player.zig");

var State: *globals.GameState = undefined;

fn GetIsometric(v: rl.Vector3) rl.Vector3 {
    var interVec = rl.Vector3Scale(rl.Vector3{ .x = v.x - v.z, .y = 0, .z = v.x + v.z }, 0.7);
    interVec.y = v.y;
    return interVec;
}

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // const allocator = gpa.allocator();
    State = globals.GetGameState();
    // globals.GameState.init(allocator);
    // for mac potentially: rl.FLAG_WINDOW_HIGHDPI
    rl.SetConfigFlags(rl.FLAG_MSAA_4X_HINT);
    rl.InitWindow(State.screen.width, State.screen.height, "main window");
    rl.SetExitKey(rl.KEY_NULL);
    defer rl.CloseWindow();

    State.camera.position = rl.Vector3{ .x = 0.0, .y = 4.0, .z = 7.0 };
    State.camera.target = rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 };
    State.camera.up = rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 }; // y is UP
    State.camera.fovy = 20.0; //degrees (y-axis)
    State.camera.projection = rl.CAMERA_ORTHOGRAPHIC;

    //State.player = .{ .position = rl.Vector3{ .x = 0, .y = 1, .z = 0 }, .spriteSheet = sprite.NewSprite(rl.LoadTexture("resources/player/sprite_player.png"), 32, 32, 0, 6), .moveSpeed = 0.1 };
    var player = playerController.Player.Init(rl.LoadTexture("resources/player/sprite_player.png"), 32, 32, 0.1);

    const lightingShader = rl.LoadShader("resources/shaders/lighting.new.vs", "resources/shaders/lighting.new.fs");
    const alphaDiscardShader = rl.LoadShader(null, "resources/shaders/alphadiscard.fs");
    //lightingShader.locs[rl.SHADER_LOC_VECTOR_VIEW] = rl.GetShaderLocation(lightingShader, "viewPos");
    //    lightingShader.locs[rl.SHADER_LOC_MATRIX_MODEL] = rl.GetShaderLocation(lightingShader, "matModel");

    const lAmbient = rl.GetShaderLocation(lightingShader, "ambientColor");
    const lAmbientStrength = rl.GetShaderLocation(lightingShader, "ambientStrength");
    const lPixelation = rl.GetShaderLocation(lightingShader, "pixelresolution");
    const ambientStrength: f32 = 0.4;
    const pixelResolution: i32 = 64;
    rl.SetShaderValue(lightingShader, lAmbient, &[3]f32{ 1.0, 1.0, 1.0 }, rl.SHADER_UNIFORM_VEC3); //ambient color
    rl.SetShaderValue(lightingShader, lAmbientStrength, &ambientStrength, rl.SHADER_UNIFORM_FLOAT);
    rl.SetShaderValue(lightingShader, lPixelation, &pixelResolution, rl.SHADER_UNIFORM_INT);

    const bgShader = rl.LoadShader(null, "resources/shaders/bg.new.fs");
    var sunPos = rl.Vector3{ .x = 0.0, .y = 1.5, .z = 0.0 };
    var sunAngle: f32 = 0.0;

    var sunPos2 = rl.Vector3{ .x = 0.0, .y = 0.0, .z = 1.5 };

    var lights: [globals.MaxLights]light.Light = undefined;
    lights[0] = light.CreateLight(light.LightType.DIRECTIONAL, sunPos, rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 }, rl.YELLOW, 50.0, lightingShader); // sun
    lights[1] = light.CreateLight(light.LightType.POINT, sunPos2, rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 }, rl.GREEN, 50.0, lightingShader); //vertical sun

    const bgPlaneMesh = rl.GenMeshPlane(2, 1, 1, 1);
    var bgPlaneModel = rl.LoadModelFromMesh(bgPlaneMesh);
    bgPlaneModel.materials[0].shader = bgShader;
    bgPlaneModel.transform = rl.MatrixRotateX(90 * rl.DEG2RAD); //.z = -90 * rl.DEG2RAD });566
    const lBgOffset = rl.GetShaderLocation(bgShader, "xoffset");
    const bg_frame: [5]rl.Texture2D = .{
        rl.LoadTexture("resources/bg/1.png"),
        rl.LoadTexture("resources/bg/2.png"),
        rl.LoadTexture("resources/bg/3.png"),
        rl.LoadTexture("resources/bg/4.png"),
        rl.LoadTexture("resources/bg/5.png"),
    };
    var bg_offsets: [5]f32 = undefined;
    @memset(&bg_offsets, 0);

    const letterTexture = rl.LoadTexture("resources/letter.png");
    const letterBgTexture = rl.LoadTexture("resources/letter_bg.png");
    const letterInput = rl.LoadFileText("resources/letter.txt");
    var letterSpritePos = rl.Vector3One();
    const letterSpriteMinY = letterSpritePos.y;
    var letterSprite = sprite.NewSprite(letterTexture, 32, 32, 4, 0.2);
    letterSprite.SetFrameRange(0, 0, 0.1);
    letterSprite.SetBounce(true);

    var letterInRange = false;
    var letterOpen = false;
    // const cubeMesh = rl.GenMeshCube(1.0, 1.0, 1.0);
    // var cubeModel = rl.LoadModelFromMesh(cubeMesh);
    // cubeModel.transform = rl.MatrixRotateY(45 * rl.DEG2RAD);

    // const texelTexture = rl.LoadTexture("resources/grass.png");
    // cubeModel.materials[0].maps[rl.MATERIAL_MAP_DIFFUSE].texture = texelTexture;
    // cubeModel.materials[0].shader = lightingShader;

    //const at_size = 24; //px
    //const atlas_texture = rl.LoadTexture("resources/isometric tiles.png");
    //var tex_rect = rl.Rectangle{ .x = 0, .y = 0, .width = at_size * 2, .height = at_size };
    //var frames: u32 = 0;
    //const num_x_frames = atlas_texture.width / at_size * 2;
    //const num_y_frames = atlas_texture.height / at_size;
    // var tex_pos: u32 = 0;
    rl.SetTargetFPS(rl.GetMonitorRefreshRate(rl.GetCurrentMonitor()));
    const scaleDownFactor = 1;
    const renderTexture = rl.LoadRenderTexture(@divFloor(State.screen.width, scaleDownFactor), @divFloor(State.screen.height, scaleDownFactor));
    //const cameraTranslateUnitVector = rl.Vector3Normalize(rl.Vector3CrossProduct(State.camera.position, player.position));

    var map = try mapController.LoadMap("resources/map.map", allocator, lightingShader);
    player.position = GetIsometric(rl.Vector3Subtract(map.spawn, map.mapCenter));
    player.position = rl.Vector3Subtract(player.position, rl.Vector3{ .x = 1, .z = 1 });
    // std.debug.print("Spawn at: {any}\n", .{player.position});

    while (!rl.WindowShouldClose()) {
        const dt = rl.GetFrameTime();
        //checkKeyState();

        // update camera

        State.camera.position.x = rl.Lerp(State.camera.position.x, player.position.x, dt * 1);
        State.camera.position.z = rl.Lerp(State.camera.position.z, player.position.z + State.camera_follow_distance, dt * 1);

        State.camera.target = rl.Vector3Lerp(State.camera.target, rl.Vector3Subtract(player.position, rl.Vector3{ .x = 0, .y = 1, .z = 0 }), dt * 0.9);
        // State.camera.target.x = rl.Lerp(State.camera.position.x, player.position.x, dt * 0.7);
        // State.camera.target.z = rl.L
        //rl.UpdateCamera(&State.camera, rl.CAMERA_ORBITAL);
        //rl.SetShaderValue(lightingShader, lightingShader.locs[rl.SHADER_LOC_VECTOR_VIEW], &State.camera.position.x, rl.SHADER_UNIFORM_VEC3);

        // update player velocity, position, sprite keyframes
        (&player).Update(dt);

        // if (rl.IsKeyDown(rl.KEY_A)) {
        //     State.camera.position = rl.Vector3Add(State.camera.position, cameraTranslateUnitVector);
        // } else if (rl.IsKeyDown(rl.KEY_D)) {
        //     State.camera.position = rl.Vector3Subtract(State.camera.position, cameraTranslateUnitVector);
        // }

        // control camera wrt player position
        //State.camera.position.x = rl.Lerp(State.camera.position.x, player.position.x, dt * 1);
        //State.camera.position.z = rl.Lerp(State.camera.position.z, player.position.z, 0.1);
        //        const curCamDistDelta = rl.Vector3DistanceSqr(State.camera.position, player.position) - cameraFollowDist;

        //State.camera.position.z = rl.Lerp(State.camera.position.z, player.position.z + 12.0, 0.3);
        //State.camera.position.x = rl.Lerp(State.camera.position.x, player.position.x + 12.0, 0.3);
        //State.camera.target.x = rl.Lerp(State.camera.position.x, player.position.x, dt * 0.7);
        //State.camera.targ.y = 0;

        // tmp: update 'sun'
        sunAngle += 0.009;
        sunPos.x = std.math.cos(sunAngle) * 4.0;
        sunPos.z = std.math.sin(sunAngle) * 4.0;
        sunPos.y = std.math.sin(sunAngle) * 0.5 + 1.5;

        sunPos2.x = std.math.sin(sunAngle) * 6.2;
        sunPos2.y = std.math.cos(sunAngle) * 6.2;
        sunPos2.z = std.math.sin(sunAngle) * 0.5 + 1.5;
        lights[0].position = sunPos;
        lights[1].position = sunPos2;
        light.UpdateLightValues(lightingShader, lights[0]);
        light.UpdateLightValues(lightingShader, lights[1]);

        letterInRange = rl.Vector3DistanceSqr(player.position, letterSpritePos) < 4;
        if (letterInRange) {
            letterSprite.SetFrameRange(0, 3, 0.6);
        } else {
            letterSprite.SetFrameRange(0, 0, 0.1);
        }
        //std.debug.print("{any}\n", .{letterInRange});
        letterSprite.Update(dt);
        // make letter 'hover'

        letterSpritePos.y = letterSpriteMinY + @as(f32, @floatCast(std.math.sin(rl.GetTime()))) * 0.2;

        if (letterInRange and rl.IsKeyPressed(rl.KEY_I)) {
            letterOpen = true;
        }
        if (letterOpen and rl.IsKeyPressed(rl.KEY_ESCAPE)) {
            letterOpen = false;
        } else if (rl.IsKeyPressed(rl.KEY_ESCAPE)) {
            break;
        }

        //DRAW SECTION BEGIN
        //draw to rendertex
        rl.BeginTextureMode(renderTexture);
        rl.ClearBackground(rl.BLUE);

        // move parallax here?

        rl.BeginShaderMode(bgShader);
        for (bg_frame, 0..) |frame, ix| {
            bgPlaneModel.materials[0].maps[rl.MATERIAL_MAP_DIFFUSE].texture = frame;
            bg_offsets[ix] += dt * 0.1 / @as(f32, @floatFromInt(ix + 1 * ix + 1));
            rl.SetShaderValue(bgShader, lBgOffset, &bg_offsets[ix], rl.SHADER_UNIFORM_FLOAT);
            //const bg_pos = -15.0 + @as(f32, @floatFromInt(ix));
            // rl.DrawTexture(frame, 0, 0, rl.WHITE);
            rl.DrawModel(bgPlaneModel, rl.Vector3{ .x = State.camera.position.x, .y = State.camera.position.y - 7, .z = -1 }, 25.0, rl.WHITE);
        }
        rl.EndShaderMode();

        // const dim = rl.MeasureTextEx(rl.GetFontDefault(), "We did it!", 20, 1.0);
        //const tx: c_int = @as(u32, @floatFromInt(State.screen.width) / 2) - 12;
        //const ty: c_int = @as(u32, @floatFromInt(State.screen.height) / 2) - 12;
        //const screen = State.screen;
        rl.BeginMode3D(State.camera);

        // background
        // for (bg_frame, 0..) |frame, ix| {
        //     bgPlaneModel.materials[0].maps[rl.MATERIAL_MAP_DIFFUSE].texture = frame;
        //     bg_offsets[ix] += dt * 0.1 / @as(f32, @floatFromInt(ix + 1 * ix + 1));
        //     rl.SetShaderValue(bgShader, lBgOffset, &bg_offsets[ix], rl.SHADER_UNIFORM_FLOAT);
        //     const bg_pos = -15.0 + @as(f32, @floatFromInt(ix));
        //     rl.DrawModel(bgPlaneModel, rl.Vector3{ .x = State.camera.position.x, .y = State.camera.position.y - 7, .z = bg_pos }, 25.0, rl.WHITE);
        // }

        for (0..map.width) |x| {
            for (0..map.height) |z| {
                const tile = map.GetTile(@intCast(x), @intCast(z));
                //if (tile == null) continue;
                //var pos = GetIsometric(@intCast(x), 0, @intCast(z));
                var pos = rl.Vector3{ .x = @as(f32, @floatFromInt(x)) + 1, .y = 0.0, .z = @as(f32, @floatFromInt(z)) + 1 };
                pos = rl.Vector3Subtract(pos, map.mapCenter);
                pos = GetIsometric(pos);
                //std.debug.print("{d},{d} = pos{any}\n", .{ x, z, pos });
                //pos = rl.Vector3RotateByAxisAngle(pos, rl.Vector3{ .x = 0, .y = 1, .z = 0 }, 45.0 * rl.DEG2RAD);
                rl.DrawModel(tile.tileType.model, pos, 1.0, rl.WHITE);
            }
        }
        // rl.DrawModel(cubeModel, rl.Vector3{ .x = 0.5, .y = 2.3, .z = 0.5 }, 1.0, rl.WHITE);

        rl.DrawSphere(sunPos, 0.2, rl.YELLOW);
        rl.DrawSphere(sunPos2, 0.2, rl.GREEN);

        rl.DrawGrid(10, 1);

        //rl.DrawBillboardRec(State.camera, State.player.spriteSheet.textureSheet, State.player.spriteSheet.rectSrc, State.player.position, rl.Vector2{ .x = 1, .y = 1 }, rl.WHITE);
        // HANDLE BILLBOARDS

        rl.BeginShaderMode(alphaDiscardShader);
        (&player).Draw(State.camera);
        rl.DrawBillboardRec(State.camera, letterSprite.textureSheet, letterSprite.rectSrc, letterSpritePos, rl.Vector2One(), rl.WHITE);
        rl.EndShaderMode();
        rl.EndMode3D();

        rl.DrawFPS(10, 10);
        drawCenteredText(rl.Vector2{ .x = 60, .y = 60 }, rl.TextFormat("%02.02f,%02.02f", player.position.x, player.position.z), 20, rl.GetFontDefault(), rl.WHITE);

        if (letterInRange and !letterOpen) {
            const screenPosSprite = rl.GetWorldToScreen(rl.Vector3Add(letterSpritePos, rl.Vector3{ .y = 1 }), State.camera);
            //std.debug.print("{d}, {d}\n", .{ screenPosSprite.x, screenPosSprite.y });
            drawCenteredText(screenPosSprite, "Press [I] to Interact", 20, rl.GetFontDefault(), rl.BLUE);
        }

        if (letterOpen) {
            // show letter overlay
            rl.DrawTexture(letterBgTexture, 0, 0, rl.WHITE);
            rl.DrawText(letterInput, 10, 10, 20, rl.DARKGRAY);
        }

        rl.EndTextureMode();

        rl.BeginDrawing();
        rl.DrawTexturePro(renderTexture.texture, rl.Rectangle{ .x = 0, .y = 0, .width = @floatFromInt(renderTexture.texture.width), .height = @floatFromInt(-renderTexture.texture.height) }, rl.Rectangle{ .x = 0, .y = 0, .width = @floatFromInt(State.screen.width), .height = @floatFromInt(State.screen.height) }, rl.Vector2Zero(), 0.0, rl.WHITE);
        rl.EndDrawing();
        //drawCenteredText(.{ .x = @as(f32, @floatFromInt(screen.width)) / 2, .y = @as(f32, @floatFromInt(screen.height)) / 2 - 50 }, "We did it! Again!", 40, rl.GetFontDefault(), rl.RAYWHITE);
        // rotate through atlas
        //frames += 1;
        //if (frames % 10 == 0) {
        //    frames += 1;
        //    tex_rect.x = (48 * frames % num_x_frames);
        //}

        //rl.DrawTextureRec(atlas_texture, tex_rect, .{ .x = 100, .y = 100 }, rl.WHITE);
        // rl.DrawText("We did it!", tx, ty, 20, rl.BLACK);
    }

    //rl.UnloadModel(cubeModel);
    //rl.UnloadShader(lightingShader);
    //rl.CloseWindow();
}

fn drawCenteredText(pos: rl.Vector2, text: [*c]const u8, fontSize: f32, font: rl.Font, color: rl.Color) void {
    //const screen = globals.GameState.Get().Screen;
    const dim = rl.MeasureTextEx(font, text, fontSize, 1.0);
    const tx: f32 = pos.x - dim.x / 2;
    const ty: f32 = pos.y - dim.y / 2;
    rl.DrawTextEx(font, text, .{ .x = tx, .y = ty }, fontSize, 1.0, color);
}

// fn checkKeyState() void {
//     if (rl.IsKeyDown(rl.KEY_RIGHT)) {
//         State.player.position.x += State.player.moveSpeed;
//         State.player.position.z -= State.player.moveSpeed;
//     }
//     if (rl.IsKeyDown(rl.KEY_LEFT)) {
//         State.player.position.x -= State.player.moveSpeed;
//         State.player.position.z += State.player.moveSpeed;
//     }
//     if (rl.IsKeyDown(rl.KEY_UP)) {
//         State.player.position.x -= State.player.moveSpeed;
//         State.player.position.z -= State.player.moveSpeed;
//     }
//     if (rl.IsKeyDown(rl.KEY_DOWN)) {
//         State.player.position.x += State.player.moveSpeed;
//         State.player.position.z += State.player.moveSpeed;
//     }
// }
