program FIFO;
{$CODEPAGE UTF8}
uses crt;

type
  MenuState = (addItem, removeItem, showQueue, clearQueue, exitProgram);
  PNode = ^TNode;
  TNode = record
    data: integer;
    next: PNode;
  end;

var
  CurrentMenu: MenuState;
  queueHead, queueTail: PNode;
  queueSize: integer;

procedure DrawMenu;
var
  i: integer;
  MenuItems: array[1..5] of string;
begin
  clrscr;
  writeln('========================================');
  writeln('          ДИНАМИЧЕСКАЯ ОЧЕРЕДЬ         ');
  writeln('========================================');
  writeln;

  MenuItems[1] := 'Добавить элемент в очередь';
  MenuItems[2] := 'Удалить элемент из очереди';
  MenuItems[3] := 'Показать очередь';
  MenuItems[4] := 'Очистить очередь';
  MenuItems[5] := 'Выход из программы';

  for i := 1 to 5 do
  begin
    write('  ');
    if CurrentMenu = MenuState(i-1) then
      write('> ')
    else
      write('  ');

    write(MenuItems[i]);

    case i of
      3: write(' (Размер: ', queueSize, ')');
      4: if queueSize > 0 then write(' (Очистить ', queueSize, ' элементов)');
      5: write('');
    end;

    writeln;
  end;

  writeln;
  writeln('========================================');
  writeln('Управление: Up/Down - выбор, Enter - выполнить');
  writeln('ESC - выход из программы');
  writeln('========================================');
  writeln;
  writeln('Очередь: FIFO (First In - First Out)');
end;

procedure Enqueue(value: integer);
var
  newNode: PNode;
begin
  new(newNode);
  newNode^.data := value;
  newNode^.next := nil;

  if queueTail = nil then
  begin
    // Очередь пуста
    queueHead := newNode;
    queueTail := newNode;
  end
  else
  begin
    // Добавляем в конец
    queueTail^.next := newNode;
    queueTail := newNode;
  end;

  inc(queueSize);
end;

function Dequeue: integer;
var
  tempNode: PNode;
begin

  Result := queueHead^.data;
  tempNode := queueHead;
  queueHead := queueHead^.next;

  if queueHead = nil then
    queueTail := nil;

  dispose(tempNode);
  dec(queueSize);
end;

procedure DisplayQueue;
var
  current: PNode;
  i: integer;
begin
  clrscr;
  writeln('СОДЕРЖИМОЕ ОЧЕРЕДИ');
  writeln('==================');
  writeln;

  if queueSize = 0 then
  begin
    writeln('Очередь пуста');
    writeln;
    writeln('Нажмите любую клавишу...');
    readkey;
    exit;
  end;

  writeln('Голова');
  current := queueHead;
  i := 1;

  while current <> nil do
  begin
    writeln('  ', i, '. ', current^.data);
    current := current^.next;
    inc(i);
  end;

  writeln('Хвост');
  writeln;
  writeln('Всего элементов: ', queueSize);
  writeln;
  writeln('Нажмите любую клавишу...');
  readkey;
end;

procedure Clear;
var
  tempNode: PNode;
begin
  clrscr;
  writeln('ОЧИСТКА ОЧЕРЕДИ');
  writeln('===============');
  writeln;

  if queueSize = 0 then
  begin
    writeln('Очередь уже пуста');
  end
  else
  begin
    while queueHead <> nil do
    begin
      tempNode := queueHead;
      queueHead := queueHead^.next;
      dispose(tempNode);
    end;

    queueTail := nil;
    queueSize := 0;
    writeln('Очередь очищена');
  end;

  writeln;
  writeln('Нажмите любую клавишу...');
  readkey;
end;

procedure AddElement;
var
  value, code: integer;
  n: string;
begin
  clrscr;
  writeln('ДОБАВЛЕНИЕ ЭЛЕМЕНТА');
  writeln('==================');
  writeln;
  writeln('Текущий размер очереди: ', queueSize);
  writeln;
  writeln('Введите целое число:');

  repeat
    readln(n);
    val(n, value, code);

    if code <> 0 then
    begin
      writeln('Введите целое число!');
    end;
  until code = 0;

  Enqueue(value);

  writeln;
  writeln('Элемент ', value, ' добавлен в очередь');
  writeln('Новый размер: ', queueSize);
  writeln;
  writeln('Нажмите любую клавишу...');
  readkey;
end;

procedure RemoveElement;
var
  value: integer;
begin
  clrscr;
  writeln('УДАЛЕНИЕ ЭЛЕМЕНТА');
  writeln('================');
  writeln;
  writeln('Текущий размер очереди: ', queueSize);
  writeln;

  if queueSize = 0 then
  begin
    writeln('Очередь пуста');
  end
  else
  begin
    value := Dequeue();
    writeln('Удален элемент: ', value);
    writeln('Новый размер: ', queueSize);

    if queueSize = 0 then
      writeln('Очередь теперь пуста');
  end;

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
            if CurrentMenu = addItem then
              CurrentMenu := exitProgram
            else
              CurrentMenu := pred(CurrentMenu);
          end;
          #80: begin
            if CurrentMenu = exitProgram then
              CurrentMenu := addItem
            else
              CurrentMenu := succ(CurrentMenu);
          end;
        end;
      end;
      #13: case CurrentMenu of
        addItem: AddElement;
        removeItem: RemoveElement;
        showQueue: DisplayQueue;
        clearQueue: Clear;
        exitProgram: ch := #27;
      end;
    end;
  until ch = #27;
end;

begin
  clrscr;
  CurrentMenu := addItem;

  queueHead := nil;
  queueTail := nil;
  queueSize := 0;

  HandleMenu;

  Clear;
end.