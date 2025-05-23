% Define the grid dimensions
grid(5, 5).

% Define fixed cells with their values
fixed_cell(1, 1, 4).
fixed_cell(3, 1, 1).
fixed_cell(3, 5, 1).
fixed_cell(5, 5, 6).

%fixed_cell(3, 1, 3).
%fixed_cell(1,3, 7).
%fixed_cell(5, 3, 1).
%fixed_cell(3, 5, 2).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Diagonally adjacent clues
set_walls_for_diagonal_clues(Grid, NewGrid) :-
    findall((X1, Y1, X2, Y2), diagonal_clues(X1, Y1, X2, Y2), DiagonalPairs),
    set_diagonal_walls(DiagonalPairs, Grid, NewGrid).

% Find all pairs of diagonally adjacent clues
diagonal_clues(X1, Y1, X2, Y2) :-
    fixed_cell(X1, Y1, _),
    fixed_cell(X2, Y2, _),
    abs(X1 - X2) =:= 1,
    abs(Y1 - Y2) =:= 1.

% Set walls for all diagonal pairs found
set_diagonal_walls([], Grid, Grid).
set_diagonal_walls([(X1, Y1, X2, Y2)|Rest], Grid, NewGrid) :-
    set_diagonal_wall(X1, Y1, X2, Y2, Grid, TempGrid),
    set_diagonal_walls(Rest, TempGrid, NewGrid).

% Set a wall for a pair of diagonally adjacent clues
set_diagonal_wall(X1, Y1, X2, Y2, Grid, NewGrid) :-
    (X1 < X2 -> (WallX1 is X1, WallY1 is Y2); (WallX1 is X2, WallY1 is Y1)),
    (Y1 < Y2 -> (WallX2 is X2, WallY2 is Y1); (WallX2 is X1, WallY2 is Y2)),
    set_cell(WallX1, WallY1, b, Grid, TempGrid1),
    set_cell(WallX2, WallY2, b, TempGrid1, NewGrid).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Island of 1
set_b_around_one(Grid, NewGrid) :-
    findall((X, Y), fixed_cell(X, Y, 1), Ones),
    set_b_around_ones(Ones, Grid, NewGrid).

set_b_around_ones([], Grid, Grid).
set_b_around_ones([(X, Y)|Rest], Grid, NewGrid) :-
    set_b_around_one(X, Y, Grid, TempGrid),
    set_b_around_ones(Rest, TempGrid, NewGrid).

set_b_around_one(X, Y, Grid, NewGrid) :-
    grid(Width, Height),
    X1 is X - 1, X2 is X + 1,
    Y1 is Y - 1, Y2 is Y + 1,
    (X1 > 0 -> set_cell(X1, Y, b, Grid, TempGrid1); TempGrid1 = Grid),
    (X2 =< Width -> set_cell(X2, Y, b, TempGrid1, TempGrid2); TempGrid2 = TempGrid1),
    (Y1 > 0 -> set_cell(X, Y1, b, TempGrid2, TempGrid3); TempGrid3 = TempGrid2),
    (Y2 =< Height -> set_cell(X, Y2, b, TempGrid3, NewGrid); NewGrid = TempGrid3).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Clues separated by one square
set_walls_between_clues(Grid, NewGrid) :-
    findall((X1, Y1, X2, Y2), separated_by_one_square(X1, Y1, X2, Y2), Pairs),
    set_walls(Pairs, Grid, NewGrid).

% Find all pairs of clues that are separated by one square
separated_by_one_square(X1, Y1, X2, Y2) :-
    fixed_cell(X1, Y1, _),
    fixed_cell(X2, Y2, _),
    (X1 == X2, Y2 is Y1 + 2; Y1 == Y2, X2 is X1 + 2).

% Set walls for all pairs found
set_walls([], Grid, Grid).
set_walls([(X1, Y1, X2, Y2)|Rest], Grid, NewGrid) :-
    set_wall(X1, Y1, X2, Y2, Grid, TempGrid),
    set_walls(Rest, TempGrid, NewGrid).

% Set a wall between two clues
set_wall(X1, Y1, X2, Y2, Grid, NewGrid) :-
    (X1 == X2 -> WallX is X1, WallY is Y1 + 1; WallX is X1 + 1, WallY is Y2),
    set_cell(WallX, WallY, b, Grid, NewGrid).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Surrounded squares
