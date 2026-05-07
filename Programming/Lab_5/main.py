from tkinter import *
from tkinter.ttk import Combobox, Progressbar
from tkinter import scrolledtext
import ctypes, threading, os, shutil

# DLL генерации
dll = ctypes.CDLL(os.path.join(os.path.dirname(__file__), "generator.dll"))
dll.GenerateCSV.argtypes = dll.GenerateBIN.argtypes = [ctypes.CFUNCTYPE(None, ctypes.c_int)]
dll.GenerateCSV.restype = dll.GenerateBIN.restype = ctypes.c_bool

mod = None
cpp_dll = None
py_mod = None

def log(msg): 
    output.insert(END, msg + "\n")
    output.see(END)

def progress(p): 
    bar['value'] = p
    lbl_progress.config(text=f"{p}%")
    window.update()

# Загрузка C++ модуля
try:
    cpp_dll = ctypes.CDLL(os.path.join(os.path.dirname(__file__), "sort_module.dll"))
    cpp_dll.sort_csv_file.argtypes = [ctypes.c_char_p, ctypes.POINTER(ctypes.c_int), ctypes.CFUNCTYPE(None, ctypes.c_int)]
    cpp_dll.sort_bin_file.argtypes = cpp_dll.sort_csv_file.argtypes
    cpp_dll.sort_csv_file.restype = cpp_dll.sort_bin_file.restype = ctypes.c_bool
    _cb = ctypes.CFUNCTYPE(None, ctypes.c_int)(progress)
    cpp_mod = type('CppModule', (), {
        'sort_csv': staticmethod(lambda file, _: cpp_dll.sort_csv_file(file.encode(), ctypes.byref(ctypes.c_int()), _cb)),
        'sort_bin': staticmethod(lambda file, _: cpp_dll.sort_bin_file(file.encode(), ctypes.byref(ctypes.c_int()), _cb))
    })()
except: cpp_mod = None

# Загрузка Python модуля
try:
    import sort_module
    py_mod = type('PyModule', (), {
        'sort_csv': staticmethod(sort_module.sort_csv_file),
        'sort_bin': staticmethod(sort_module.sort_bin_file)
    })()
except: py_mod = None

def change_library(event=None):
    global mod
    sel = choice.get()
    if sel == "Python" and py_mod:
        mod = py_mod
        log("Python модуль загружен")
    elif sel == "C++" and cpp_mod:
        mod = cpp_mod
        log("C++ модуль загружен")
    else:
        mod = None
        log("Модуль не загружен")
    btn_sort.config(state=NORMAL if mod else DISABLED)
    btn_show.config(state=NORMAL if mod else DISABLED)

def generate(fmt):
    for b in [btn_csv, btn_bin, btn_sort, btn_show]: b.config(state=DISABLED)
    progress(0)
    log(f"Генерация {fmt}...")
    def task():
        ok = getattr(dll, f"Generate{fmt}")(ctypes.CFUNCTYPE(None, ctypes.c_int)(progress))
        window.after(0, lambda: done(ok, "Готово!" if ok else "Ошибка"))
    threading.Thread(target=task, daemon=True).start()

def done(ok, msg):
    for b in [btn_csv, btn_bin, btn_sort, btn_show]: b.config(state=NORMAL if (b != btn_sort or mod) else DISABLED)
    log(msg)

def sort_file():
    if not mod: return log("Выберите модуль сортировки")
    ft = combo_type.get().lower()
    if not os.path.exists(f"data.{ft}"): return log(f"Сгенерируйте data.{ft} сначала")
    for b in [btn_csv, btn_bin, btn_sort, btn_show]: b.config(state=DISABLED)
    log(f"Сортировка {combo_type.get()} по полю {combo_field.get()}...")
    def task():
        ok = getattr(mod, f"sort_{ft}")(combo_field.get(), progress)
        window.after(0, lambda: done(ok, "Сортировка завершена!" if ok else "Ошибка"))
    threading.Thread(target=task, daemon=True).start()

def show():
    if not os.path.exists("sorted.txt"): return log("Ошибка! Файл не найден")
    log("\nПЕРВЫЕ 1000 СТРОК\n")
    with open("sorted.txt", encoding="utf-8") as file:
        for i, line in enumerate(file):
            if i >= 1000: break
            output.insert(END, line)

def clear(): output.delete(1.0, END)

def exit():
    for file in ["data.csv", "data.bin", "sorted.txt", "tmp"]:
        try: os.remove(file) if os.path.isfile(file) else shutil.rmtree(file) if os.path.isdir(file) else None
        except: pass
    window.destroy()

# GUI
window = Tk()
window.geometry("800x800")
window.title("Sort")

top = Frame(window)
top.grid(column=0, row=0, columnspan=2, pady=10)
Label(top, text="Модуль сортировки:").pack(side=LEFT, padx=5)
choice = Combobox(top, values=["None", "Python", "C++"], width=10)
choice.set("None")
choice.bind("<<ComboboxSelected>>", change_library)
choice.pack(side=LEFT, padx=5)

left = Frame(window, bd=2, relief=GROOVE)
left.place(relx=0.02, rely=0.10, relwidth=0.28, relheight=0.85)

Label(left, text="ГЕНЕРАЦИЯ", font=("Arial", 14, "bold")).pack(pady=10)
btn_csv = Button(left, text="Генерация CSV", width=20, height=2, command=lambda: generate("CSV"))
btn_csv.pack(pady=5)
btn_bin = Button(left, text="Генерация BIN", width=20, height=2, command=lambda: generate("BIN"))
btn_bin.pack(pady=5)

Frame(left, height=2, bd=1, relief=SUNKEN).pack(fill=X, padx=10, pady=10)

Label(left, text="СОРТИРОВКА", font=("Arial", 14, "bold")).pack(pady=10)
Label(left, text="Тип файла:").pack()
combo_type = Combobox(left, values=("CSV", "BIN"), width=18)
combo_type.set("CSV")
combo_type.pack(pady=5)
Label(left, text="Поле сортировки:").pack()
combo_field = Combobox(left, values=("id", "date", "product", "price", "quantity"), width=18)
combo_field.set("id")
combo_field.pack(pady=5)
btn_sort = Button(left, text="Сортировать в sorted.txt", width=20, height=2, command=sort_file, state=DISABLED)
btn_sort.pack(pady=10)
btn_show = Button(left, text="Показать sorted.txt", width=20, height=2, command=show, state=DISABLED)
btn_show.pack(pady=10)
btn_exit = Button(left, text="Выход", width=20, height=2, command=exit)
btn_exit.pack(pady=10)

right = Frame(window, bd=2, relief=GROOVE)
right.place(relx=0.32, rely=0.10, relwidth=0.66, relheight=0.85)
Label(right, text="ВЫВОД", font=("Arial", 14, "bold")).pack(pady=10)

pf = Frame(right)
pf.pack(fill=X, padx=10)
bar = Progressbar(pf, length=450, mode='determinate')
bar.pack(side=LEFT, padx=5)
lbl_progress = Label(pf, text="0%", width=5)
lbl_progress.pack(side=LEFT)

output = scrolledtext.ScrolledText(right, width=65, height=25)
output.pack(pady=10, padx=10, expand=True, fill=BOTH)
Button(right, text="Очистить вывод", width=15, command=clear).pack(pady=5)

window.protocol("WM_DELETE_WINDOW", exit)
window.mainloop()