import tkinter as tk
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg

# generates a user interface to select the fire seasons months.
# his also has a graph for each year which corresponds to the number of burnt pixels per month in our AOI
# the graph is embedded into the user interface above the buttons.

# inspiration and code adapted from: cosine1509 (2020)
# found at: https://www.geeksforgeeks.org/how-to-embed-matplotlib-charts-in-tkinter-gui/

def generate_UI(fig):

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
        window.quit()  # force end the main loop
        window.destroy()


    # create the main window
    window = tk.Tk()

    # embed the matplotlib figure on a canvas in the tkinter window
    canvas = FigureCanvasTkAgg(fig, master=window)
    canvas_widget = canvas.get_tk_widget()
    canvas_widget.pack(pady=20)

    months = ['January', 'February', 'March', 'April',
              'May', 'June', 'July', 'August',
              'September', 'October', 'November', 'December']

    month_codes = ['Jan', 'Feb', 'Mar', 'Apr',
                   'May', 'Jun', 'Jul', 'Aug',
                   'Sep', 'Oct', 'Nov', 'Dec']

    selected_months = []
    selected_month_codes = []

    # create the label for the instruction
    instruction_label = tk.Label(window, text="Please select the months that correspond to the fire season")
    instruction_label.pack(pady=10)

    # create the buttons
    buttons_frame = tk.Frame(window)
    buttons_frame.pack()

    for i, month in enumerate(months):
        button = tk.Button(buttons_frame, text=month, width=10, height=2,
                           command=lambda m=month, c=month_codes[i]: button_click(m, c))
        button.grid(row=i // 4, column=i % 4, padx=5, pady=5)

    # create a button to delete the previous month
    delete_button = tk.Button(window, text="Delete Previous Month", command=delete_last_month)
    delete_button.pack(pady=5)

    # create a label for the selected months
    selected_label = tk.Label(window, text="Selected months:")
    selected_label.pack()

    # create a label to show the selected months
    label = tk.Label(window, text='')
    label.pack()

    # create a button to close the window:

    finish = tk.Button(window, text="Finish", command=close_window)
    finish.pack(pady=10)

    return window, selected_month_codes
