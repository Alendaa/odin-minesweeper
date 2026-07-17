package CampoMinado

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

// TODO: change this to a bit_set so i can have two states per cell, like:
// Cell: Mine, Flag
Cell :: bit_set[enum u8 {
    None,
    Empty,
    Mine,
    Flag,
}]

CELLS_PER_ROW_AND_COLUM :: 20
grid: [CELLS_PER_ROW_AND_COLUM * CELLS_PER_ROW_AND_COLUM]Cell
CELL_SIZE :: [2]i32{SCREEN_SIZE.x / CELLS_PER_ROW_AND_COLUM, SCREEN_SIZE.y / CELLS_PER_ROW_AND_COLUM}
MINES : u16 : 70

CELL_COLOR1     :: rl.Color{75, 255, 0, 255}
CELL_COLOR2     :: rl.Color{50, 200, 0, 255}
CELL_HOVERED    :: rl.Color{50, 180, 0, 255}

SCREEN_SIZE :: [2]i32{600, 600}
TITLE : cstring : "Campo minado"

GameState :: enum u8 {
    UNITIALIZED,
    STARTED,
    FINISHED,
    LOSE,
}

game := GameState.UNITIALIZED

main :: proc() {
    for &v in grid {
        v = {.None}
    }

    rl.InitWindow(SCREEN_SIZE.x, SCREEN_SIZE.y, TITLE)
    defer rl.CloseWindow()
    rl.SetTargetFPS(30)

    for !rl.WindowShouldClose() {

        mousePos := rl.GetMousePosition()

        switch {
        case rl.IsMouseButtonPressed(.LEFT):
            cellIndex := get_cell_index(mousePos)
            switch grid[cellIndex] {
            case {.None}:
                #partial switch game {
                case .UNITIALIZED:
                    grid[cellIndex] = {.Empty}
                    generate_field()
                }
            case {.Mine}:
                game = .LOSE
            }
        case rl.IsMouseButtonPressed(.RIGHT) && game == .STARTED:
            cellIndex := get_cell_index(mousePos)
            switch {
            case .Flag in grid[cellIndex]:
                grid[cellIndex] -= {.Flag}
            case grid[cellIndex] == {.Mine} || grid[cellIndex] == {.None}:
                grid[cellIndex] += {.Flag}
            }
            fmt.println(grid[cellIndex])
        }

        rl.BeginDrawing()
        rl.ClearBackground(CELL_COLOR1)
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

                switch {
                case .Flag in cell:
                    rl.DrawRectangleRec(cellRec, rl.RED)
                case cell == {.Mine}:
                    rl.DrawRectangleRec(cellRec, rl.BLACK)
                case:
                    if rl.CheckCollisionPointRec(mousePos, cellRec) {
                        rl.DrawRectangleRec(cellRec, CELL_HOVERED)
                    } else if n % 2 == 0 {
                        rl.DrawRectangleRec(cellRec, CELL_COLOR2)
                    }
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

    return min(dividedPos.x + CELLS_PER_ROW_AND_COLUM * dividedPos.y, len(grid)-1)
}

get_cell_index_by_xy :: proc(x, y: int) -> int {
    return x + y * CELLS_PER_ROW_AND_COLUM
}

// This proc uses the Fisher-Yates Shuffle to generate the mines.
generate_field :: proc() {
    // i think padding is not a good name, but idc
    padding: u16
    for i in 0..<MINES {
        if grid[i] == {.Empty} do padding += 1
        grid[i+padding] = {.Mine}
    }

    for i in 1..=len(grid)-1 {
        if grid[len(grid)-i] == {.Empty} do continue

        randomIndex := rand.int_range(0, len(grid)-i)
        randomCell := grid[randomIndex]
        if randomCell == {.Empty} do continue

        grid[randomIndex] = grid[len(grid)-i]
        grid[len(grid)-i] = randomCell
    }

    game = .STARTED
}