set_b_for_surrounded_squares(Grid, NewGrid) :-
    findall((X, Y), surrounded_square(X, Y, Grid), SurroundedSquares),
    set_cells_to_b(SurroundedSquares, Grid, NewGrid).

% Find all surrounded squares
surrounded_square(X, Y, Grid) :-
    grid(Width, Height),
    between(1, Width, X),
    between(1, Height, Y),
    \+ fixed_cell(X, Y, _), % Ensure its not a fixed cell
    is_surrounded(X, Y, Grid, Width, Height).

% Check if a cell is surrounded by walls horizontally and vertically
is_surrounded(X, Y, Grid, Width, Height) :-
    X1 is X - 1, X2 is X + 1,
    Y1 is Y - 1, Y2 is Y + 1,
    (X1 > 0 -> nth1(Y, Grid, Row), nth1(X1, Row, Cell1), Cell1 == b; true),
    (X2 =< Width -> nth1(Y, Grid, Row), nth1(X2, Row, Cell2), Cell2 == b; true),
    (Y1 > 0 -> nth1(Y1, Grid, Row1), nth1(X, Row1, Cell3), Cell3 == b; true),
    (Y2 =< Height -> nth1(Y2, Grid, Row2), nth1(X, Row2, Cell4), Cell4 == b; true).

% Set cells to 'b'
set_cells_to_b([], Grid, Grid).
set_cells_to_b([(X, Y)|Rest], Grid, NewGrid) :-
    set_cell(X, Y, b, Grid, TempGrid),
    set_cells_to_b(Rest, TempGrid, NewGrid).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

wall_expansion(Grid, NewGrid) :-
    findall((X, Y), expandable(X, Y, Grid), ExpandableCells),
    set_cells_to_b(ExpandableCells, Grid, NewGrid).

expandable(X, Y, Grid) :-
    grid(Width, Height),
    between(1, Width, X),
    between(1, Height, Y),
    \+ fixed_cell(X, Y, _),
    is_expandable(X, Y, Grid).

is_expandable(X, Y, Grid) :-
    adjacent_walls_count(X, Y, Grid, Count),
    Count >= 2.

adjacent_walls_count(X, Y, Grid, Count) :-
    findall(_, adjacent_wall(X, Y, Grid), Walls),
    length(Walls, Count).

adjacent_wall(X, Y, Grid) :-
    (X1 is X - 1, within_bounds(X1, Y, Grid), cell(X1, Y, b, Grid));
    (X2 is X + 1, within_bounds(X2, Y, Grid), cell(X2, Y, b, Grid));
    (Y1 is Y - 1, within_bounds(X, Y1, Grid), cell(X, Y1, b, Grid));
    (Y2 is Y + 1, within_bounds(X, Y2, Grid), cell(X, Y2, b, Grid)).

within_bounds(X, Y, Grid) :-
    length(Grid, Height),
    nth1(1, Grid, Row),
    length(Row, Width),
    X > 0, X =<Width,
    Y > 0, Y =< Height.

cell(X, Y, Value, Grid) :-
    nth1(Y, Grid, Row),
    nth1(X, Row, Value).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Expand islands from clues
expand_islands_from_clues(Grid, NewGrid) :-
findall((X, Y, Value), fixed_cell(X, Y, Value), Clues),
expand_clues(Clues, Grid, NewGrid).

% Expand each clue
expand_clues([], Grid, Grid).
expand_clues([(X, Y, Value)|Rest], Grid, NewGrid) :-
expand_clue(X, Y, Value, Grid, TempGrid),
expand_clues(Rest, TempGrid, NewGrid).

% Expand a single clue
expand_clue(X, Y, Value, Grid, NewGrid) :-
findall((X1, Y1), adjacent_free_cell(X, Y, X1, Y1, Grid), FreeCells),
length(FreeCells, FreeCount),
NeededExpansion is Value - 1, % Subtract 1 for the clue cell itself
(NeededExpansion =:= FreeCount -> % If the number of free cells matches the needed expansion
set_cells_to_island(FreeCells, Grid, NewGrid); % Set all free cells as part of the island
NewGrid = Grid % Otherwise, do not expand
).

