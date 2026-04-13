from tkinter import * # Для интерфейса
from tkinter.ttk import Combobox # Для выпадающего списка
from tkinter import scrolledtext # Для окна вывода
import ctypes # Для вызова функций из dll 

# Выбранный модуль при запуске программы
qlib = None

# Функция выбора модуля
def change_library(event=None):
    global qlib # Одна переменная для двух модулей
    select = choice.get()
    if select == "Python":
        import qlib as py_lib
        qlib = py_lib
        output_w.insert(END, "Выбрана Python библиотека\n")
    elif select == "C++":
        qlib = ctypes.CDLL("qlib.dll")
        output_w.insert(END, "Выбрана C++ библиотека\n")
    else:  # None
        qlib = None
        output_w.insert(END, "Библиотека не выбрана\n")

# Функция для добавления элемента в очередь        
def add_el():
    try:
        val = int(input_w.get())
        qlib.AddElement(val)
        size = qlib.GetSize()
        output_w.insert(END, f"Добавлено: {val} (размер: {size})\n")
        input_w.delete(0, END)
    except:
        if qlib == None:
            output_w.insert(END, "Ошибка: выберите модуль!\n")
        else:
            output_w.insert(END, "Ошибка: введите число!\n")

# Функция для удаления элемента из очереди
def remove_el():
    if qlib.IsEmpty():
        output_w.insert(END, "Очередь пуста!\n")
    else:
        val = qlib.RemoveElement()
        size = qlib.GetSize()
        output_w.insert(END, f"Удалено: {val} (Размер: {size})\n")    

# Функция для отображения очереди    
def show_q():
    size = qlib.GetSize()
    output_w.insert(END, f"Размер очереди: {size}\n")
    if size > 0:
        Elem = (ctypes.c_int * size)()
        count = qlib.DisplayQ(Elem, size)
        output_w.insert(END, "Голова ->\n")
        for i in range(count):
            output_w.insert(END, f"  {i+1}. {Elem[i]}\n")
        output_w.insert(END, "<- Хвост\n")
    else:
        output_w.insert(END, "Очередь пуста\n")

# Функция для очистки текущей очереди
def clear_q():
    qlib.Clear()
    output_w.insert(END, "Очередь очищена\n")

# Функция для очистки памяти и выхода 
def exit_p():
    try:
        import libqlibpy as py_lib
        py_lib.Clear()
    except:
        pass
    
    try:
        cpp_lib = ctypes.CDLL(r"C:\Users\wegfyhj\Documents\VS\PythonProject\qlib.dll")
        cpp_lib.Clear()
    except:
        pass
    
    window.quit()
    


window = Tk()
window.geometry("800x600") # Разрешение окна
window.title("FIFO") # Заголовок окна
window.resizable(False, False) # Запрет на масштабирование окна

# Выпадающий список с выбором модулей
choice = Combobox(window)
choice['values'] = ("None", "Python", "C++")
choice.set("None")
choice.bind("<<ComboboxSelected>>", change_library)
choice.grid(column=0, row=0)

# Левая часть с кнопками
left_part = Frame(window, bd=2, relief=GROOVE)
left_part.place(relx=0.02, rely=0.05, relwidth=0.28, relheight=0.9)
# Заголовок левой части
lbl_l = Label(left_part, text="ФУНКЦИИ", font=("Arial", 14, "bold"))
lbl_l.pack(pady=10)
# Кнопки с фунциями
btn1 = Button(left_part, text="Добавить элемент", font=("Arial", 12), width=20, height=2, command=add_el)
btn1.pack(pady=10)
btn2 = Button(left_part, text="Удалить элемент", font=("Arial", 12), width=20, height=2, command=remove_el)
btn2.pack(pady=10)
btn3 = Button(left_part, text="Показать очередь", font=("Arial", 12), width=20, height=2, command=show_q)
btn3.pack(pady=10)
btn4 = Button(left_part, text="Очистить очередь", font=("Arial", 12), width=20, height=2, command=clear_q)
btn4.pack(pady=10)
btn5 = Button(left_part, text="Выход", font=("Arial", 12), width=20, height=2, command=exit_p)
btn5.pack(pady=10)

# Правая часть
right_part = Frame(window, bd=2, relief=GROOVE)
right_part.place(relx=0.30, rely=0.05, relwidth=0.65, relheight=0.9)
# Заголовок правой части
lbl_r = Label(right_part, text="ВВОД/ВЫВОД", font=("Arial", 14, "bold"))
lbl_r.pack(pady=10)
# Поле для ввода значений
input_w = Entry(right_part, width=60)
input_w.pack(pady=10)
# Окно вывода текстовой информации
output_w = scrolledtext.ScrolledText(right_part, width=60)
output_w.pack(pady=10)
# Кнопка для очистки окна
btn6 = Button(right_part, text="Очистить вывод", font=("Arial", 10), width=12, height=1, command=lambda: output_w.delete(1.0,END))
btn6.pack(pady=1)

window.mainloop()