uses GraphABC, Events, Timers;

const 
  OBJ_COUNT = 7; 
  ENEMY_COUNT = 4;
  SPIKE_COUNT = 10;
  COIN_COUNT = 15;

var 
  x, y: integer; 
  steps, score: integer; 
  level: integer := 1;
  gName: string; 
  gColor: Color; 
  obsX, obsY: array[1..OBJ_COUNT] of integer; 
  coinX, coinY: array[1..COIN_COUNT] of integer; 
  spkX, spkY: array[1..SPIKE_COUNT] of integer;
  coinActive: array[1..COIN_COUNT] of boolean; 
  enX: array[1..ENEMY_COUNT] of real; 
  enBaseY: array[1..ENEMY_COUNT] of integer; 
  angle: real; 
  syncObj: object := new object; 
  gameOver: boolean := false; 
  gameTimer: Timer;
  immortalTime: integer := 0;
  bonusTimer: Timer;

procedure StartLevel; forward;

procedure DrawGamer;
begin
  lock(syncObj) do begin
    LockDrawing;
    ClearWindow;
    SetBrushColor(clGray);
    for var i := 1 to OBJ_COUNT do FillRectangle(obsX[i], obsY[i], obsX[i] + 60, obsY[i] + 60);
    SetBrushColor(clBlack);
    for var i := 1 to SPIKE_COUNT do FillPie(spkX[i], spkY[i], 15, 0, 180);
    SetBrushColor(clYellow);
    for var i := 1 to COIN_COUNT do if coinActive[i] then FillCircle(coinX[i], coinY[i], 10);
    SetBrushColor(clRed);
    for var i := 1 to ENEMY_COUNT do FillCircle(Round(enX[i]), enBaseY[i] + Round(sin(angle + i) * 60), 15);
    
    if immortalTime > 0 then SetBrushColor(clCyan) else SetBrushColor(gColor);
    FillRectangle(x, y, x + 40, y + 40);
    
    SetFontColor(clBlack); SetFontSize(10);
    TextOut(10, 10, $'Игрок: {gName} | Уровень: {level} | Собрано: {score}/{COIN_COUNT}');
    if immortalTime > 0 then begin
      SetFontColor(clBlue);
      TextOut(10, 30, $'БЕССРМЕРТИЕ: {immortalTime} сек.');
    end;

    if (score = COIN_COUNT) and (level < 2) then begin
      level := 2; StartLevel; exit;
    end else if (score = COIN_COUNT) and (level = 2) then begin
      SetFontSize(30); SetFontColor(clGreen);
      TextOut(WindowWidth div 2 - 100, WindowHeight div 2, 'ПОБЕДА!');
      gameTimer.Stop; bonusTimer.Stop;
    end;
    if gameOver then begin
      SetFontSize(30); SetFontColor(clRed);
      TextOut(WindowWidth div 2 - 120, WindowHeight div 2, 'ПОРАЖЕНИЕ!');
      gameTimer.Stop; bonusTimer.Stop;
    end;
    Redraw;
  end;
end;

function IsOnObstacle(px, py: integer): boolean;
begin
  Result := false;
  for var i := 1 to OBJ_COUNT do
    if (px + 15 > obsX[i]) and (px - 15 < obsX[i] + 60) and (py + 15 > obsY[i]) and (py - 15 < obsY[i] + 60) then Result := true;
end;

function IsOnSpike(cx, cy: integer): boolean;
begin
  Result := false;
  for var i := 1 to SPIKE_COUNT do
    if Sqrt(Sqr(cx - spkX[i]) + Sqr(cy - spkY[i])) < 25 then Result := true;
end;

procedure CheckDeath;
begin
  if immortalTime > 0 then exit;
  for var i := 1 to ENEMY_COUNT do begin
    var ex := Round(enX[i]);
    var ey := enBaseY[i] + Round(sin(angle + i) * 60);
    if (ex > x) and (ex < x + 40) and (ey > y) and (ey < y + 40) then gameOver := true;
  end;
  for var i := 1 to SPIKE_COUNT do
    if (spkX[i] + 12 > x) and (spkX[i] - 12 < x + 40) and (spkY[i] + 12 > y) and (spkY[i] - 12 < y + 40) then gameOver := true;
end;

procedure MoveEnemies;
begin
  angle += 0.1;
  var speed := if level = 2 then 7 else 4;
  for var i := 1 to ENEMY_COUNT do begin
    enX[i] += speed;
    if enX[i] > WindowWidth then enX[i] := -20;
  end;
  CheckDeath;
  DrawGamer;
end;

procedure UpdateBonus;
begin
  if immortalTime > 0 then immortalTime -= 1;
end;

procedure KeyDown(key: integer);
begin
  if gameOver then Halt;
  var oldX := x; var oldY := y;
  case key of
    VK_Left: if x > 0 then x -= 10;
    VK_Right: if x < WindowWidth - 40 then x += 10;
    VK_Up: if y > 0 then y -= 10;
    VK_Down: if y < WindowHeight - 40 then y += 10;
  end;
  for var i := 1 to OBJ_COUNT do
    if (x + 40 > obsX[i]) and (x < obsX[i] + 60) and (y + 40 > obsY[i]) and (y < obsY[i] + 60) then begin
      x := oldX; y := oldY;
    end;
  for var i := 1 to COIN_COUNT do
    if coinActive[i] and (coinX[i] > x) and (coinX[i] < x + 40) and (coinY[i] > y) and (coinY[i] < y + 40) then begin
      coinActive[i] := false; score += 1;
    end;
  CheckDeath;
end;

procedure StartLevel;
begin
  x := 400; y := 300; score := 0; immortalTime := 40;
  for var i := 1 to ENEMY_COUNT do begin enX[i] := Random(0, 800); enBaseY[i] := Random(100, 500); end;
  for var i := 1 to OBJ_COUNT do repeat obsX[i] := Random(50, 700); obsY[i] := Random(50, 500); until Abs(obsX[i]-x)>80;
  for var i := 1 to SPIKE_COUNT do repeat spkX[i] := Random(50, 750); spkY[i] := Random(50, 550); until not IsOnObstacle(spkX[i], spkY[i]) and (Abs(spkX[i]-x) > 100);
  for var i := 1 to COIN_COUNT do repeat coinX[i] := Random(50, 750); coinY[i] := Random(50, 550); until not IsOnObstacle(coinX[i], coinY[i]) and not IsOnSpike(coinX[i], coinY[i]);
  for var i := 1 to COIN_COUNT do coinActive[i] := true;
end;

begin
  Print('Имя: '); readln(gName);
  gColor := clBlue;
  SetWindowSize(800, 600); CenterWindow;
  StartLevel;
  OnKeyDown := KeyDown;
  gameTimer := new Timer(40, MoveEnemies); gameTimer.Start;
  bonusTimer := new Timer(1000, UpdateBonus); bonusTimer.Start;
end.
