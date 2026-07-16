package CampoMinado

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

Cell :: enum u8 {
    None,
    Empty,
    Mine,
    Flag,
}

CELLS_PER_ROW_AND_COLUM :: 12
grid: [CELLS_PER_ROW_AND_COLUM * CELLS_PER_ROW_AND_COLUM]Cell
CELL_SIZE :: [2]i32{SCREEN_SIZE.x / CELLS_PER_ROW_AND_COLUM, SCREEN_SIZE.y / CELLS_PER_ROW_AND_COLUM}
MINES : u16 : 20

CELL_COLOR1     :: rl.Color{75, 255, 0, 255}
CELL_COLOR2     :: rl.Color{50, 200, 0, 255}
CELL_HOVERED    :: rl.Color{50, 180, 0, 255}

SCREEN_SIZE :: [2]i32{600, 600}
TITLE : cstring : "Campo minado"

GameState :: enum u8 {
    UNITIALIZED,
    STARTED,
    ENDED,
}

game := GameState.UNITIALIZED

main :: proc() {
    rl.InitWindow(SCREEN_SIZE.x, SCREEN_SIZE.y, TITLE)
    defer rl.CloseWindow()
    rl.SetTargetFPS(30)

    for !rl.WindowShouldClose() {
        n := 0

        mousePos := rl.GetMousePosition()
        if rl.IsMouseButtonPressed(.LEFT) {
            dividedPos := [2]i32{
                i32(mousePos.x) / CELL_SIZE.y,
                i32(mousePos.y) / CELL_SIZE.y,
            }

            cellIndex := dividedPos.x + CELLS_PER_ROW_AND_COLUM * dividedPos.y
            if grid[cellIndex] == .None {
                if game == .UNITIALIZED {
                    grid[cellIndex] = .Empty
                    generate_field()
                }
            }
        }

        rl.BeginDrawing()
        for x := 0; x < CELLS_PER_ROW_AND_COLUM; x+=1 {
            n+=1
            for y := 0; y < CELLS_PER_ROW_AND_COLUM; y+=1 {
                cell := rl.Rectangle{
                    f32(CELL_SIZE.x * i32(x % CELLS_PER_ROW_AND_COLUM)), f32(CELL_SIZE.y * i32(y % CELLS_PER_ROW_AND_COLUM)),
                    f32(CELL_SIZE.x), f32(CELL_SIZE.y),
                }

                if rl.CheckCollisionPointRec(mousePos, cell) {
                    rl.DrawRectangleRec(cell, CELL_HOVERED)
                } else {
                    rl.DrawRectangleRec(cell, CELL_COLOR1 if n % 2 == 0 else CELL_COLOR2)
                }

                n+=1
            }
        }

        rl.EndDrawing()
    }
}

generate_field :: proc() {

}
