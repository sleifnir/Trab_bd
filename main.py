import tkinter as tk
from tkinter import ttk
import psycopg2

# MODIFICA CONEXÃO PARA SEU BANCO
conn = psycopg2.connect(
    dbname="postgres",
    user="postgres",
    password="admin123",
    host="localhost",
    port="5432",
)


# Function to show dropdown options
def show_dropdown(option):
    clear_results()  # Clear previous results when a new option is selected

    for widget in option_frame.winfo_children():
        widget.destroy()

    if option == "Listagem Candidatura":
        suboptions = ["ano", "nome", "cargo"]
        check_vars = {}
        entry_vars = {}

        # Create checkboxes for suboptions
        for suboption in suboptions:
            var = tk.BooleanVar()
            check_vars[suboption] = var
            checkbox = tk.Checkbutton(
                option_frame,
                text=suboption.capitalize(),
                variable=var,
                command=lambda so=suboption: toggle_entry(so),
            )
            checkbox.pack(anchor="w")

            # Create entry widgets for each suboption (initially hidden)
            entry_vars[suboption] = []
            entry_frame = tk.Frame(option_frame)
            entry_frame.pack(anchor="w", padx=20)
            entry_vars[suboption].append(entry_frame)

        # Create checkboxes for sorting
        sort_options = ["ano", "nome", "cargo"]
        sort_var = tk.StringVar()
        sort_var.set("ano")  # Default sorting option

        sort_label = tk.Label(option_frame, text="Sort by:")
        sort_label.pack(anchor="w")

        for sort_option in sort_options:
            radio_button = tk.Radiobutton(
                option_frame,
                text=sort_option.capitalize(),
                variable=sort_var,
                value=sort_option,
            )
            radio_button.pack(anchor="w")

        # Function to toggle entry fields
        def toggle_entry(suboption):
            if check_vars[suboption].get():
                add_entry(suboption)
            else:
                for entry in entry_vars[suboption]:
                    entry.destroy()
                entry_vars[suboption] = []

        # Function to add entry field
        def add_entry(suboption):
            entry_frame = tk.Frame(option_frame)
            label = tk.Label(
                entry_frame, text=f"Enter {suboption} value(s) (separated by commas):"
            )
            entry = tk.Entry(entry_frame)
            entry_frame.pack(anchor="w", padx=20)
            label.pack(side="left")
            entry.pack(side="left")
            entry_vars[suboption].append(entry_frame)

        # Add button to save and print selected options and their values
        def save_and_print_selections():
            selections = {}
            for suboption in suboptions:
                if check_vars[suboption].get():
                    values = []
                    for frame in entry_vars[suboption]:
                        for widget in frame.winfo_children():
                            if isinstance(widget, tk.Entry):
                                values += [
                                    value.strip() for value in widget.get().split(",")
                                ]
                    selections[suboption] = values

            # Add the selected sorting option
            selections["sort_by"] = sort_var.get()

            # Print selections to terminal
            print(f"Selected options and values: {selections}")

            # Query the database with the selected options and values
            query_candidaturas_variable(selections)

        save_button = tk.Button(
            option_frame,
            text="Save Selections",
            command=lambda: [clear_results(), save_and_print_selections()],
        )
        save_button.pack(anchor="w")

    elif option == "Listar ficha limpa":
        query_ficha_limpa()

    elif option == "Geração de relatórios":
        query_relatorio_candidatura()

    elif option == "Busca ou remoção":
        # Add radio buttons for Remove or List options
        operation_var = tk.StringVar()
        remove_radio = tk.Radiobutton(
            option_frame, text="Remove", variable=operation_var, value="remove"
        )
        list_radio = tk.Radiobutton(
            option_frame, text="List", variable=operation_var, value="list"
        )
        remove_radio.pack(anchor="w")
        list_radio.pack(anchor="w")

        # Add entry fields for table name, fields, and values
        table_entry = tk.Entry(option_frame)
        table_entry_label = tk.Label(option_frame, text="Enter table name:")
        table_entry_label.pack(anchor="w")
        table_entry.pack(anchor="w")

        fields_entry = tk.Entry(option_frame)
        fields_entry_label = tk.Label(option_frame, text="Enter fields:")
        fields_entry_label.pack(anchor="w")
        fields_entry.pack(anchor="w")

        values_entry = tk.Entry(option_frame)
        values_entry_label = tk.Label(option_frame, text="Enter values:")
        values_entry_label.pack(anchor="w")
        values_entry.pack(anchor="w")

        all_data_var = tk.BooleanVar()
        all_data_checkbox = tk.Checkbutton(
            option_frame,
            text="Todos os dados",
            variable=all_data_var,
        )
        all_data_checkbox.pack(anchor="w")

        # Function to execute Remove or List operation
        def execute_operation():
            clear_results()
            operation = operation_var.get()
            table = table_entry.get()
            fields = fields_entry.get().split(",")
            values = values_entry.get().split(",")

            conditions = " AND ".join(
                [f"{field} = '{value}'" for field, value in zip(fields, values)]
            )

            if operation == "remove":
                remove_data(table, conditions)
            elif operation == "list":
                if all_data_var.get():
                    list_all_data(table)
                else:
                    list_data(table, conditions)

        execute_button = tk.Button(
            option_frame, text="Execute", command=execute_operation
        )
        execute_button.pack(anchor="w")

    elif option == "Busca por data":
        # Entry fields for table name and date field
        table_entry = tk.Entry(option_frame)
        table_entry_label = tk.Label(option_frame, text="Enter table name:")
        table_entry_label.pack(anchor="w")
        table_entry.pack(anchor="w")

        date_field_entry = tk.Entry(option_frame)
        date_field_entry_label = tk.Label(option_frame, text="Enter date field:")
        date_field_entry_label.pack(anchor="w")
        date_field_entry.pack(anchor="w")

        # Entry fields for initial and final dates
        start_date_entry = tk.Entry(option_frame)
        end_date_entry = tk.Entry(option_frame)
        start_date_label = tk.Label(option_frame, text="Enter start date (YYYY-MM-DD):")
        end_date_label = tk.Label(option_frame, text="Enter end date (YYYY-MM-DD):")
        start_date_label.pack(anchor="w")
        start_date_entry.pack(anchor="w")
        end_date_label.pack(anchor="w")
        end_date_entry.pack(anchor="w")

        # Function to execute the date range search
        def execute_date_search():
            clear_results()
            table = table_entry.get()
            date_field = date_field_entry.get()
            start_date = start_date_entry.get()
            end_date = end_date_entry.get()
            conditions = f"{date_field} BETWEEN '{start_date}' AND '{end_date}'"
            list_data(table, conditions)

        execute_button = tk.Button(
            option_frame, text="Execute Search", command=execute_date_search
        )
        execute_button.pack(anchor="w")

    elif option == "Remoção por data":
        # Entry fields for table name and date field
        table_entry = tk.Entry(option_frame)
        table_entry_label = tk.Label(option_frame, text="Enter table name:")
        table_entry_label.pack(anchor="w")
        table_entry.pack(anchor="w")

        date_field_entry = tk.Entry(option_frame)
        date_field_entry_label = tk.Label(option_frame, text="Enter date field:")
        date_field_entry_label.pack(anchor="w")
        date_field_entry.pack(anchor="w")

        # Entry fields for initial and final dates
        start_date_entry = tk.Entry(option_frame)
        end_date_entry = tk.Entry(option_frame)
        start_date_label = tk.Label(option_frame, text="Enter start date (YYYY-MM-DD):")
        end_date_label = tk.Label(option_frame, text="Enter end date (YYYY-MM-DD):")
        start_date_label.pack(anchor="w")
        start_date_entry.pack(anchor="w")
        end_date_label.pack(anchor="w")
        end_date_entry.pack(anchor="w")

        # Function to execute the date range search
        def execute_date_search():
            clear_results()
            table = table_entry.get()
            date_field = date_field_entry.get()
            start_date = start_date_entry.get()
            end_date = end_date_entry.get()
            conditions = f"{date_field} BETWEEN '{start_date}' AND '{end_date}'"
            remove_data(table, conditions)

        execute_button = tk.Button(
            option_frame, text="Execute Delete", command=execute_date_search
        )
        execute_button.pack(anchor="w")

    elif option == "Sair":
        sair()


