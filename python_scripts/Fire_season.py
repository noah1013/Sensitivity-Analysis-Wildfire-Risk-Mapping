import tkinter as tk

def generate_UI():

    def button_click(month, month_code):
        selected_months.append(month)
        selected_month_codes.append(month_code)
        update_label()

    def delete_last_month():
        if selected_months:
            selected_months.pop()
            selected_month_codes.pop()
            update_label()

    def update_label():
        label.config(text=', '.join(selected_months))

    def close_window():
        window.destroy()

    # Create the main window
    window = tk.Tk()

    months = ['January', 'February', 'March', 'April',
              'May', 'June', 'July', 'August',
              'September', 'October', 'November', 'December']

    month_codes = ['Jan', 'Feb', 'Mar', 'Apr',
                   'May', 'Jun', 'Jul', 'Aug',
                   'Sep', 'Oct', 'Nov', 'Dec']

    selected_months = []
    selected_month_codes = []

    # Create the label for the instruction
    instruction_label = tk.Label(window, text="Please select the months that correspond to the fire season")
    instruction_label.pack(pady=10)

    # Create the buttons
    buttons_frame = tk.Frame(window)
    buttons_frame.pack()

    for i, month in enumerate(months):
        button = tk.Button(buttons_frame, text=month, width=10, height=2,
                           command=lambda m=month, c=month_codes[i]: button_click(m, c))
        button.grid(row=i // 4, column=i % 4, padx=5, pady=5)

    # Create the "Delete Last Month" button
    delete_button = tk.Button(window, text="Delete Previous Month", command=delete_last_month)
    delete_button.pack(pady=5)

    # Create the label for the selected months
    selected_label = tk.Label(window, text="Selected months:")
    selected_label.pack()

    # Create the label to show the selected months
    label = tk.Label(window, text='')
    label.pack()

    # Create the button to close the window:

    finish = tk.Button(window, text="Finish", command=close_window)
    finish.pack(pady=10)

    return window, selected_month_codes
