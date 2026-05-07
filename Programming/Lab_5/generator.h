#pragma once
#define DLL_EXPORT __declspec(dllexport)
typedef void (*ProgressCallback)(int percent);
extern "C" {
    DLL_EXPORT bool GenerateCSV(ProgressCallback callback);
    DLL_EXPORT bool GenerateBIN(ProgressCallback callback);
}