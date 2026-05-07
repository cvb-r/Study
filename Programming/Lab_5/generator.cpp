#include "generator.h"
#include <fstream>
#include <random>
#include <string>
#include <cstring>

using namespace std;

#pragma pack(push, 1)
struct Record { int id, year, month, day; char product[50]; int price, quantity; };
#pragma pack(pop)

static const char* products[] = {"Laptop", "Mouse", "Keyboard", "Monitor", "Phone", "Tablet", "Headphones", "Charger"};
static const int NUM_PROD = 8;
static const long long TARGET = 1024*1024*1024; // Размер генерируемого файла

static mt19937& rng() {
    static mt19937 gen(time(nullptr));
    return gen;
}

static int rand_range(int a, int b) {
    return uniform_int_distribution<>(a, b)(rng());
}

static void report_progress(ProgressCallback cb, long long written, long long target, int& last) {
    if (!cb) return;
    int p = (int)(written * 100 / target);
    if (p != last) { cb(p); last = p; }
}

DLL_EXPORT bool GenerateCSV(ProgressCallback cb) {
    try {
        ofstream file("data.csv");
        if (!file) return false;
        file << "id,date,product,price,quantity\n";
        
        string buf;
        buf.reserve(10*1024*1024); // 10MB буфер
        long long rows = 0, written = 0;
        int last = -1;
        
        while (written < TARGET) {
            rows++;
            buf += to_string(rows) + ',';
            buf += to_string(rand_range(2020,2025)) + '-' + to_string(rand_range(1,12)) + '-' + to_string(rand_range(1,28)) + ',';
            buf += products[rand_range(0, NUM_PROD-1)];
            buf += ',' + to_string(rand_range(10,3000)) + ',' + to_string(rand_range(1,100)) + '\n';
            
            if (buf.size() >= (10 << 20) || rows % 50000 == 0) {
                file << buf;
                buf.clear();
                written = file.tellp();
                report_progress(cb, written, TARGET, last);
            }
        }
        if (!buf.empty()) file << buf;
        if (cb) cb(100);
        return true;
    } catch (...) { return false; }
}

DLL_EXPORT bool GenerateBIN(ProgressCallback cb) {
    try {
        ofstream file("data.bin", ios::binary);
        if (!file) return false;
        
        const int BUF_SIZE = 40000;
        Record* buf = new Record[BUF_SIZE];
        long long rows = 0, written = 0;
        int idx = 0, last = -1;
        
        while (written < TARGET) {
            rows++;
            buf[idx] = {
                (int)rows,
                rand_range(2020,2025), rand_range(1,12), rand_range(1,28),
                {0}, rand_range(10,3000), rand_range(1,100)
            };
            strncpy(buf[idx].product, products[rand_range(0, NUM_PROD-1)], 49);
            
            if (++idx >= BUF_SIZE) {
                file.write((char*)buf, idx * sizeof(Record));
                idx = 0;
                written = file.tellp();
                report_progress(cb, written, TARGET, last);
            }
        }
        
        if (idx > 0) file.write((char*)buf, idx * sizeof(Record));
        delete[] buf;
        if (cb) cb(100);
        return true;
    } catch (...) { return false; }
}