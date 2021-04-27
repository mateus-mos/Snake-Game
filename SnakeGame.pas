program SnakeGame;
{$modeSwitch advancedRecords}
uses Crt;
type 
    type_food = record
	    Point:integer;
	    ID:integer;
	    Icon:char;
	    Color:integer;
	end;
const 
    (* Map *)
    MAP_SIZE = 30;
    WALL = 5; 
    NOTHING = 0;
    GAME_COLOR = 11;
    (* Wall Icon *)
    WALL_HORIZONTAL_TOP = '▄';
    WALL_HORIZONTAL_BOTTOM = '▀';
    WALL_VERTICAL = '▒';
    (* Movimentation *)
    time_delay = 100;
    UP = -1;
    DOWN = -2;
    RIGHT = -3;
    LEFT = -4;
    (* Body Icon *)
    BODY_HORIZONTAL = '═';
    BODY_VERTICAL = '║';
    BODY_UPRIGHT = '╔';
    BODY_UPLEFT = '╗';
    BODY_DOWNRIGHT = '╚';
    BODY_DOWNLEFT = '╝';
    BODY_COLOR = WHITE;
    (* Food *)
    (* See section Constant record *)
    (* https://wiki.freepascal.org/Record *)
    (* FOOD ID Start in 301 *)
    FOOD: array of type_food = ( 
	(* The first food has to be a positive point food *)
	(point: 1;ID: 301;Icon:'@';Color:GREEN),
	(point: -1;ID: 302;Icon:'%';Color:RED),
	(point: -1;ID: 304;Icon:'*';Color:RED)
    );

type
    type_coord = record
	lin,col:integer;
    end;
    
    type_game = record 
	snake: record
	    head,tail:type_coord;
	end;
	map: array [1..MAP_SIZE,1..MAP_SIZE] of integer;
	score:integer;
    end;


procedure change_score(var game:type_game; x:integer);
(* Sum x to the score. X can be either negative or positive *)
begin
    game.score:=game.score+x;
end;


function RandomFreeSpace(var game:type_game):type_coord;
begin
    RandomFreeSpace.lin:=random(MAP_SIZE)+1;
    RandomFreeSpace.col:=random(MAP_SIZE)+1;

   while game.map[RandomFreeSpace.lin,RandomFreeSpace.col] <> NOTHING do
	begin
	    RandomFreeSpace.lin:=random(MAP_SIZE)+1;
	    RandomFreeSpace.col:=random(MAP_SIZE)+1;
	end;

end;

procedure create_food(var game:type_game; CreatePosFood:boolean);
(* Create a new food in a random place *)
(* IF CreatePosFood = TRUE then the program will be forced *)
(* to create a positive food *)
var 
    i:integer;
    Coord:type_coord;
begin
    if CreatePosFood then
	begin
	    (* Create a random positive food*)
	    Coord:=RandomFreeSpace(game);
	    i:=random(length(FOOD));
	    while FOOD[i].POINT < 0 do
		i:=random(length(FOOD));
	    game.map[Coord.lin,Coord.col]:=FOOD[i].ID;
	end;

    if random(5) <=2  then
	begin
	    (* Create a random positive food*)
	    Coord:=RandomFreeSpace(game);
	    i:=random(length(FOOD));
	    while FOOD[i].POINT > 0 do
		i:=random(length(FOOD));
	    game.map[Coord.lin,Coord.col]:=FOOD[i].ID;
	end;
end;

function next_position(var game:type_game; action,lin,col:integer):type_coord;
(* Calculate the next position if the action is executed *)
begin
    case action of 
	UP:begin
	    next_position.lin:=lin-1;
	    next_position.col:=col;
	end;
	DOWN:begin
	    next_position.lin:=lin+1;
	    next_position.col:=col;
	end;
	RIGHT:begin
	    next_position.lin:=lin;
	    next_position.col:=col+1;
	end;
	LEFT:begin
	    next_position.lin:=lin;
	    next_position.col:=col-1;
	end;
    end;
end;

function ValidAction(var game:type_game; action,lin,col:integer):boolean;
(* Verify if the action is invalid like the snake turn off in him-self *)
var x:type_coord;
begin
    ValidAction:=true;
    if (game.map[lin,col]<=-1)and(game.map[lin,col]<>WALL) then
	begin
	    x:=next_position(game,game.map[lin,col],lin,col);
	    if (x.lin = game.snake.head.lin)and(x.col = game.snake.head.col) then
		ValidAction:=false;
	end;
end;

procedure increase_body(var game:type_game; nex_pos:type_coord; action:integer);
begin
    game.map[game.snake.head.lin,game.snake.head.col]:=action;(* this body part will point to the new position of the body *)
    game.map[nex_pos.lin,nex_pos.col]:=action;(*Create a new Head *)
    game.snake.head:=nex_pos;
end;

procedure decrease_body(var game:type_game);
var action:integer;
begin
    action:=game.map[game.snake.tail.lin,game.snake.tail.col];(* Get where the next part of the body is*)
    game.map[game.snake.tail.lin,game.snake.tail.col]:=NOTHING;
    game.snake.tail:=next_position(game,action,game.snake.tail.lin,game.snake.tail.col);
end;

procedure move_snake(var game:type_game; nex_pos:type_coord; action:integer);
begin
    (*Create a new head *)
    increase_body(game,nex_pos,action);

    action:=game.map[game.snake.tail.lin,game.snake.tail.col];(* Get where the next part of the body is*)
    game.map[game.snake.tail.lin,game.snake.tail.col]:=NOTHING;
    game.snake.tail:=next_position(game,action,game.snake.tail.lin,game.snake.tail.col);
end;

procedure ate_food(var game:type_game; id_food,action:integer; nex_pos:type_coord);
var 
    i:integer;
begin
    i:=0;
    while FOOD[i].ID <> id_food do
	i:=i+1;

    change_score(game,FOOD[I].POINT);

    if FOOD[i].POINT > 0 then
	begin
	    (* The snake gain a point and increase *)
	    increase_body(game,nex_pos,action);
	    create_food(game,TRUE);
	end
    else
	begin
	    create_food(game,FALSE);
	    decrease_body(game);
	    game.map[nex_pos.lin,nex_pos.col]:=NOTHING;
	    (* The snake has to be moved, otherwise, the player *)
	    (* will have the impression of the snake stop for a moment *)
	    move_snake(game,nex_pos,action);
	end;
end;

function aply_action(var game:type_game; action:integer):boolean;
(* Return FALSE if the game end *)
(* Return TRUE if the game continue *)
var 
    nex_pos:type_coord;
    map_element:integer;
begin
    aply_action:=TRUE;
    (* Calculate the next position to test if the move is valid *)
    nex_pos:=next_position(game,action,game.snake.head.lin,game.snake.head.col);
    if ValidAction(game,action,nex_pos.lin,nex_pos.col) then
	begin
	    map_element:=game.map[nex_pos.lin,nex_pos.col]; 
	    if  map_element = WALL then 
		aply_action:=FALSE
	    else if (map_element>=-4)and(map_element <=-1) then 
		aply_action:=FALSE
	    else if map_element>=301 then (* It is a food *)
		begin
		    ate_food(game,map_element,action,nex_pos);
		end
	    else
		move_snake(game,nex_pos,action);
	end;
end;

procedure initializing_game(var game:type_game);
var i,j:integer;
begin
    with game do
	begin
	    score:=0;

	    snake.head.lin:= MAP_SIZE div 2;
	    snake.head.col:= MAP_SIZE div 2;

	    snake.tail.lin:= (MAP_SIZE div 2);
	    snake.tail.col:= (MAP_SIZE div 2)-1;

	    for i:=1 to MAP_SIZE do
		for j:=1 to MAP_SIZE do 
		    if (j=1) or (j=MAP_SIZE) then
			map[i,j]:=WALL
		    else
			if (i=1) or (i=MAP_SIZE) then
			    map[i,j]:=WALL
			else
			    map[i,j]:=NOTHING;

	    map[snake.head.lin,snake.head.col]:=UP;
	    map[snake.tail.lin,snake.tail.col]:=RIGHT;

	end;
end;

procedure print_snake(var game:type_game; i,j:integer);
begin
    with game do 
	begin textcolor(BODY_COLOR);
	    if (i=snake.head.lin)and(j=snake.head.col) then
		write('¤')
	    (* Verify if have to print the corners of the body *)
	    else if ((map[i,j]=LEFT)and(map[i+1,j]=UP))or((map[i,j]=DOWN)and(map[i,j-1]=RIGHT))then
		write(BODY_UPLEFT)
	    else if ((map[i,j]=RIGHT)and(map[i+1,j]=UP))or((map[i,j]=DOWN)and(map[i,j+1]=LEFT))then
		write(BODY_UPRIGHT)
	    else if (map[i,j]=UP)and(map[i,j-1]=RIGHT)or((map[i,j]=LEFT)and(map[i-1,j]=DOWN))then
		write(BODY_DOWNLEFT)
	    else if (map[i,j]=RIGHT)and(map[i-1,j]=DOWN)or((map[i,j]=UP)and(map[i,j+1]=LEFT))then
		write(BODY_DOWNRIGHT)
	    else 
		(* Print horizontal/vertical parts *)
		case game.map[i,j] of
		    UP:write(BODY_VERTICAL);
		    DOWN:write(BODY_VERTICAL);
		    LEFT:write(BODY_HORIZONTAL);
		    RIGHT:write(BODY_HORIZONTAL);
		end;
	    textcolor(GAME_COLOR);
	end;
end;

procedure print_elements(var game:type_game; i,j:integer);
(* Print elements of the map, like walls, foods, etc *)
var k:integer;
begin
    case game.map[i,j] of
	NOTHING:write(' ');
	WALL:begin
	    if i = 1 then 
		write(WALL_HORIZONTAL_TOP)
	    else if i = MAP_SIZE then   
		write(WALL_HORIZONTAL_BOTTOM)
	    else
	       write(WALL_VERTICAL);
        end
	else 
	    begin
		k:=0;
		while FOOD[k].ID <> game.map[i,j] do
		    k:=k+1;
		textcolor(FOOD[k].COLOR);
		write(FOOD[k].ICON);
		textcolor(GAME_COLOR);
	    end;
    end;
end;

procedure print_map(var game:type_game);
var 
i,j:integer;
begin
    for i:=1 to MAP_SIZE do
	begin
	    for j:=1 to MAP_SIZE do
		begin
		    if game.map[i,j]<0 then
			print_snake(game,i,j)
		    else
			print_elements(game,i,j);
		end;
	    writeln;
	end;
    end;

procedure print_rules();
begin
    writeln;
    write('Eat ');
    textcolor(GREEN);
    write('Green Food ');
    textColor(GAME_COLOR);
    write('to earn points and make the snake longer.');

    writeln;

    write('Avoid ');
    textcolor(RED);
    write('Red Food ');
    textColor(GAME_COLOR);
    write(', otherwise, you will lose points and make the snake shorter.');

    writeln;

    writeln('Use the arrow keys to move.');

end;

var 
    game:type_game;
    game_continue:boolean;
    ch:char;
begin
    randomize;
    ClrScr;
    textColor(GAME_COLOR);

    initializing_game(game);
    create_food(game,TRUE);
    print_map(game);

    writeln('Press any key to start');
    writeln;
    print_rules();
    repeat
    until KeyPressed;

    game_continue:=TRUE;
    repeat 
	ClrScr;

	writeln('SCORE: ',game.score);
	print_map(game);

	Delay(time_delay);

	if keypressed then
	    begin
		ch:=ReadKey;
		case ch of
		    #0:begin
			    ch:=ReadKey;
			    case ch of
				#72:game_continue:=aply_action(game,UP);
				#80:game_continue:=aply_action(game,DOWN);
				#75:game_continue:=aply_action(game,LEFT);
				#77:game_continue:=aply_action(game,RIGHT);
			    end;
			end;
		    #27:game_continue:=true;
		    end;
	    end
	else
	    (* Keep the snake moving if the player does not press a key *)
	    game_continue:=aply_action(game,game.map[game.snake.head.lin,game.snake.head.col]);

	if game.score = -1 then
	    game_continue:=false;

	while keypressed do
	    ch:=ReadKey;
    until game_continue = false;
end.
