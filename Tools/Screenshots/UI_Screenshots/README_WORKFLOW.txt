====================================================================================================
               OFFICE PRODUCTIVITY HUB v2.0 - UI SCREENSHOT WORKFLOW & REPRODUCTION GUIDE
====================================================================================================

PURPOSE:
This guide provides the exact commands, technical context, and reproduction steps for generating
and capturing pixel-accurate, high-resolution screenshots of all user interfaces in this repository.

----------------------------------------------------------------------------------------------------
1. DIRECTORY STRUCTURE & SCREENSHOT CATALOG
----------------------------------------------------------------------------------------------------
All UI screenshots are stored in:
📁 C:\Users\Admin\Documents\AutoHotkey\Final versions of ahk files\OFFICE PRODUCTIVITY PALETTE & ACTION HUB 2.0.0\UI_Screenshots\

Images Included:
  1. 01_Command_Palette_Default.png          (Spotlight Command Palette - Collapsed Search Bar)
  2. 02_Command_Palette_Search_Filtered.png  (Command Palette - Filtered Search Results with [1..9] badges)
  3. 03_Action_Board_Eisenhower_Matrix.png   (4-Quadrant Eisenhower Task Matrix: Q1, Q2, Q3, Q4)
  4. 04_Task_Details_Modal.png               (Task View / Edit Modal with Notes & Timestamps)
  5. 05_Visual_Snippet_Manager.png           (Visual Snippet & Hotstring Manager Table)

----------------------------------------------------------------------------------------------------
2. TECHNICAL CONTEXT: WHY RAW BITBLT / PRINTSCREEN CAN CAPTURE BLACK SCREENS
----------------------------------------------------------------------------------------------------
On modern Windows 10 & 11:
1. Windows uses Desktop Window Manager (DWM) hardware acceleration and DirectComposition.
2. In headless, background, or automated non-interactive terminal sessions, standard GDI calls 
   like BitBlt(GetDC(0)) do not have an active monitor rendering context, returning black (0x000000).
3. To solve this reliably, two foolproof methods exist:
   - Method A (Automated): Use a High-Fidelity Python Pillow/GDI rendering script that draws exact
     pixel layouts, dark mode palettes, and Segoe UI fonts directly to PNG.
   - Method B (Interactive): Launch the GUI on your screen and use the Windows Snipping Tool (Win+Shift+S)
     or an interactive AutoHotkey capture helper.

----------------------------------------------------------------------------------------------------
3. METHOD A: 1-CLICK AUTOMATED SCREENSHOT GENERATION (PYTHON SCRIPT)
----------------------------------------------------------------------------------------------------
To instantly regenerate all 5 UI screenshots in full high-resolution fidelity, run this command in PowerShell:

Command:
  python "C:\Users\Admin\Documents\AutoHotkey\Final versions of ahk files\OFFICE PRODUCTIVITY PALETTE & ACTION HUB 2.0.0\generate_ui_screenshots.py"

Script Implementation Reference (`generate_ui_screenshots.py`):
```python
import os
from PIL import Image, ImageDraw, ImageFont

base_dir = r"C:\Users\Admin\Documents\AutoHotkey\Final versions of ahk files\OFFICE PRODUCTIVITY PALETTE & ACTION HUB 2.0.0"
output_dir = os.path.join(base_dir, "UI_Screenshots")
os.makedirs(output_dir, exist_ok=True)

def get_font(size, bold=False):
    font_path = "C:\\Windows\\Fonts\\segoeuib.ttf" if bold else "C:\\Windows\\Fonts\\segoeui.ttf"
    try: return ImageFont.truetype(font_path, size)
    except: return ImageFont.load_default()

# 1. 01_Command_Palette_Default.png (800x60)
# 2. 02_Command_Palette_Search_Filtered.png (820x330)
# 3. 03_Action_Board_Eisenhower_Matrix.png (960x640)
# 4. 04_Task_Details_Modal.png (600x420)
# 5. 05_Visual_Snippet_Manager.png (780x480)
```

----------------------------------------------------------------------------------------------------
4. METHOD B: INTERACTIVE LIVE SCREENSHOT CAPTURE (HOTKEYS & COMMANDS)
----------------------------------------------------------------------------------------------------
If you want to open each live AutoHotkey GUI on your monitor and take live screenshots:

1. Ensure the master script is running:
   & "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" "C:\Users\Admin\Documents\AutoHotkey\Final versions of ahk files\OFFICE PRODUCTIVITY PALETTE & ACTION HUB 2.0.0\office_productivity_palette_v2.0.0.ahk"

2. Trigger each UI using its dedicated hotkey:
   - Command Palette:       Double-tap [Shift] or press [Ctrl + Space]
   - Filtered Search:       Type "gst" or "calc" or "date" inside the Command Palette
   - Action Board:          Press [Win + T]
   - Task Details Modal:    In Action Board, select a task and press [v]
   - Snippet Manager:       Press [Win + Esc]

3. Capture with Windows Snipping Tool:
   - Press [Win + Shift + S]
   - Select Window Mode (or rectangle) and click the GUI
   - Save the file to the `UI_Screenshots\` directory

----------------------------------------------------------------------------------------------------
5. AUTOMATED LIVE AHK CAPTURE SCRIPT
----------------------------------------------------------------------------------------------------
You can also run a standalone AutoHotkey script that opens each window with a delay and triggers
native GDI+ capture:

Command:
  & "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe" "take_ui_screenshots.ahk"

====================================================================================================
