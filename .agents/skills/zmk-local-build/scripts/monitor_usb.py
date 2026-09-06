import os
import sys
import glob
import time
import threading
import serial

COLOR_MAP = {
    0: "\033[36m", # Cyan
    1: "\033[32m", # Green
    2: "\033[33m", # Yellow
    3: "\033[35m", # Magenta
}
RESET = "\033[0m"

def monitor_port(port, idx):
    color = COLOR_MAP.get(idx % len(COLOR_MAP), "")
    tag = f"{color}[{os.path.basename(port)}]{RESET}"
    
    while True:
        try:
            if not os.path.exists(port):
                time.sleep(1)
                continue
            
            print(f"{tag} Connecting to {port}...")
            with serial.Serial(port, 115200, timeout=1) as ser:
                print(f"{tag} Connected! Listening for logs...")
                while True:
                    line = ser.readline()
                    if line:
                        try:
                            decoded = line.decode('utf-8', errors='replace').rstrip()
                            if decoded:
                                ts = time.strftime("%H:%M:%S")
                                print(f"{tag} [{ts}] {decoded}", flush=True)
                        except Exception as e:
                            pass
        except serial.SerialException:
            time.sleep(1)
        except Exception as e:
            time.sleep(1)

def main():
    print("=== Multi-Port ZMK USB Debug Logger Started ===", flush=True)
    threads = {}
    
    while True:
        ports = sorted(glob.glob("/dev/cu.usbmodem*"))
        for idx, port in enumerate(ports):
            if port not in threads or not threads[port].is_alive():
                t = threading.Thread(target=monitor_port, args=(port, idx), daemon=True)
                threads[port] = t
                t.start()
        time.sleep(2)

if __name__ == "__main__":
    main()
