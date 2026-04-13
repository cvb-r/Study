#include "qlib.h" // Заголовочный файл
#include <stdlib.h> // Для использования malloc и free
#include <stdio.h>

// Структура узла очереди
struct Node {
    int data; // Хранимые данные
    struct Node* next; // Указатель на следующий элемент
};

static struct Node* head = NULL;
static struct Node* tail = NULL;
static int QSize = 0;

// Функция добавления нового элемента в конец очереди
void AddElement(int value) {
    struct Node* new_node = (struct Node*)malloc(sizeof(struct Node));

    \\ Вывод ошибки если новый узел не удалось создать
    if (new_node == NULL) {
        printf("Ошибка\n");
        return;
    }

    new_node->data = value; \\ Заносим введённые данные в data
    new_node->next = NULL;  \\ Перед новым элементом ничего нет

    \\ Если новый элемент будет первым в очереди
    if (tail == NULL) {
        head = new_node;
        tail = new_node;
    } else {
        tail->next = new_node;
        tail = new_node;
    }

    QSize++;
}

\\ Удаление эемента из начала очереди
int RemoveElement() {

    \\ Если в очереди нет элементов
    if (head == NULL) { 
        return 0;
    }

    int value = head->data; \\ Записываем хранимое значение элемента
    struct Node* temp = head;
    head = head->next;

    \\Если элемент был последним в очереди
    if (head == NULL) {
        tail = NULL;
    }

    free(temp); \\ Освобождение памяти удалённого узла
    QSize--; \\ Уменьшаем переменную размера очереди на единицу
    return value;
}

\\ Проверка на пустую очередь
int IsEmpty() {
    if (head == NULL) {
        return 1;
    } else {
        return 0;
    }
}

\\ Функция для получения размера очереди
int GetSize() {
    return QSize;
}

\\ Функция для отображения очереди
int DisplayQ(int* Elem, int max_size) {
    struct Node* current = head;
    int count = 0;

    while (current != NULL && count < max_size) {
        Elem[count] = current->data;
        current = current->next;
        count++;
    }

    return count;
}

\\ Функция для очистки очереди
void Clear() {
    while (head != NULL) {
        struct Node* temp = head;
        head = head->next;
        free(temp); \\ Освобождение памяти удалённого узла
    }
    tail = NULL;
    QSize = 0;
}