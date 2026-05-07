#pragma once
#define DLL_EXPORT __declspec(dllexport)
typedef void (*ProgressCallback)(int percent);
extern "C" {
    DLL_EXPORT bool sort_csv_file(const char* field_name, int* rows, ProgressCallback cb);
    DLL_EXPORT bool sort_bin_file(const char* field_name, int* rows, ProgressCallback cb);
}