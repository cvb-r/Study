#include "sort_module.h"
#include <fstream>
#include <string>
#include <vector>
#include <algorithm>
#include <queue>
#include <cstdlib>

using namespace std;

static ProgressCallback _cb = nullptr;
static int _last = -1;
static void report(int p) {
    if (_cb && p != _last) { _cb(p); _last = p; }
}

struct Key {
    string s; int i = 0; double d = 0.0;
};

static bool less_by(const Key& a, const Key& b, const string& f) {
    if (f == "id" || f == "quantity") return a.i < b.i;
    if (f == "price") return a.d < b.d;
    return a.s < b.s;
}

// CSV
static Key csv_key(const string& line, const string& f) {
    Key k;
    size_t p1 = line.find(','), p2 = line.find(',', p1+1),
           p3 = line.find(',', p2+1), p4 = line.find(',', p3+1);
    if (f == "id") k.i = stoi(line.substr(0, p1));
    else if (f == "date") k.s = line.substr(p1+1, p2-p1-1);
    else if (f == "product") k.s = line.substr(p2+1, p3-p2-1);
    else if (f == "price") k.d = stod(line.substr(p3+1, p4-p3-1));
    else if (f == "quantity") k.i = stoi(line.substr(p4+1));
    return k;
}

DLL_EXPORT bool sort_csv_file(const char* field, int* rows, ProgressCallback cb) {
    _cb = cb; _last = -1; report(0);
	ifstream in("data.csv");
    if (!in) return false; // Проверка на существование файла (нет в ifstream, оставляем как есть)
    
    string header, line, f(field);
    getline(in, header);
    system("mkdir tmp 2>nul");
    
    vector<string> tmp_files;
    int total = 0;
    
    // ФАЗА 1
    while (true) {
        vector<pair<string, Key>> chunk;
        // Читаем чанки
        while (chunk.size() < 400000 && getline(in, line)) {
            if (!line.empty()) {
                chunk.push_back(make_pair(line, csv_key(line, f)));
            }
        }
        if (chunk.empty()) break;
        total += chunk.size();
        // Сортируем чанк по указанному полю
        sort(chunk.begin(), chunk.end(), [&](const pair<string,Key>& a, const pair<string,Key>& b) {
            return less_by(a.second, b.second, f);
        });
        string name = "tmp/chunk_" + to_string(tmp_files.size()) + ".tmp";
        // Записываем отсортированный чанк во временный текстовый файл
        ofstream out(name.c_str());
        for (size_t i = 0; i < chunk.size(); ++i) {
            out << chunk[i].first << "\n";
        }
        tmp_files.push_back(name);
        report((int)(tmp_files.size() * 50 / 77));
    }
    report(50);
    
    // ФАЗА 2
    ofstream out("sorted.txt"); // Открываем файл в режиме записи
    out << header << "\n";
    
    struct HeapItem {
        string line;
        Key key;
        int idx;
    };
    auto cmp = [&](const HeapItem& a, const HeapItem& b) {
        return !less_by(a.key, b.key, f);
    };
    priority_queue<HeapItem, vector<HeapItem>, decltype(cmp)> pq(cmp);
    
    vector<ifstream> files(tmp_files.size());
    // Открываем все temp файлы в режиме текстового чтения
    for (size_t i = 0; i < tmp_files.size(); ++i) {
        files[i].open(tmp_files[i].c_str());
        if (getline(files[i], line)) {
            HeapItem item;
            item.line = line;
            item.key = csv_key(line, f);
            item.idx = (int)i;
            pq.push(item);
        }
    }
    
    int merged = 0;
    while (!pq.empty()) {
        HeapItem top = pq.top(); pq.pop(); // Извлекаем наименьшую запись
        out << top.line << "\n"; // Записываем в результат
        if (++merged % 50000 == 0) report(50 + merged * 50 / total);
        line.clear();
        // Читаем следующую запись
        if (getline(files[top.idx], line)) {
            HeapItem item;
            item.line = line;
            item.key = csv_key(line, f);
            item.idx = top.idx;
            pq.push(item);
        }
        // Обновление прогресса каждые 50000 записей (вверху)
    }
    
    // Очистка после завершения сортировки
    for (size_t i = 0; i < files.size(); ++i) files[i].close();
    // Удаление временных файлов
    for (size_t i = 0; i < tmp_files.size(); ++i) remove(tmp_files[i].c_str());
    system("rmdir /s /q tmp 2>nul");
    report(100);
    *rows = total;
    return true;
}