% Find adjacent free cells
adjacent_free_cell(X, Y, X1, Y1, Grid) :-
adjacent(X, Y, X1, Y1),
within_bounds(X1, Y1, Grid),
cell(X1, Y1, Cell, Grid),
var(Cell).

% Set cells as part of an island
set_cells_to_island([], Grid, Grid).
set_cells_to_island([(X, Y)|Rest], Grid, NewGrid) :-
set_cell(X, Y, g, Grid, TempGrid),
set_cells_to_island(Rest, TempGrid, NewGrid).

adjacent(X, Y, X1, Y1) :-
(X1 is X + 1, Y1 is Y);    % Right cell
(X1 is X - 1, Y1 is Y);    % Left cell
(X1 is X, Y1 is Y + 1);    % Upper cell
(X1 is X, Y1 is Y - 1).    % Lower cell

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- discontiguous set_cells_to_island/3.
% Ensure island continuity and prevent 2x2 wall blocks
ensure_island_continuity(Grid, NewGrid) :-
    findall((X, Y), must_be_island(X, Y, Grid), MustBeIslandCells),
    set_cells_to_island(MustBeIslandCells, Grid, NewGrid).

% Find cells that must be part of an island to prevent 2x2 wall blocks
must_be_island(X, Y, Grid) :-
    grid(Width, Height),
    between(1, Width, X),
    between(1, Height, Y),
    check_2x2_wall(X, Y, Grid).

% Check for potential 2x2 wall formation
check_2x2_wall(X, Y, Grid) :-
    X1 is X + 1, Y1 is Y + 1,
    X2 is X - 1, Y2 is Y - 1,
    % Check the 2x2 block starting at (X, Y)
    ((cell(X, Y, b, Grid), cell(X1, Y, b, Grid), cell(X, Y1, b, Grid), var_or_empty(X1, Y1, Grid));
    (cell(X2, Y2, b, Grid), cell(X2, Y, b, Grid), cell(X, Y2, b, Grid), var_or_empty(X, Y, Grid))).

% Check if a cell is explicitly empty ('.') in the grid
var_or_empty(X, Y, Grid) :-
    within_bounds(X, Y, Grid),
    cell(X, Y, Cell, Grid),
    (var(Cell) ; Cell = '.').

% Helper to set cells as part of an island
set_cells_to_island([], Grid, Grid).
set_cells_to_island([(X, Y)|Rest], Grid, NewGrid) :-
    cell(X, Y, _, Grid),
    \+ fixed_cell(X, Y, _), % Ensure its not a fixed cell
    var_or_empty(X, Y, Grid), % Check if the cell is empty or unassigned
    set_cell(X, Y, g, Grid, TempGrid), % Set the cell as part of an island
    set_cells_to_island(Rest, TempGrid, NewGrid).

% Handle the case where the cell is not suitable for island placement
set_cells_to_island([_|Rest], Grid, NewGrid) :-
    set_cells_to_island(Rest, Grid, NewGrid).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check for wall continuity and prevent partitioning
ensure_wall_continuity(Grid, NewGrid) :-
findall((X, Y), must_be_wall(X, Y, Grid), MustBeWallCells),
set_cells_to_wall(MustBeWallCells, Grid, NewGrid).

% Find cells that must be part of a wall to prevent partitioning
must_be_wall(X, Y, Grid) :-
grid(Width, Height),
between(1, Width, X),
between(1, Height, Y),
cell(X, Y, Cell, Grid),
var(Cell), % Cell is unassigned
would_partition_wall(X, Y, Grid).

% Check if setting a cell as an island would partition a wall
would_partition_wall(X, Y, Grid) :-
% Check all four directions around the cell
adjacent(X, Y, X1, Y1),
adjacent(X, Y, X2, Y2),
X1 \= X2, Y1 \= Y2, % Ensure were checking different directions
cell(X1, Y1, Cell1, Grid), Cell1 == b,
cell(X2, Y2, Cell2, Grid), Cell2 == b,
% Check the two other cells that form a rectangle with the current cell
(X == X1 -> (OtherX is X2, OtherY1 is Y1, OtherY2 is Y2)
; (OtherX is X1, OtherY1 is Y2, OtherY2 is Y1)),
cell(OtherX, OtherY1, OtherCell1, Grid), var(OtherCell1),
cell(OtherX, OtherY2, OtherCell2, Grid), var(OtherCell2).

