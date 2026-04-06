import tkinter as tk
import intel_jtag_uart
import threading
from collections import deque

class QPDVisualizer:
    def __init__(self, root):
        self.root = root
        self.root.title("Nios V Laser Tracker - Filtered Monitor")
        
        # Calibration and Filtering
        self.offset_x = 0.0
        self.offset_y = 0.0
        self.window_size = 10  # Number of samples to average (higher = smoother but slower)
        self.history_x = deque(maxlen=self.window_size)
        self.history_y = deque(maxlen=self.window_size)
        
        # Setup GUI
        self.canvas = tk.Canvas(root, width=400, height=400, bg="black")
        self.canvas.pack(pady=10)
        self.draw_target()
        
        self.dot = self.canvas.create_oval(195, 195, 205, 205, fill="red", outline="white")
        
        # Status and Value Labels
        self.status_var = tk.StringVar(value="STATUS: DISCONNECTED")
        self.status_label = tk.Label(root, textvariable=self.status_var, font=("Arial", 12, "bold"), fg="orange")
        self.status_label.pack()

        self.label_var = tk.StringVar(value="Waiting for JTAG...")
        self.label = tk.Label(root, textvariable=self.label_var, font=("Courier", 10))
        self.label.pack()
        
        tk.Button(root, text="Zero / Calibrate Center", command=self.zero_values).pack(pady=5)

        try:
            self.ju = intel_jtag_uart.intel_jtag_uart()
            self.running = True
            self.thread = threading.Thread(target=self.read_jtag, daemon=True)
            self.thread.start()
        except Exception as e:
            self.status_var.set("STATUS: JTAG ERROR")
            self.label_var.set(f"{e}")

    def draw_target(self):
        self.canvas.create_line(200, 0, 200, 400, fill="gray40")
        self.canvas.create_line(0, 200, 400, 200, fill="gray40")
        for r in [50, 100, 150]:
            self.canvas.create_oval(200-r, 200-r, 200+r, 200+r, outline="gray30")

    def read_jtag(self):
        buffer = ""
        while self.running:
            data = self.ju.read()
            if data:
                buffer += data.decode('utf-8', errors='ignore')
                if "\n" in buffer:
                    lines = buffer.split("\n")
                    self.process_line(lines[-2])
                    buffer = lines[-1]

    def process_line(self, line):
        try:
            # Cleaning the string from your specific format (pipes and spaces)
            raw_parts = line.replace('|', ' ').split()
            if len(raw_parts) >= 4:
                tr, br, bl, tl = map(float, raw_parts[:4])
                total = tr + br + tl + bl
                
                # Range Check
                if total < 50:
                    self.status_var.set("STATUS: OUT OF RANGE (LOW SIGNAL)")
                    self.status_label.config(fg="red")
                    self.canvas.itemconfig(self.dot, state='hidden')
                else:
                    self.status_var.set("STATUS: TRACKING")
                    self.status_label.config(fg="green")
                    self.canvas.itemconfig(self.dot, state='normal')
                    
                    # Calculate raw position
                    raw_x = ((tr + br) - (tl + bl)) / total
                    raw_y = ((tr + tl) - (br + bl)) / total if 'BR' not in locals() else ((tr + tl) - (br + bl)) / total
                    
                    # Apply Moving Average Filter
                    #self.history_x.append(raw_x)
                    #self.history_y.append(raw_y)
                    
                    #avg_x = sum(self.history_x) / len(self.history_x)
                    #avg_y = sum(self.history_y) / len(self.history_y)
                    
                    self.update_dot(raw_x, raw_y)
                
                self.label_var.set(f"TR:{int(tr)} BR:{int(br)} TL:{int(tl)} BL:{int(bl)} Sum:{int(total)}")
        except (ValueError, IndexError):
            pass

    def update_dot(self, x, y):
        # Constraints to keep dot on screen even if filtered values go slightly wild
        x = max(min(x, 1.1), -1.1)
        y = max(min(y, 1.1), -1.1)
        
        screen_x = 200 + (x * 180)
        screen_y = 200 - (y * 180)
        self.canvas.coords(self.dot, screen_x-6, screen_y-6, screen_x+6, screen_y+6)

    def zero_values(self):
        if len(self.history_x) > 0:
            self.offset_x = sum(self.history_x) / len(self.history_x)
            self.offset_y = sum(self.history_y) / len(self.history_y)

if __name__ == "__main__":
    root = tk.Tk()
    app = QPDVisualizer(root)
    root.mainloop()