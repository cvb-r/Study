Elements = []

# Функция для добавления элемента в конец очереди
def AddElement(value):
    Elements.append(value)

# Функция для удаления элемента из начала очереди
def RemoveElement():
    return Elements.pop(0) if Elements else None

# Функция для проверки на пустую очередь
def IsEmpty():
    return len(Elements) == 0

# Функция для получения размера очереди
def GetSize():
    return len(Elements)

# Функция для отображения очереди
def DisplayQ(Elem, size):
    count = min(len(Elements), size)
    for i in range(count):
        Elem[i] = Elements[i]
    return count

# Функция очиски очереди
def Clear():
    Elements.clear()