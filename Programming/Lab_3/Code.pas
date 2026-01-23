program Integral_ZZZ;
{$CODEPAGE UTF8}
uses crt;

type
  MenuState = (limits, step, calc, error, result);

var
  CurrentMenu: MenuState;
  a, b, h, integral, exact, AbsErr, RelErr: real;
  n: integer;
  DataEntered: array[1..5] of boolean;

function f(x: real): real;
begin
  f := x*x*x - 5*x + 8;
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
      3: if DataEntered[3] then write(' (S=', integral:0:5, ')');
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
  repeat
  repeat
  write('Левая граница (a): ');
  readln(a);
  if a < 0 then
    writeln('Значение должно быть >= 0');
  until a >= 0;
  repeat
  write('Правая граница (b): ');
  readln(b);
  if a >= b then
    writeln('Значение должно быть больше a');
  until b >= 0;
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
  h := (b - a) / n;
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
  sum: real;
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

  sum := 0;

  for i := 1 to n-1 do
  begin
    sum := sum + f(a + i*h)
  end;

  integral := (h/3) * (f(a) + f(b) + 4*sum + 2*sum);
  DataEntered[3] := true;
  DataEntered[4] := false;
  DataEntered[5] := false;

  clrscr;
  writeln('РАСЧЕТ ПЛОЩАДИ');
  writeln('----------------');
  writeln;
  writeln('Площадь: ', integral:0:5);
  writeln;
  writeln('Нажмите любую клавишу...');
  readkey;
end;

procedure CalculateError;
var
  i, xn: integer;
  sum, f_h: real;
begin
  if not DataEntered[3] then
  begin
    clrscr;
    writeln('Выполните расчет площади!');
    readkey;
    exit;
  end;

  xn := n;
  f_h := (b - a) / xn;
  sum := 0;

  for i := 1 to xn-1 do
  begin
    sum := sum + f(a + i*f_h)
  end;

  exact := f_h * ((f(a) + f(b))/2 + sum);

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
  writeln('Абсолютная: ', AbsErr:0:10);
  writeln('Относительная: ', RelErr*100:0:6, '%');
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
  writeln('Приближенная S: ', integral:0:5);
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