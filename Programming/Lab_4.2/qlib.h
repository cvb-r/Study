#pragma once // Не включать этот файл больше одного раза

#ifdef __cplusplus
extern "C" { // Сохранять декор
#endif

    // Добавить элемент
    __declspec(dllexport) void AddElement(int value);

    // Удалить и вывести
    __declspec(dllexport) int RemoveElement();

    // Проверить, пустая ли очередь
    __declspec(dllexport) int IsEmpty();

    // Получить размер очереди
    __declspec(dllexport) int GetSize();

    // Отобразить очередь
    __declspec(dllexport) int DisplayQ(int* Elem, int max_size);

    // Очистить очередь
    __declspec(dllexport) void Clear();

#ifdef __cplusplus
}
#endif