% Set cells as part of a wall
set_cells_to_wall([], Grid, Grid).
set_cells_to_wall([(X, Y)|Rest], Grid, NewGrid) :-
set_cell(X, Y, b, Grid, TempGrid), % 'b' denotes a wall cell
set_cells_to_wall(Rest, TempGrid, NewGrid).

wall(Grid, NewGrid) :-
findall((X, Y), condition_for_wall(X, Y, Grid), WallCells),
set_cells_to_wall(WallCells, Grid, NewGrid).

condition_for_wall(X, Y, Grid) :-
cell(X, Y, Cell, Grid), var(Cell),
adjacent(X, Y, X1, Y1),
adjacent(X, Y, X2, Y2),
X1 \= X2, Y1 \= Y2,
cell(X1, Y1, Cell1, Grid), Cell1 == b,
cell(X2, Y2, Cell2, Grid), Cell2 == b,
not(would_form_2x2_block(X, Y, Grid)).

would_form_2x2_block(X, Y, Grid) :-
grid(Width, Height),
between(1, Width, X),
between(1, Height, Y),
findall((XAdj, YAdj), adjacent_wall(X, Y, XAdj, YAdj, Grid), AdjacentWalls),
length(AdjacentWalls, NumAdjacentWalls),
NumAdjacentWalls >= 2,
% Check each combination of adjacent walls to see if a 2x2 block is formed
check_2x2_combinations(AdjacentWalls, X, Y, Grid).

% Check combinations of adjacent walls for 2x2 block formation
check_2x2_combinations(AdjacentWalls, X, Y, Grid) :-
member((X1, Y1), AdjacentWalls),
member((X2, Y2), AdjacentWalls),
X1 \= X2,
Y1 \= Y2,
% Determine the coordinates of the fourth cell that would complete the 2x2 block
(X1 == X -> OtherX = X2 ; OtherX = X1),
(Y1 == Y -> OtherY = Y2 ; OtherY = Y1),
% Check if the fourth cell is also a wall
cell(OtherX, OtherY, OtherCell, Grid),
OtherCell == b.

% Helper predicate to find adjacent walls
adjacent_wall(X, Y, XAdj, YAdj, Grid) :-
adjacent(X, Y, XAdj, YAdj),
cell(XAdj, YAdj, Cell, Grid),
Cell == b.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Surround a completed island with walls
surround_completed_islands(Grid, NewGrid) :-
    findall((X, Y), completed_island(X, Y, Grid), CompletedIslands),
    set_walls_around_islands(CompletedIslands, Grid, NewGrid).

% Find all completed islands
completed_island(X, Y, Grid) :-
    cell(X, Y, g, Grid), % Check if the cell is part of a completed island
    once(findall((X1, Y1), (adjacent(X, Y, X1, Y1), cell(X1, Y1, g, Grid)), IslandCells)), % Find all island cells
    length(IslandCells, IslandSize), % Get the island size
    fixed_cell(X, Y, Value), % Get the clue value of the island
    IslandSize == Value. % Check if the island size matches the clue value

% Set walls around each completed island
set_walls_around_islands([], Grid, Grid).
set_walls_around_islands([(X, Y)|Rest], Grid, NewGrid) :-
    set_walls_around_island(X, Y, Grid, TempGrid),
    set_walls_around_islands(Rest, TempGrid, NewGrid).

% Set walls around a single completed island
set_walls_around_island(X, Y, Grid, NewGrid) :-
    grid(Width, Height),
    X1 is X - 1, X2 is X + 1,
    Y1 is Y - 1, Y2 is Y + 1,
    (X1 > 0 -> set_cell(X1, Y, b, Grid, TempGrid1); TempGrid1 = Grid),
    (X2 =< Width -> set_cell(X2, Y, b, TempGrid1, TempGrid2); TempGrid2 = TempGrid1),
    (Y1 > 0 -> set_cell(X, Y1, b, TempGrid2, TempGrid3); TempGrid3 = TempGrid2),
    (Y2 =< Height -> set_cell(X, Y2, b, TempGrid3, NewGrid); NewGrid = TempGrid3).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Initialization