# Function to handle menu selection
def menu_selected(option):
    show_dropdown(option)


# Function to toggle fullscreen mode
def toggle_fullscreen(event=None):
    is_fullscreen = not app.attributes("-fullscreen")
    app.attributes("-fullscreen", is_fullscreen)
    if not is_fullscreen:
        app.geometry("800x600")  # Default size when not fullscreen


# Function to clear previous results
def clear_results():
    for widget in result_frame_container.winfo_children():
        widget.destroy()


# Function to display results in a Treeview
def display_results(columns, results):
    tree = ttk.Treeview(result_frame_container, columns=columns, show="headings")
    for col in columns:
        tree.heading(col, text=col)
        tree.column(col, anchor=tk.W)
    for row in results:
        tree.insert("", tk.END, values=row)

    tree.pack(side="left", fill=tk.BOTH, expand=True)

    h_scroll = ttk.Scrollbar(
        result_frame_container, orient="horizontal", command=tree.xview
    )
    v_scroll = ttk.Scrollbar(
        result_frame_container, orient="vertical", command=tree.yview
    )
    tree.configure(xscrollcommand=h_scroll.set, yscrollcommand=v_scroll.set)

    h_scroll.pack(side="bottom", fill="x")
    v_scroll.pack(side="right", fill="y")


