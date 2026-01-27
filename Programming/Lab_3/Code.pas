program Integral_ZZZ;
{$CODEPAGE UTF8}
uses crt;

type
  MenuState = (limits, step, calc, error, result);

var
  CurrentMenu: MenuState;
  a, b, h, integral, S, exact, AbsErr, RelErr: double;
  n: integer;
  DataEntered: array[1..5] of boolean;

  function f(x: double): double;
  begin
    f := x*x*x - 5*x + 8;
  end;

  function p(x: double): double;
  var
    y: double;
  begin
    y := x*x*x - 5*x + 8;
    if y < 0 then
      p := 0
    else
      p := y;
  end;

procedure DrawMenu;
var
  i: integer;
  MenuItems: array[1..5] of string;
begin
  clrscr;
  writeln('========================================');
  writeln('      ВЫЧИСЛЕНИЕ ПЛОЩАДИ ФИГУРЫ      ');
  writeln('========================================');
  writeln;

  MenuItems[1] := 'Ввод пределов интегрирования';
  MenuItems[2] := 'Ввод количества разбиений';
  MenuItems[3] := 'Расчет площади';
  MenuItems[4] := 'Расчет погрешности';
  MenuItems[5] := 'Вывод результата';

  for i := 1 to 5 do
  begin
    write('  ');
    if CurrentMenu = MenuState(i-1) then
      write('> ')
    else
      write('  ');

    write(MenuItems[i]);

    case i of
      1: if DataEntered[1] then write(' (a=', a:0:2, ', b=', b:0:2, ')');
      2: if DataEntered[2] then write(' (n=', n, ')');
      3: if DataEntered[3] then write(' (S=', S:0:5, ')');
      4: if DataEntered[4] then write(' (Отн=', RelErr*100:0:2, '%)');
      5: if DataEntered[5] then write(' (OK)');
    end;

    writeln;
  end;

  writeln;
  writeln('========================================');
  writeln('Навигация: Up/Down - выбор, Enter - выполнить');
  writeln('ESC - выход из программы');
  writeln('========================================');
  writeln;
  writeln('Функция: f(x) = x^3 - 5x + 8');
end;

procedure InputLimits;
begin
  clrscr;
  writeln('ВВОД ПРЕДЕЛОВ ИНТЕГРИРОВАНИЯ');
  writeln('------------------------------');
  writeln;
  write('Левая граница (a): ');
  readln(a);
  repeat
  write('Правая граница (b): ');
  readln(b);
  if a >= b then
    writeln('Значение должно быть больше a');
  until a < b;
  DataEntered[1] := true;
  DataEntered[4] := false;
  DataEntered[5] := false;
  writeln;
  writeln('OK. Нажмите любую клавишу...');
  readkey;
end;

procedure InputStep;
begin
  clrscr;
  writeln('ВВОД КОЛИЧЕСТВА РАЗБИЕНИЙ');
  writeln('--------------------------');
  writeln;
  repeat
    write('Количество разбиений (четное): ');
    readln(n);
    if n <= 0 then
      writeln('Ошибка: n > 0')
    else if n mod 2 <> 0 then
      writeln('Ошибка: требуется четное n');
  until (n > 0) and (n mod 2 = 0);
  DataEntered[2] := true;
  DataEntered[4] := false;
  DataEntered[5] := false;
  writeln;
  writeln('OK. Нажмите любую клавишу...');
  readkey;
end;

procedure CalculateIntegral;
var
  i: integer;
  sum, sum1: double;
begin
  if not DataEntered[1] then
  begin
    clrscr;
    writeln('Введите пределы интегрирования!');
    readkey;
    exit;
  end;

  if not DataEntered[2] then
  begin
    clrscr;
    writeln('Введите количество разбиений!');
    readkey;
    exit;
  end;

  h := (b - a) / n;
  sum := 0;
  sum1 := 0;
  for i := 1 to n-1 do
  begin
    if i mod 2 <> 0 then
      begin
      sum := sum + 4 * f(a + i*h);
      sum1 := sum1 + 4 * p(a + i*h);
      end
    else
      begin
      sum := sum + 2 * f(a + i*h);
      sum1 := sum1 + 2 * p(a + i*h);
      end;
  end;
  integral := (h/3) * (f(a) + f(b) + sum);
  S := (h/3) * (p(a) + p(b) + sum1);
  DataEntered[3] := true;
  DataEntered[4] := false;
  DataEntered[5] := false;

  clrscr;
  writeln('РАСЧЕТ ПЛОЩАДИ');
  writeln('----------------');
  writeln;
  writeln('Площадь: ', S:0:5);

  writeln;
  writeln('Нажмите любую клавишу...');
  readkey;
end;

procedure CalculateError;
var
  F_a, F_b: double;
begin
  if not DataEntered[3] then
  begin
    clrscr;
    writeln('Выполните расчет площади!');
    readkey;
    exit;
  end;

  F_a := (a*a*a*a)/4 - (5/2)*a*a + 8*a;
  F_b := (b*b*b*b)/4 - (5/2)*b*b + 8*b;
  exact := F_b - F_a;
  AbsErr := abs(exact - integral);

  if exact <> 0 then
    RelErr := AbsErr / abs(exact)
  else
    RelErr := 0;

  DataEntered[4] := true;

  clrscr;
  writeln('РАСЧЕТ ПОГРЕШНОСТИ');
  writeln('------------------');
  writeln;
  writeln('Абсолютная: ', AbsErr:0:5);
  writeln('Относительная: ', RelErr*100:0:5, '%');
  writeln;
  writeln('Нажмите любую клавишу...');
  readkey;
end;

procedure ShowResult;
begin
  if not DataEntered[4] then
  begin
    clrscr;
    writeln('Выполните расчет погрешности!');
    readkey;
    exit;
  end;

  DataEntered[5] := true;

  clrscr;
  writeln('ИТОГОВЫЙ РЕЗУЛЬТАТ');
  writeln('------------------');
  writeln;
  writeln('Пределы: [', a:0:2, ', ', b:0:2, ']');
  writeln('Кол-во разбиений: ', n);
  writeln('Шаг: ', h:0:5);
  writeln;
  writeln('Точное значение: ', exact:0:5);
  writeln('Вычисленное значение: ', integral:0:5);
  writeln('Приближенная S: ', S:0:5);
  writeln('Абсолют. погр.: ', AbsErr:0:5);
  writeln('Относ. погр.: ', (RelErr*100):0:5, '%');
  writeln;
  writeln('Нажмите любую клавишу...');
  readkey;
end;

procedure HandleMenu;
var
  ch: char;
begin
  repeat
    DrawMenu;
    ch := readkey;

    case ch of
      #0: begin
        ch := readkey;
        case ch of
          #72: begin
            if CurrentMenu = limits then
              CurrentMenu := result
            else
              CurrentMenu := pred(CurrentMenu);
          end;
          #80: begin
            if CurrentMenu = result then
              CurrentMenu := limits
            else
              CurrentMenu := succ(CurrentMenu);
          end;
        end;
      end;
      #13: case CurrentMenu of
        limits: InputLimits;
        step: InputStep;
        calc: CalculateIntegral;
        error: CalculateError;
        result: ShowResult;
      end;
    end;
  until ch = #27;
end;

begin
  clrscr;
  CurrentMenu := limits;
  for n := 1 to 5 do DataEntered[n] := false;

  a := 0;
  b := 0;
  n := 0;

  HandleMenu;

  clrscr;
end.