init_grid(Grid) :-
    grid(Width, Height),
    create_grid(Width, Height, Grid),
    print_grid(Grid),nl,print_grid_with_stars,

    set_fixed_cells(Grid, TempGrid1),
    print_grid(TempGrid1),nl,print_grid_with_stars,

    set_b_around_one(TempGrid1, TempGrid2),
    print_grid(TempGrid2),nl,print_grid_with_stars,

    set_walls_between_clues(TempGrid2, TempGrid3),
    print_grid(TempGrid3),nl,print_grid_with_stars ,

    set_walls_for_diagonal_clues(TempGrid3, TempGrid4),
    print_grid(TempGrid4),nl,print_grid_with_stars,

    set_b_for_surrounded_squares(TempGrid4, TempGrid5),
    print_grid(TempGrid5),nl,print_grid_with_stars ,

    ensure_island_continuity(TempGrid5, TempGrid6),
    print_grid(TempGrid6),nl,print_grid_with_stars ,

    expand_islands_from_clues(TempGrid6, TempGrid7),
    print_grid(TempGrid7),nl,print_grid_with_stars ,

    surround_completed_islands(TempGrid7, TempGrid8),
    print_grid(TempGrid8),nl,print_grid_with_stars ,

    set_b_around_one(TempGrid8, TempGrid9),
    print_grid(TempGrid9),nl,print_grid_with_stars ,

    wall_expansion(TempGrid9, TempGrid10),
    print_grid(TempGrid10),nl,print_grid_with_stars,

    ensure_wall_continuity(TempGrid10, TempGrid11),
    print_grid(TempGrid11),nl,print_grid_with_stars,

    finalize_grid(TempGrid11, TempGrid12),

    print_grid(TempGrid12), nl,
    wall(TempGrid12, NewGrid),print_grid_with_stars ,

    print_grid(NewGrid), nl,print_grid_with_stars.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
print_grid_with_stars :-
    write('******************'), nl,
    sleep(1).
finalize_grid(Grid, NewGrid) :-
    findall((X, Y), empty_cell(X, Y, Grid), EmptyCells),
    fill_remaining_cells(EmptyCells, Grid, NewGrid).

% Find all empty cells
empty_cell(X, Y, Grid) :-
    grid(Width, Height),
    between(1, Width, X),
    between(1, Height, Y),
    cell(X, Y, Cell, Grid),
    var(Cell). % Check if the cell is unbound (empty)

% Fill remaining cells with 'g'
fill_remaining_cells([], Grid, Grid).
fill_remaining_cells([(X, Y)|Rest], Grid, NewGrid) :-
    set_cell(X, Y, g, Grid, TempGrid),
    fill_remaining_cells(Rest, TempGrid, NewGrid).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Create an empty grid
create_grid(Width, Height, Grid) :-
    length(Grid, Height),
    maplist(create_row(Width), Grid).

create_row(Length, Row) :-
    length(Row, Length).

% Set fixed cells in the grid
set_fixed_cells(Grid, NewGrid) :-
    findall((X, Y, Value), fixed_cell(X, Y, Value), FixedCells),
    set_cells(FixedCells, Grid, NewGrid).

% Helper predicate to set all fixed cells
set_cells([], Grid, Grid).
set_cells([(X, Y, Value)|Rest], Grid, NewGrid) :-
    set_cell(X, Y, Value, Grid, TempGrid),
    set_cells(Rest, TempGrid, NewGrid).

% Set a specific cell in the grid
set_cell(X, Y, Value, Grid, NewGrid) :-
    nth1(Y, Grid, Row),
    replace_nth(X, Row, Value, NewRow),
    replace_nth(Y, Grid, NewRow, NewGrid).

% Replace the Nth element of a list
replace_nth(1, [_|Rest], Value, [Value|Rest]).
replace_nth(N, [H|Rest], Value, [H|NewRest]) :-
    N > 1,
    N1 is N - 1,
    replace_nth(N1, Rest, Value, NewRest).

% Print the grid
print_grid([]).
print_grid([Row|Rest]) :-
    print_row(Row),
    nl,
    print_grid(Rest).

