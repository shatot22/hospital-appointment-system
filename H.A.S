import tkinter as tk
from tkinter import ttk, messagebox
from datetime import datetime
import mysql.connector

def setup_database():
    try:
        mydb = mysql.connector.connect(
            host="localhost",  # or عنوان الخادم الخاص بك
            user="root",       # اسم المستخدم الخاص بـ MySQL
            password="root"    # كلمة المرور الخاصة بـ MySQL
        )

        mycursor = mydb.cursor()

        # إنشاء قاعدة البيانات إذا لم تكن موجودة
        mycursor.execute("CREATE DATABASE IF NOT EXISTS hospital2")

        # الاتصال بقاعدة البيانات المحددة
        mydb.close()  # إغلاق الاتصال الأول
        mydb = mysql.connector.connect(
            host="localhost",
            user="root",
            password="root",
            database="hospital2"  # اسم قاعدة البيانات التي أنشأناها
        )
        mycursor = mydb.cursor()

        mycursor.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id INT AUTO_INCREMENT PRIMARY KEY,
                patant VARCHAR(255) NOT NULL,
                phone VARCHAR(100) NOT NULL,
                doc VARCHAR(255) NOT NULL,
                date VARCHAR(255) NOT NULL,
                time VARCHAR(255) NOT NULL,
                record TEXT NOT NULL,
                visit_type VARCHAR(50) NOT NULL
            )
        """)

        mydb.commit()
        mydb.close()
    except mysql.connector.Error as err:
        print(f"Something went wrong: {err}")

setup_database()

def load_data():
    try:
        mydb = mysql.connector.connect(
            host="localhost",
            user="root",
            password="root",
            database="hospital2"
        )
        mycursor = mydb.cursor()

        mycursor.execute("SELECT * FROM users")
        rows = mycursor.fetchall()

        # مسح البيانات القديمة في الجدول
        tree.delete(*tree.get_children())

        # إدراج البيانات الجديدة
        for row in rows:
            tree.insert("", "end", values=row)

        mydb.close()
    except mysql.connector.Error as err:
        print(f"خطأ أثناء جلب البيانات: {err}")

def add_appointment():
    """ تضيف موعد جديد إلى قاعدة البيانات بعد التحقق من صحة البيانات """

    # جلب البيانات من حقول الإدخال
    patient_name = p_name_entry.get().strip()
    phone = phone_entry.get().strip()
    doctor = doctor_entry.get().strip()
    date = f"{year_entry.get()}-{month_entry.get()}-{day_entry.get()}"  # تنسيق التاريخ
    time = f"{time_entry.get()} {period_entry.get()}"
    record = record_entry.get("1.0", tk.END).strip()  # قراءة النص مع إزالة المسافات الفارغة
    visit_type = visit_type_var.get()

    # التحقق من أن جميع الحقول ممتلئة
    if not all([patient_name, phone, doctor, date, time, record, visit_type]):
        print("Error: Incomplete data received!")  # طباعة رسالة خطأ
        return

    try:
        # الاتصال بقاعدة البيانات
        mydb = mysql.connector.connect(
            host="localhost",
            user="root",
            password="root",
            database="hospital2"
        )
        mycursor = mydb.cursor()

        # تنفيذ استعلام الإدخال في قاعدة البيانات
        mycursor.execute(
            "INSERT INTO users (patant, phone, doc, date, time, record, visit_type) VALUES (%s, %s, %s, %s, %s, %s, %s)",
            (patient_name, phone, doctor, date, time, record, visit_type)
        )
        mydb.commit()
        mydb.close()

        print(f"Success: Appointment for {patient_name} added successfully!")  # طباعة نجاح العملية
        load_data()  # تحديث الجدول بعد إضافة الموعد

    except mysql.connector.Error as err:
        print(f"Database Error: {err}")

def edit_appointment():
    """ تعديل بيانات موعد موجود في قاعدة البيانات """
    try:
        selected_item = tree.selection()[0]
        item = tree.item(selected_item)
        appointment_id = item['values'][0]

        # جلب البيانات من حقول الإدخال
        patient_name = p_name_entry.get().strip()
        phone = phone_entry.get().strip()
        doctor = doctor_entry.get().strip()
        date = f"{year_entry.get()}-{month_entry.get()}-{day_entry.get()}"  # تنسيق التاريخ
        time = f"{time_entry.get()} {period_entry.get()}"
        record = record_entry.get("1.0", tk.END).strip()  # قراءة النص مع إزالة المسافات الفارغة
        visit_type = visit_type_var.get()

        # التحقق من أن جميع الحقول ممتلئة
        if not all([patient_name, phone, doctor, date, time, record, visit_type]):
            print("Error: Incomplete data received!")  # طباعة رسالة خطأ
            return

        mydb = mysql.connector.connect(
            host="localhost",
            user="root",
            password="root",
            database="hospital2"
        )
        mycursor = mydb.cursor()

        # تنفيذ استعلام التعديل في قاعدة البيانات
        mycursor.execute("""
            UPDATE users
            SET patant = %s, phone = %s, doc = %s, date = %s, time = %s, record = %s, visit_type = %s
            WHERE id = %s
        """, (patient_name, phone, doctor, date, time, record, visit_type, appointment_id))
        
        mydb.commit()
        mydb.close()

        print(f"Success: Appointment for {patient_name} updated successfully!")  # طباعة نجاح العملية
        load_data()  # تحديث الجدول بعد تعديل الموعد

    except IndexError:
        print("Error: No appointment selected!")  # طباعة خطأ إذا لم يتم تحديد موعد
    except mysql.connector.Error as err:
        print(f"Database Error: {err}")

def delete_appointment():
    try:
        selected_item = tree.selection()[0]
        item = tree.item(selected_item)
        appointment_id = item['values'][0]

        mydb = mysql.connector.connect(
            host="localhost",
            user="root",
            password="root",
            database="hospital2"
        )
        mycursor = mydb.cursor()
        mycursor.execute("DELETE FROM users WHERE id = %s", (appointment_id,))
        mydb.commit()

        tree.delete(selected_item)

        success_label = tk.Label(root, text="تم حذف الموعد بنجاح ✅", fg="green", bg="white", font=("Helvetica", 10, "bold"))
        success_label.pack()
        root.after(2000, success_label.destroy)

    except IndexError:
        error_label = tk.Label(root, text="يرجى تحديد موعد لحذفه.", fg="red", bg="white", font=("Helvetica", 10, "bold"))
        error_label.pack()
        root.after(2000, error_label.destroy)
    except mysql.connector.Error as err:
        error_label = tk.Label(root, text=f"خطأ في الاتصال بقاعدة البيانات: {err}", fg="red", bg="white", font=("Helvetica", 10, "bold"))
        error_label.pack()
        root.after(2000, error_label.destroy)
    finally:
        mydb.close()

def search_data():
    """ البحث عن مواعيد في قاعدة البيانات بناءً على معيار البحث المحدد """
    query = search_entry.get().strip()
    filter_by = search_options.get()

    if filter_by == "اسم المريض":
        filter_by = "patant"
    elif filter_by == "رقم الهاتف":
        filter_by = "phone"
    elif filter_by == "اسم الطبيب":
        filter_by = "doc"
    elif filter_by == "التاريخ":
        filter_by = "date"
    else:
        filter_by = "visit_type"

    try:
        mydb = mysql.connector.connect(
            host="localhost",
            user="root",
            password="root",
            database="hospital2"
        )
        mycursor = mydb.cursor()

        sql = f"SELECT * FROM users WHERE {filter_by} LIKE %s"
        values = (f"%{query}%", )
        mycursor.execute(sql, values)
        rows = mycursor.fetchall()

        # مسح البيانات القديمة في الجدول
        tree.delete(*tree.get_children())

        # إدراج البيانات الجديدة
        for row in rows:
            tree.insert("", "end", values=row)

        mydb.close()
    except mysql.connector.Error as err:
        print(f"Database Error: {err}")

# إنشاء النافذة الرئيسية
root = tk.Tk()
root.title("نظام إدارة مواعيد العيادات الطبية")
root.geometry("980x600")
root.configure(bg="#F0F8FF")

# شريط البحث
search_frame = tk.Frame(root, bg="#F0F8FF")
search_frame.pack(pady=10)
tk.Label(search_frame, text="بحث:", bg="#F0F8FF", font=("Arial", 14, "bold")).pack(side=tk.LEFT, padx=5)
search_entry = tk.Entry(search_frame, font=("Arial", 13), bd=2, relief="groove")
search_entry.pack(side=tk.LEFT, padx=5)
search_options = ttk.Combobox(search_frame, values=["اسم المريض", "رقم الهاتف", "اسم الطبيب", "التاريخ", "نوع الزيارة"], font=("Arial", 13))
search_options.pack(side=tk.LEFT, padx=5)
search_options.set("اسم المريض")
tk.Button(search_frame, text="🔍 بحث", bg="#4CAF50", fg="white", font=("Arial", 13, "bold"), command=search_data).pack(side=tk.LEFT, padx=5)
# إنشاء الجدول
columns = ("id", "اسم المريض", "رقم الهاتف", "اسم الطبيب", "تاريخ الموعد", "ميعاد الحضور", "التاريخ المرضي", "نوع الزيارة")
tree = ttk.Treeview(root, columns=columns, show="headings")
tree.pack(expand=True, fill="both", padx=10, pady=10)

for col in columns:
    tree.heading(col, text=col, anchor=tk.CENTER)
    tree.column(col, anchor=tk.CENTER, width=10, minwidth=30, stretch=True)  # السماح بتغير العرض

def on_tree_select(event):
    selected_item = tree.selection()  # جلب العنصر المحدد من الجدول

    if selected_item:
        values = tree.item(selected_item, "values")  # استخراج القيم من العنصر

        # تعبئة الحقول بالقيم المختارة
        p_name_entry.delete(0, tk.END)
        p_name_entry.insert(0, values[1])

        phone_entry.delete(0, tk.END)
        phone_entry.insert(0, values[2])

        doctor_entry.delete(0, tk.END)
        doctor_entry.insert(0, values[3])

        if "-" in values[4]:  # التحقق من صحة تنسيق التاريخ
            date_parts = values[4].split("-")
            if len(date_parts) == 3:  # يجب أن يكون هناك 3 أجزاء (YYYY-MM-DD)
                day_entry.set(date_parts[2])   # استخراج اليوم
                month_entry.set(date_parts[1])  # استخراج الشهر
                year_entry.set(date_parts[0])  # استخراج السنة

        time_parts = values[5].split(" ")
        if len(time_parts) == 2:
            time_entry.set(time_parts[0])  # ضبط وقت الموعد
            period_entry.set(time_parts[1])  # ضبط الفترة (صباحًا/مساءً)

        record_entry.delete("1.0", tk.END)
        record_entry.insert("1.0", values[6])  # إضافة التاريخ المرضي

        visit_type_var.set(values[7])  # ضبط نوع الزيارة

tree.bind("<<TreeviewSelect>>", on_tree_select)
# حقول الإدخال
form_frame = tk.Frame(root, bg="#F0F8FF")
form_frame.pack(pady=10)

tk.Label(form_frame, text="اسم المريض", bg="#F0F8FF", font=("Arial", 13)).grid(row=0, column=0)
p_name_entry = tk.Entry(form_frame, font=("Arial", 13), bd=2, relief="groove")
p_name_entry.grid(row=0, column=1)

tk.Label(form_frame, text="رقم الهاتف", bg="#F0F8FF", font=("Arial", 13)).grid(row=1, column=0)
phone_entry = tk.Entry(form_frame, font=("Arial", 13), bd=2, relief="groove")
phone_entry.grid(row=1, column=1)

tk.Label(form_frame, text="اسم الطبيب", bg="#F0F8FF", font=("Arial", 13)).grid(row=2, column=0)
doctor_entry = tk.Entry(form_frame, font=("Arial", 13), bd=2, relief="groove")
doctor_entry.grid(row=2, column=1)

tk.Label(form_frame, text="التاريخ المرضي", bg="#F0F8FF", font=("Arial", 13)).grid(row=0, column=4, sticky="n")
record_entry = tk.Text(form_frame, font=("Arial", 13), bd=2, relief="groove", height=7, width=30)
record_entry.grid(row=1, column=4, rowspan=4, sticky="w")

tk.Label(form_frame, text="نوع الزيارة", bg="#F0F8FF", font=("Arial", 13)).grid(row=5, column=0)
visit_type_var = tk.StringVar(value="كشف")
tk.Radiobutton(form_frame, text="كشف", variable=visit_type_var, value="كشف", bg="#F0F8FF", font=("Arial", 13)).grid(row=5, column=1, sticky="w")
tk.Radiobutton(form_frame, text="عمليات", variable=visit_type_var, value="عمليات", bg="#F0F8FF", font=("Arial", 13)).grid(row=5, column=1, sticky="e")

# اختيار التاريخ
tk.Label(form_frame, text="التاريخ", bg="#F0F8FF", font=("Arial", 13)).grid(row=3, column=0)
now = datetime.today()
day_entry = ttk.Combobox(form_frame, values=[str(i) for i in range(1, 32)], font=("Arial", 13), width=5)
day_entry.set(str(now.day))
day_entry.grid(row=3, column=1, sticky="w")

month_entry = ttk.Combobox(form_frame, values=[str(i) for i in range(1, 13)], font=("Arial", 13), width=3)
month_entry.set(str(now.month))
month_entry.grid(row=3, column=1)

year_entry = ttk.Combobox(form_frame, values=[str(i) for i in range((now.year), 2051)], font=("Arial", 13), width=5)
year_entry.set(str(now.year))
year_entry.grid(row=3, column=1, sticky="e")

# اختيار ميعاد الحضور
tk.Label(form_frame, text="ميعاد الحضور", bg="#F0F8FF", font=("Arial", 13)).grid(row=4, column=0)
time_entry = ttk.Combobox(form_frame, values=[f"{h}:00" for h in range(1, 13)], font=("Arial", 13), width=6)
time_entry.grid(row=4, column=1, sticky="w")

period_entry = ttk.Combobox(form_frame, values=["صباحًا", "مساءً"], font=("Arial", 13), width=6)
period_entry.grid(row=4, column=1)
period_entry.grid(row=4, column=1, sticky="e")

# أزرار التحكم
button_frame = tk.Frame(root, bg="#F0F8FF")
button_frame.pack(pady=10)
tk.Button(button_frame, text="➕ إضافة موعد", bg="#4CAF50", fg="white", font=("Arial", 13, "bold"), command=add_appointment).pack(side=tk.LEFT, padx=5)
tk.Button(button_frame, text="✏️ تعديل موعد", bg="#2196F3", fg="white", font=("Arial", 13, "bold"), command=edit_appointment).pack(side=tk.LEFT, padx=5)
tk.Button(button_frame, text="❌ حذف موعد", bg="#F44336", fg="white", font=("Arial", 13, "bold"), command=delete_appointment).pack(side=tk.LEFT, padx=5)

# استدعاء الدالة عند تشغيل البرنامج
load_data()

root.mainloop()