# Define database query functions
def query_ficha_limpa():
    try:
        cursor = conn.cursor()

        query = "SELECT i.nome, i.cpf FROM individuo i LEFT JOIN individuo_processos ip ON I.cpf = ip.cpf LEFT JOIN processojuridico p ON ip.processoid = p.processoid WHERE p.procedente = FALSE OR p.procedente IS NULL"

        print(f"Executing query: {query}")

        cursor.execute(query)
        results = cursor.fetchall()
        columns = [desc[0] for desc in cursor.description]

        print(f"Query Results: {results}")

        display_results(columns, results)

        cursor.close()

    except Exception as e:
        print(f"Error querying the database: {e}")


def query_relatorio_candidatura():
    try:
        cursor = conn.cursor()

        query = "SELECT i.nome, i.cpf, carg.nome, i2.nome, i2.cpf , cand.eleito FROM candidatura cand LEFT JOIN individuo i ON cand.cpf = i.cpf JOIN cargo carg ON cand.cargoid = carg.cargoid LEFT JOIN individuo i2 ON cand.vice = i2.cpf"

        print(f"Executing query: {query}")

        cursor.execute(query)
        results = cursor.fetchall()

        columns = ["nome", "cpf", "cargo", "vice", "vice cpf", "eleito"]

        print(f"Query Results: {results}")
        print(columns)
        display_results(columns, results)

        cursor.close()

    except Exception as e:
        print(f"Error querying the database: {e}")


def query_candidaturas_variable(selections):
    try:
        cursor = conn.cursor()
        query = "SELECT i.nome, i.cpf, carg.nome, cand.ano FROM candidatura cand LEFT JOIN individuo i ON cand.cpf = i.cpf JOIN cargo carg ON cand.cargoid = carg.cargoid WHERE "
        conditions = []
        if "ano" in selections:
            conditions.append("cand.ano IN (%s)" % ",".join(selections["ano"]))
        if "nome" in selections:
            conditions.append(
                "UPPER(i.nome) IN (UPPER(%s))"
                % ",".join("'%s'" % name for name in selections["nome"])
            )
        if "cargo" in selections:
            conditions.append(
                "UPPER(carg.nome) IN (UPPER(%s))"
                % ",".join("'%s'" % cargo for cargo in selections["cargo"])
            )

        query += " AND ".join(conditions)

        # Add sorting option
        if "sort_by" in selections:
            if "nome" in selections["sort_by"]:
                query += f" ORDER BY i.nome"
            elif "cargo" in selections["sort_by"]:
                query += f" ORDER BY carg.nome"
            else:
                query += f" ORDER BY ano"

        print(f"Executing query: {query}")
        cursor.execute(query)
        results = cursor.fetchall()
        columns = ["nome", "cpf", "cargo", "ano"]
        print(f"Query Results: {results}")
        display_results(columns, results)
        cursor.close()
    except Exception as e:
        print(f"Error querying the database: {e}")


