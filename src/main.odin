package CampoMinado

import "core:fmt"
import "core:math/rand"
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

        mousePos := rl.GetMousePosition()
        if rl.IsMouseButtonPressed(.LEFT) {
            cellIndex := get_cell_index(mousePos)
            if grid[cellIndex] == .None {
                if game == .UNITIALIZED {
                    grid[cellIndex] = .Empty
                    generate_field()
                }
            }
        }

        rl.BeginDrawing()
        n := 0
        for x := 0; x < CELLS_PER_ROW_AND_COLUM; x+=1 {
            n+=1
            for y := 0; y < CELLS_PER_ROW_AND_COLUM; y+=1 {
                defer n+=1

                cell := grid[get_cell_index(x, y)]
                cellRec := rl.Rectangle{
                    f32(CELL_SIZE.x * i32(x % CELLS_PER_ROW_AND_COLUM)), f32(CELL_SIZE.y * i32(y % CELLS_PER_ROW_AND_COLUM)),
                    f32(CELL_SIZE.x), f32(CELL_SIZE.y),
                }

                if cell == .Mine {
                    rl.DrawRectangleRec(cellRec, rl.BLACK)
                    continue
                }

                if rl.CheckCollisionPointRec(mousePos, cellRec) {
                    rl.DrawRectangleRec(cellRec, CELL_HOVERED)
                } else {
                    rl.DrawRectangleRec(cellRec, CELL_COLOR1 if n % 2 == 0 else CELL_COLOR2)
                }

            }
        }

        rl.EndDrawing()
    }
}

get_cell_index :: proc{
    get_cell_index_by_pos,
    get_cell_index_by_xy,
}

get_cell_index_by_pos :: proc(position: rl.Vector2) -> i32 {
    dividedPos := [2]i32{
        i32(position.x) / CELL_SIZE.y,
        i32(position.y) / CELL_SIZE.y,
    }

    return dividedPos.x + CELLS_PER_ROW_AND_COLUM * dividedPos.y
}

get_cell_index_by_xy :: proc(x, y: int) -> int {
    return x + y * CELLS_PER_ROW_AND_COLUM
}

// This proc uses the Fisher-Yates Shuffle to generate the mines.
generate_field :: proc() {
    // i think padding is not a good name, but idc
    padding: u16
    for i in 0..<MINES {
        if grid[i] == .Empty do padding += 1
        grid[i+padding] = .Mine
    }

    for i in 1..=len(grid)-1 {
        if grid[len(grid)-i] == .Empty do continue

        randomIndex := rand.int_range(0, len(grid)-i)
        randomCell := grid[randomIndex]
        if randomCell == .Empty do continue

        grid[randomIndex] = grid[len(grid)-i]
        grid[len(grid)-i] = randomCell
    }

    game = .STARTED
}