// BIN
#pragma pack(push, 1)
struct BinRecord { int id, year, month, day; char product[50]; int price, quantity; };
#pragma pack(pop)

static Key bin_key(const BinRecord& r, const string& f) {
    Key k;
    if (f == "id") k.i = r.id;
    else if (f == "date") k.s = to_string(r.year) + "-" + to_string(r.month) + "-" + to_string(r.day);
    else if (f == "product") k.s = string(r.product);
    else if (f == "price") k.d = (double)r.price;
    else if (f == "quantity") k.i = r.quantity;
    return k;
}

DLL_EXPORT bool sort_bin_file(const char* field, int* rows, ProgressCallback cb) {
    _cb = cb; _last = -1; report(0);
    ifstream in("data.bin", ios::binary);
    if (!in) return false; // Проверка на существование файла
    
    system("mkdir tmp 2>nul");
    const size_t RS = sizeof(BinRecord);
    in.seekg(0, ios::end);
    size_t total = in.tellg() / RS; // Определяем размер
    in.seekg(0);
    
    vector<string> tmp_files;
    const size_t CHUNK = (10 * 1024 * 1024) / RS; // Ограничиваем память
    
    // ФАЗА 1
    while (true) {
        vector<pair<BinRecord, Key>> chunk;
        BinRecord r;
        // Читаем чанки
        for (size_t i = 0; i < CHUNK && in.read((char*)&r, RS); ++i) {
            chunk.push_back(make_pair(r, bin_key(r, field)));
        }
        if (chunk.empty()) break;
        // Сортируем чанк по указанному полю
        sort(chunk.begin(), chunk.end(), [&](const pair<BinRecord,Key>& a, const pair<BinRecord,Key>& b) {
            return less_by(a.second, b.second, field);
        });
        string name = "tmp/bin_" + to_string(tmp_files.size()) + ".tmp";
        // Записываем отсортированный чанк во временный бинарный файл
        ofstream out(name.c_str(), ios::binary);
        for (size_t i = 0; i < chunk.size(); ++i) {
            out.write((char*)&chunk[i].first, RS);
        }
        tmp_files.push_back(name);
        report((int)(tmp_files.size() * 50 / 103));
    }
    report(50);
    
    // ФАЗА 2
    struct BinHeapItem {
        BinRecord rec;
        Key key;
        int idx;
    };
    auto cmp = [&](const BinHeapItem& a, const BinHeapItem& b) {
        return !less_by(a.key, b.key, field);
    };
    priority_queue<BinHeapItem, vector<BinHeapItem>, decltype(cmp)> pq(cmp);
    
    vector<ifstream> files(tmp_files.size());
    // Открываем все temp файлы в режиме бинарного чтения
    for (size_t i = 0; i < tmp_files.size(); ++i) {
        files[i].open(tmp_files[i].c_str(), ios::binary);
        BinRecord r;
        if (files[i].read((char*)&r, RS)) {
            BinHeapItem item;
            item.rec = r;
            item.key = bin_key(r, field);
            item.idx = (int)i;
            pq.push(item);
        }
    }
    
    ofstream out("sorted.txt"); // Открываем файл в режиме записи
    out << "id,date,product,price,quantity\n";
    
    size_t merged = 0;
    while (!pq.empty()) {
        BinHeapItem top = pq.top(); pq.pop(); // Извлекаем наименьшую запись
        // Распаковываем запись
        out << top.rec.id << "," << top.rec.year << "-" << top.rec.month << "-" << top.rec.day << ","
            << top.rec.product << "," << top.rec.price << "," << top.rec.quantity << "\n"; // Записываем в CSV формате
        if (++merged % 100000 == 0) report(50 + (int)(merged * 50 / total));
        BinRecord r;
        // Читаем следующую запись
        if (files[top.idx].read((char*)&r, RS)) {
            BinHeapItem item;
            item.rec = r;
            item.key = bin_key(r, field);
            item.idx = top.idx;
            pq.push(item);
        }
        // Обновление прогресса каждые 100000 записей (вверху)
    }
    
    // Очистка после завершения сортировки
    for (size_t i = 0; i < files.size(); ++i) files[i].close();
    for (size_t i = 0; i < tmp_files.size(); ++i) remove(tmp_files[i].c_str());
    system("rmdir /s /q tmp 2>nul");
    report(100);
    *rows = (int)total;
    return true;
}