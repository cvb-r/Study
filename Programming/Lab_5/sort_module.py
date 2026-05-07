import os
import heapq
import struct

# Прогресс
_cb = None
_last_progress = -1
def _report(p):
    global _last_progress
    if _cb and p != _last_progress:
        _cb(p)
        _last_progress = p

# CSV
def _make_csv_key(line, field):
    parts = line.split(",")
    if field == "id":
        return int(parts[0])
    elif field == "date":
        return parts[1]
    elif field == "product":
        return parts[2]
    elif field == "price":
        return float(parts[3])
    elif field == "quantity":
        return int(parts[4])
    return parts[0]

def sort_csv_file(field_name, progress_callback=None):
    global _cb, _last_progress
    _cb = progress_callback
    _last_progress = -1
    _report(0)
    if not os.path.exists("data.csv"): # Проверка на существование файла
        return False, 0
    os.makedirs("tmp", exist_ok=True)
    CHUNK = 400000 # Размер одной серии (строк)
    temp_files = []
    total = 0
    with open("data.csv", "r", encoding="utf-8") as f: # Открываем CSV в режиме текстового чтения
        header = f.readline()

        # ФАЗА 1
        while True:
            chunk = []
            # Читаем чанки
            for _ in range(CHUNK):
                line = f.readline()
                if not line:
                    break
                line = line.strip()
                if line:
                    chunk.append(line)
            if not chunk:
                break
            total += len(chunk)
            # Сортируем чанк по указанному полю
            chunk.sort(key=lambda x: _make_csv_key(x, field_name))
            name = f"tmp/chunk_{len(temp_files)}.tmp"
            # Записываем отсортированный чанк во временный текстовый файл
            with open(name, "w", encoding="utf-8") as out:
                out.write("\n".join(chunk) + "\n")
            temp_files.append(name)
            _report(int(len(temp_files) * 50 / 77))
    _report(50)

    # ФАЗА 2
    with open("sorted.txt", "w", encoding="utf-8") as out: # Открываем файл в режиме записи
        out.write(header)
        heap = []
        files = []
        # Открываем все temp файлы в режиме текстового чтения
        for i, fname in enumerate(temp_files):
            f = open(fname, "r", encoding="utf-8")
            files.append(f)
            line = f.readline().strip()
            if line:
                heapq.heappush(heap, (_make_csv_key(line, field_name), line, i))
        merged = 0
        while heap:
            key, line, idx = heapq.heappop(heap) # Извлекаем наименьшую запись
            out.write(line + "\n") # Записываем в результат
            merged += 1
            # Читаем следующую запись
            next_line = files[idx].readline().strip()
            if next_line:
                heapq.heappush(heap,
                    (_make_csv_key(next_line, field_name), next_line, idx))
            # Обновление прогресса каждые 50000 записей
            if merged % 50000 == 0:
                _report(50 + int(merged * 50 / total))
        # Очистка после завершения сортировки
        for f in files:
            f.close()
    # Удаление временных файлов
    for f in temp_files:
        os.remove(f)
    os.rmdir("tmp")
    _report(100)
    return True, total

# BIN
BIN_STRUCT = struct.Struct("<iiii50sii")

def _make_bin_key(record, field):
    id_, year, month, day, product, price, quantity = record
    product = product.decode("utf-8").rstrip("\x00")
    if field == "id":
        return id_
    elif field == "date":
        return f"{year}-{month}-{day}"
    elif field == "product":
        return product
    elif field == "price":
        return price
    elif field == "quantity":
        return quantity
    return id_

def sort_bin_file(field_name, progress_callback=None):
    global _cb, _last_progress
    _cb = progress_callback
    _last_progress = -1
    _report(0)
    if not os.path.exists("data.bin"): # Проверка на существование файла
        return False, 0
    os.makedirs("tmp", exist_ok=True)
    size = os.path.getsize("data.bin") # Определяем размер
    record_size = BIN_STRUCT.size
    total_records = size // record_size
    MAX_MEMORY = 10 * 1024 * 1024 # Ограничиваем память
    CHUNK_RECORDS = MAX_MEMORY // record_size
    temp_files = []

    # ФАЗА 1
    with open("data.bin", "rb") as f: # Открываем bin в режиме бинарного чтения
        while True:
            chunk = []
            # Читаем чанки
            for _ in range(CHUNK_RECORDS):
                data = f.read(record_size)
                if not data:
                    break
                chunk.append(BIN_STRUCT.unpack(data))
            if not chunk:
                break
            # Сортируем чанк по указанному полю
            chunk.sort(key=lambda r: _make_bin_key(r, field_name))
            name = f"tmp/bin_chunk_{len(temp_files)}.tmp"
            # Записываем отсортированый чанк во временный бинарный файл
            with open(name, "wb") as out:
                for record in chunk:
                    out.write(BIN_STRUCT.pack(*record))
            temp_files.append(name)
            _report(int(len(temp_files) * 50 / 103))
    _report(50)

    # ФАЗА 2
    heap = []
    files = []
    # Открываем все temp файлы в режиме бинарного чтения
    for i, fname in enumerate(temp_files):
        f = open(fname, "rb")
        files.append(f)
        data = f.read(record_size)
        if data:
            record = BIN_STRUCT.unpack(data)
            heapq.heappush(heap,
                (_make_bin_key(record, field_name), record, i))
            
    # Запись результата
    with open("sorted.txt", "w", encoding="utf-8") as out: # Открываем файл в режиме записи
        out.write("id,date,product,price,quantity\n")
        merged = 0
        while heap:
            key, record, idx = heapq.heappop(heap) # Извлекаем наименьшую запись
            id_, year, month, day, product, price, quantity = record
            product = product.decode("utf-8").rstrip("\x00") # Распаковываем запись
            out.write(f"{id_},{year}-{month}-{day},{product},{price},{quantity}\n") # Записываем в CSV формате
            merged += 1
            # Читаем следующую запись
            data = files[idx].read(record_size)
            if data:
                record = BIN_STRUCT.unpack(data)
                heapq.heappush(heap,
                    (_make_bin_key(record, field_name), record, idx))
            # Обновление прогресса каждые 100000 записей
            if merged % 100000 == 0:
                _report(50 + int(merged * 50 / total_records))

    # Очистка после завершения сортировки
    for f in files:
        f.close()
    for f in temp_files:
        os.remove(f)
    os.rmdir("tmp")
    _report(100)
    return True, total_records