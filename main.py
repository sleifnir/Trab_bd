import tkinter as tk
from tkinter import ttk


# Function to show dropdown options
def show_dropdown(option):
    for widget in option_frame.winfo_children():
        widget.destroy()

    label = tk.Label(option_frame, text="Select an option:")
    label.pack(side="left")

    options = []
    if option == "Option 1":
        options = ["Ano", "Nome", "Cargo"]
    elif option == "Option 2":
        options = ["Option 2-1", "Option 2-2", "Option 2-3"]
    elif option == "Option 3":
        options = ["Option 3-1", "Option 3-2", "Option 3-3"]

    selector = ttk.Combobox(option_frame, values=options)
    selector.pack(side="left")


# Function to handle menu selection
def menu_selected(option):
    show_dropdown(option)


# Create main application window
app = tk.Tk()
app.title("Menu App with Dropdown")

# Create a menu
menu_bar = tk.Menu(app)
app.config(menu=menu_bar)

# Add menu options
file_menu = tk.Menu(menu_bar, tearoff=0)
menu_bar.add_cascade(label="Options", menu=file_menu)

file_menu.add_command(label="Option 1", command=lambda: menu_selected("Option 1"))
file_menu.add_command(label="Option 2", command=lambda: menu_selected("Option 2"))
file_menu.add_command(label="Option 3", command=lambda: menu_selected("Option 3"))

# Frame to show dropdown options
option_frame = tk.Frame(app)
option_frame.pack(pady=20)

# Run the application
app.mainloop()
