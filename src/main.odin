package CampoMinado

import "base:intrinsics"
import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

Cell :: enum u8 {
    None,
    Revealed,
    Mine,
    FlagedMine,
    Flag,
}

CELLS_PER_ROW_AND_COLUM :: 20
grid: [CELLS_PER_ROW_AND_COLUM * CELLS_PER_ROW_AND_COLUM]Cell
CELL_SIZE :: [2]i32{SCREEN_SIZE.x / CELLS_PER_ROW_AND_COLUM, SCREEN_SIZE.y / CELLS_PER_ROW_AND_COLUM}
MINES : u16 : 70

CELL_COLOR1     :: rl.Color{75, 255, 0, 255}
CELL_COLOR2     :: rl.Color{50, 200, 0, 255}
CELL_HOVERED    :: rl.Color{50, 180, 0, 255}

REVEALED_COLOR_BRIGHT :: rl.Color{179, 145, 87, 255}
REVEALED_COLOR_DARK :: rl.Color{145, 118, 71, 255}

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
    fmt.println(len(grid))
    rl.InitWindow(SCREEN_SIZE.x, SCREEN_SIZE.y, TITLE)
    defer rl.CloseWindow()
    rl.SetTargetFPS(30)

    for !rl.WindowShouldClose() {
        mousePos := rl.GetMousePosition()
        switch {
        case rl.IsMouseButtonPressed(.LEFT):
            cellIndex := get_cell_index(mousePos)
            #partial switch grid[cellIndex] {
            case .None:
                #partial switch game {
                case .UNITIALIZED:
                    grid[cellIndex] = .Revealed
                    generate_mines()
                case .STARTED:
                    reveal(get_cell_row_and_colum(mousePos))
                }
            case .Mine:
                game = .LOSE
            }
        case rl.IsMouseButtonPressed(.RIGHT) && game == .STARTED:
            cellIndex := get_cell_index(mousePos)
            #partial switch grid[cellIndex] {
            case .None:
                grid[cellIndex] = .Flag
            case .Mine:
                grid[cellIndex] = .FlagedMine
            case .FlagedMine:
                grid[cellIndex] = .Mine
            case .Flag:
                grid[cellIndex] = .None
            }
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

                #partial switch grid[get_cell_index(x, y)] {
                case .Mine:
                    rl.DrawRectangleRec(cellRec, rl.BLACK)
                case .Flag, .FlagedMine:
                    rl.DrawRectangleRec(cellRec, rl.RED)
                case .None:
                    if rl.CheckCollisionPointRec(mousePos, cellRec) {
                        rl.DrawRectangleRec(cellRec, CELL_HOVERED)
                    } else if n % 2 == 0 {
                        rl.DrawRectangleRec(cellRec, CELL_COLOR2)
                    }
                case .Revealed:
                    if n % 2 == 0 {
                        rl.DrawRectangleRec(cellRec, REVEALED_COLOR_DARK)
                        continue
                    }

                    rl.DrawRectangleRec(cellRec, REVEALED_COLOR_BRIGHT)
                }
            }
        }

        rl.EndDrawing()
    }
}

get_cell_index :: proc{
    get_cell_index_by_pos,
    get_cell_index_by_row_and_colum,
}

get_cell_index_by_pos :: #force_inline proc(position: [2]$T) -> int
    where intrinsics.type_is_numeric(T) {
    return get_cell_index_by_row_and_colum(get_cell_row_and_colum(position))
}

get_cell_index_by_row_and_colum :: #force_inline proc(row, colum: int) -> int {
    return min(row + ((colum - 1) * CELLS_PER_ROW_AND_COLUM if colum != 0 else 0), len(grid)-1)
}

get_cell_row_and_colum :: #force_inline proc(position: rl.Vector2) -> (x, y: int) {
    return  min(int(i32(position.x) / CELL_SIZE.x), CELLS_PER_ROW_AND_COLUM - 1),
            min(int(i32(position.y) / CELL_SIZE.y), CELLS_PER_ROW_AND_COLUM - 1)
}

reveal :: proc(row, colum: int) {
    if  row < 0 || row > CELLS_PER_ROW_AND_COLUM - 1 ||
        colum < 0 || colum > CELLS_PER_ROW_AND_COLUM - 1 {
        return
    }

    cell := &grid[get_cell_index(row, colum)]
    if cell^ != .None do return
    cell^ = .Revealed

    for offsetX := -1; offsetX <= 1; offsetX+=1 {
        for offsetY := -1; offsetY <= 1; offsetY+=1 {
            if  row + offsetX < 0 || row + offsetX > CELLS_PER_ROW_AND_COLUM - 1 ||
                colum + offsetY < 0 || colum + offsetY > CELLS_PER_ROW_AND_COLUM - 1 {
                continue
            }

            if grid[get_cell_index(row + offsetX, colum + offsetY)] == .Mine do return
        }
    }

    for offsetX := -1; offsetX <= 1; offsetX += 1 {
        for offsetY := -1; offsetY <= 1; offsetY += 1 {
            if offsetX == 0 && offsetY == 0 do continue
            reveal(row + offsetX, colum + offsetY)
        }
    }
}

// This proc uses the Fisher-Yates Shuffle to generate the mines.
generate_mines :: proc() #no_bounds_check {
    // i think padding is not a good name, but idc
    padding: u16
    for i in 0..<MINES {
        if grid[i] == .Revealed do padding += 1
        grid[i+padding] = .Mine
    }

    for i in 1..=len(grid)-1 {
        if grid[len(grid)-i] == .Revealed do continue

        randomIndex := rand.int_range(0, len(grid)-i)
        randomCell := grid[randomIndex]
        if randomCell == .Revealed do continue

        grid[randomIndex] = grid[len(grid)-i]
        grid[len(grid)-i] = randomCell
    }

    game = .STARTED
}