def remove_data(table, conditions):
    try:
        cursor = conn.cursor()
        query = f"DELETE FROM {table} WHERE {conditions}"
        print(f"Executing query: {query}")
        cursor.execute(query)
        conn.commit()
        print(f"Removed data from {table} where {conditions}")
        cursor.close()
    except Exception as e:
        print(f"Error removing data from the database: {e}")


def list_all_data(table):
    try:
        cursor = conn.cursor()
        query = f"SELECT * FROM {table}"
        print(f"Executing query: {query}")
        cursor.execute(query)
        results = cursor.fetchall()
        columns = [desc[0] for desc in cursor.description]
        print(f"Query Results: {results}")
        display_results(columns, results)
        cursor.close()
    except Exception as e:
        print(f"Error listing all data from the database: {e}")


def list_data(table, conditions):
    try:
        cursor = conn.cursor()
        query = f"SELECT * FROM {table} WHERE {conditions}"
        print(f"Executing query: {query}")
        cursor.execute(query)
        results = cursor.fetchall()
        columns = [desc[0] for desc in cursor.description]
        print(f"Query Results: {results}")
        display_results(columns, results)
        cursor.close()
    except Exception as e:
        print(f"Error listing data from the database: {e}")


def sair():
    try:
        # Close the database connection
        if conn:
            conn.close()
            print("Database connection closed.")
    except Exception as e:
        print(f"Error closing the database connection: {e}")
    finally:
        # Close the application
        app.quit()


if __name__ == "__main__":
    # Create main application window
    app = tk.Tk()
    app.title("Menu App with Dropdown")
    app.attributes("-fullscreen", True)

    # Bind the Escape key to exit fullscreen
    app.bind("<Escape>", toggle_fullscreen)

    # Create a menu
    menu_bar = tk.Menu(app)
    app.config(menu=menu_bar)

    # Add menu options
    file_menu = tk.Menu(menu_bar, tearoff=0)
    menu_bar.add_cascade(label="Funcionalidades", menu=file_menu)

    file_menu.add_command(
        label="Listagem Candidatura",
        command=lambda: menu_selected("Listagem Candidatura"),
    )
    file_menu.add_command(
        label="Geração de relatórios",
        command=lambda: menu_selected("Geração de relatórios"),
    )
    file_menu.add_command(
        label="Listar ficha limpa", command=lambda: menu_selected("Listar ficha limpa")
    )
    file_menu.add_command(
        label="Busca ou remoção", command=lambda: menu_selected("Busca ou remoção")
    )
    file_menu.add_command(
        label="Busca por data", command=lambda: menu_selected("Busca por data")
    )
    file_menu.add_command(
        label="Remoção por data", command=lambda: menu_selected("Remoção por data")
    )
    file_menu.add_command(label="Sair", command=lambda: menu_selected("Sair"))

    # Frame to show dropdown options
    option_frame = tk.Frame(app)
    option_frame.pack(pady=20)

    # Frame to show saved selections with scrollbar
    result_frame_container = tk.Frame(app)
    result_frame_container.pack(pady=20, fill="both", expand=True)

    result_canvas = tk.Canvas(result_frame_container)
    result_scrollbar_y = ttk.Scrollbar(
        result_frame_container, orient="vertical", command=result_canvas.yview
    )
    result_scrollbar_x = ttk.Scrollbar(
        result_frame_container, orient="horizontal", command=result_canvas.xview
    )
    result_frame = tk.Frame(result_canvas)

    result_frame.bind(
        "<Configure>",
        lambda e: result_canvas.configure(scrollregion=result_canvas.bbox("all")),
    )

    result_canvas.create_window((0, 0), window=result_frame, anchor="nw")
    result_canvas.configure(
        yscrollcommand=result_scrollbar_y.set, xscrollcommand=result_scrollbar_x.set
    )

    result_canvas.pack(side="left", fill="both", expand=True)
    result_scrollbar_y.pack(side="right", fill="y")
    result_scrollbar_x.pack(side="bottom", fill="x")

    # Run the application
    app.mainloop()