print_row([]).
print_row([Cell|Rest]) :-
    ( var(Cell) -> write(' . ')
    ;  write(' '), write(Cell), write(' ')
    ),
    print_row(Rest).

% Main entry point
:- init_grid(_).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%الفصل الأول 

%fxd_cell(1, 3, 3).
%fxd_cell(3, 1, 7).
%fxd_cell(3, 5, 1).
%fxd_cell(5, 3, 2).
% خلايا الحل
%solve_cell(1, 1, green).
%solve_cell(1, 2, blue).
%solve_cell(1, 3, green).  % ثابتة
%solve_cell(1, 4, green).

%solve_cell(1, 5, green).

%solve_cell(2, 1, green).
%solve_cell(2, 2, blue).
%solve_cell(2, 3, blue).
%solve_cell(2, 4, blue).
%solve_cell(2, 5, blue).

%solve_cell(3, 1, green).  % ثابتة
%solve_cell(3, 2, green).
%solve_cell(3, 4, blue).
%solve_cell(3, 5, green).  % ثابتة

%solve_cell(4, 1, green).
%solve_cell(4, 2, blue).
%solve_cell(4, 3, blue).  % ثابتة
%solve_cell(4, 4, blue).
%solve_cell(4, 5, blue).

%solve_cell(5, 1, green).
%solve_cell(5, 2, blue).
%solve_cell(5, 3, green).  % ثابتة
%solve_cell(5, 4, green).
%solve_cell(5, 5, blue).

%same_color_neighbors(Row, Col, Color, Neighbors) :-
   %solve_cell(Row, Col, Color),
    %findall((R, C), (solve_cell(R, C, Color), adjacent(Row, Col, R, C)), Neighbors).

%adjacent(R1, C1, R2, C2) :-
    %(R1 = R2, abs(C1 - C2) =:= 1) ;  % نفس الصف والأعمدة مجاورة
    %(C1 = C2, abs(R1 - R2) =:= 1).  % نفس العمود والصفوف مجاورة
%find_connected_cells(Row, Col, Color, Cells) :-
    %find_connected_cells(Row, Col, Color, [], Cells).

%find_connected_cells(Row, Col, Color, Visited, Cells) :-
    %solve_cell(Row, Col, Color),
    %\+ member((Row, Col), Visited),
    %same_color_neighbors(Row, Col, Color, Neighbors),
    %append([(Row, Col)], Visited, NewVisited),
    %findall(SubCells, (
      %  member((R, C), Neighbors),
     %   find_connected_cells(R, C, Color, NewVisited, SubCells)), SubLists),
    %flatten(SubLists, FlattenedSubLists),
    %list_to_set([(Row, Col) | FlattenedSubLists], Cells).

%find_connected_cells(_, _, _, Cells, Cells).


%one_sea :-
    %solve_cell(Row, Col, blue),
    %find_connected_cells(Row, Col, blue, Sea),
    %forall(solve_cell(R, C, blue), member((R, C), Sea)).

%no_2_by_2_sea :-
   % \+ (solve_cell(Row, Col, blue),
       % solve_cell(Row, Col1, blue), Col1 is Col + 1,
      %  solve_cell(Row1, Col, blue), Row1 is Row + 1,
     %   solve_cell(Row1, Col1, blue)).



%one_fixed_cell_in_island :-
    %findall((Row, Col, Num), fxd_cell(Row, Col, Num), FixedCells),
    %forall(member((Row, Col, Num), FixedCells),
           %( find_connected_cells(Row, Col, green, Island),
            %include(is_fixed_cell_in_island, Island, FixedCellsInIsland),
           % length(FixedCellsInIsland, 1))).

%is_fixed_cell_in_island((Row, Col)) :-
    %fxd_cell(Row, Col, _).


% قاعدة للتحقق من أن عدد الخلايا في الجزيرة يساوي الرقم في الخلية الثابتة
%island_number_equals_size :-
    %findall((Row, Col, Num), fxd_cell(Row, Col, Num), FixedCells),
    %forall(member((Row, Col, Num), FixedCells),
      %     (find_connected_cells(Row, Col, green, Island),
     %       length(Island, Num))).







%solved :-
    %one_sea,
    %no_2_by_2_sea,
   % one_fixed_cell_in_island,
  %  island_number_equals_size.
%!  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

















