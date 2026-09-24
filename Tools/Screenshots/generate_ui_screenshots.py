# ======================================================================================================================
# Automated UI Screenshot Generator for Office Productivity Hub v2.0
# ======================================================================================================================
import os
from PIL import Image, ImageDraw, ImageFont

base_dir = os.path.dirname(os.path.abspath(__file__))
output_dir = os.path.join(base_dir, "UI_Screenshots")
os.makedirs(output_dir, exist_ok=True)

def get_font(size, bold=False):
    font_path = "C:\\Windows\\Fonts\\segoeuib.ttf" if bold else "C:\\Windows\\Fonts\\segoeui.ttf"
    try: return ImageFont.truetype(font_path, size)
    except: return ImageFont.load_default()

def render_command_palette_default():
    w, h = 800, 60
    img = Image.new("RGBA", (w, h), (30, 30, 30, 255))
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, w-1, h-1], outline=(70, 70, 70, 255), width=1)
    draw.rectangle([10, 10, w-10, h-10], fill=(45, 45, 45, 255), outline=(60, 60, 60, 255), width=1)
    draw.text((22, 18), "Search 50+ actions, hotstrings, or tools (e.g. gst, calc, date, pan)...", fill=(150, 150, 150, 255), font=get_font(15))
    img.save(os.path.join(output_dir, "01_Command_Palette_Default.png"), "PNG")

def render_command_palette_search():
    w, h = 820, 330
    img = Image.new("RGBA", (w, h), (30, 30, 30, 255))
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, w-1, h-1], outline=(70, 70, 70, 255), width=1)
    draw.rectangle([10, 10, w-10, 46], fill=(45, 45, 45, 255), outline=(0, 122, 204, 255), width=1)
    draw.text((22, 17), "gst", fill=(255, 255, 255, 255), font=get_font(15, bold=True))
    draw.rectangle([10, 52, w-10, 285], fill=(37, 37, 38, 255), outline=(50, 50, 50, 255), width=1)
    draw.rectangle([10, 52, w-10, 80], fill=(45, 45, 48, 255))
    draw.text((20, 58), "#", fill=(170, 170, 170, 255), font=get_font(12))
    draw.text((55, 58), "Action Name", fill=(170, 170, 170, 255), font=get_font(12))
    draw.text((275, 58), "Category", fill=(170, 170, 170, 255), font=get_font(12))
    draw.text((385, 58), "Description & Usage Tip", fill=(170, 170, 170, 255), font=get_font(12))
    draw.text((710, 58), "Shortcut", fill=(170, 170, 170, 255), font=get_font(12))
    items = [
        ("[1]", "Reverse GST Calculator (18%)", "Finance", "Extracts base amount and GST from gross", "Ctrl+; -> g"),
        ("[2]", "Reverse GST Calculator (12%)", "Finance", "Calculates 12% reverse GST from total", "gst12"),
        ("[3]", "Reverse GST Calculator (5%)",  "Finance", "Calculates 5% reverse GST from total", "gst5"),
        ("[4]", "Extract All GSTIN Numbers",    "Extraction", "Finds and copies all 15-char GSTINs", "gstin"),
        ("[5]", "Validate GSTIN Checksum",     "Finance", "Verifies state code & structure of GSTIN", "gstchk"),
        ("[6]", "Current Financial Year (FY)",  "Finance", "Inserts Indian FY (e.g. FY 2026-27)", "Ctrl+; -> f")
    ]
    y = 86
    for idx, (num, name, cat, desc, sc) in enumerate(items):
        if idx == 0:
            draw.rectangle([11, y-4, w-11, y+25], fill=(9, 71, 113, 255))
        draw.text((20, y), num, fill=(115, 218, 202, 255) if idx==0 else (160, 160, 160, 255), font=get_font(13, bold=True))
        draw.text((55, y), name, fill=(255, 255, 255, 255), font=get_font(14))
        draw.text((275, y), cat, fill=(200, 200, 200, 255), font=get_font(14))
        draw.text((385, y), desc, fill=(180, 180, 180, 255), font=get_font(14))
        draw.text((710, y), sc, fill=(255, 198, 109, 255), font=get_font(14))
        y += 31
    draw.text((20, 298), "Tap [1..6] or [Enter] to Execute | [Up/Down] Navigate | [Esc] Dismiss", fill=(140, 140, 140, 255), font=get_font(12))
    img.save(os.path.join(output_dir, "02_Command_Palette_Search_Filtered.png"), "PNG")

def render_action_board():
    w, h = 960, 640
    img = Image.new("RGBA", (w, h), (24, 24, 24, 255))
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, w-1, h-1], outline=(60, 60, 60, 255), width=1)
    draw.rectangle([0, 0, w, 44], fill=(30, 30, 30, 255))
    draw.text((20, 12), "Action Board — 4-Quadrant Eisenhower Matrix", fill=(255, 255, 255, 255), font=get_font(16, bold=True))
    draw.text((w-240, 15), "Hotkeys: 1-4 Move | Space Done | Del", fill=(150, 150, 150, 255), font=get_font(11))
    draw.rectangle([20, 56, w-20, 92], fill=(37, 37, 38, 255), outline=(55, 55, 55, 255), width=1)
    draw.text((32, 64), "+ Add new task (e.g. 'Submit GST report by 5pm #Q1' or double-tap Ctrl)...", fill=(140, 140, 140, 255), font=get_font(12))
    half_w = (w - 55) // 2
    quad_h = 220
    quadrants = [
        ("Q1: DO NOW (Urgent & Important)", 20, 108, half_w, quad_h, (50, 25, 25, 255), (255, 120, 120, 255), [
            ("Finalize quarterly audit filing", "Due: Today", "URGENT"),
            ("Resolve client invoice discrepancy", "Due: 2:00 PM", "URGENT"),
            ("Submit board presentation deck", "Due: 5:30 PM", "HIGH")
        ]),
        ("Q2: PLAN (Important & Not Urgent)", 20 + half_w + 15, 108, half_w, quad_h, (25, 35, 50, 255), (100, 180, 255, 255), [
            ("Draft Q3 financial growth strategy", "Due: Friday", "STRATEGY"),
            ("Review team performance metrics", "Due: Next Week", "PLAN"),
            ("Research automation tooling for office", "Due: Oct 15", "DEV")
        ]),
        ("Q3: DELEGATE (Urgent & Not Important)", 20, 108 + quad_h + 15, half_w, quad_h, (45, 40, 20, 255), (255, 215, 0, 255), [
            ("Schedule vendor sync meeting", "Assign: Raj", "DELEGATE"),
            ("Forward shipping manifests to logistics", "Assign: Priya", "OPS")
        ]),
        ("Q4: ELIMINATE (Not Urgent & Not Important)", 20 + half_w + 15, 108 + quad_h + 15, half_w, quad_h, (25, 45, 30, 255), (100, 220, 130, 255), [
            ("Archive old Outlook newsletter folders", "Low Priority", "CLEANUP"),
            ("Unsubscribe from redundant mailing lists", "Optional", "MAINT")
        ])
    ]
    for title, qx, qy, qw, qh, bg_col, title_col, tasks in quadrants:
        draw.rectangle([qx, qy, qx+qw, qy+qh], fill=bg_col, outline=(55, 55, 60, 255), width=1)
        draw.rectangle([qx, qy, qx+qw, qy+28], fill=(32, 32, 35, 255))
        draw.text((qx+10, qy+6), title, fill=title_col, font=get_font(13, bold=True))
        ty = qy + 36
        for task_title, meta, badge in tasks:
            draw.rectangle([qx+8, ty-2, qx+qw-8, ty+24], fill=(38, 38, 42, 255), outline=(48, 48, 52, 255), width=1)
            draw.text((qx+16, ty+2), "[ ] " + task_title, fill=(235, 235, 235, 255), font=get_font(12))
            draw.text((qx+qw-110, ty+3), meta, fill=(150, 150, 150, 255), font=get_font(11))
            ty += 30
    draw.rectangle([0, h-32, w, h], fill=(28, 28, 28, 255))
    draw.text((20, h-24), "Tasks Total: 10 | Completed Today: 4 | Press 'v' to view/edit full task notes | Esc to close", fill=(140, 140, 140, 255), font=get_font(11))
    img.save(os.path.join(output_dir, "03_Action_Board_Eisenhower_Matrix.png"), "PNG")

def render_task_modal():
    w, h = 600, 420
    img = Image.new("RGBA", (w, h), (32, 32, 32, 255))
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, w-1, h-1], outline=(0, 122, 204, 255), width=1)
    draw.rectangle([0, 0, w, 38], fill=(45, 45, 48, 255))
    draw.text((20, 10), "Task Details & Notes", fill=(255, 255, 255, 255), font=get_font(15, bold=True))
    y = 52
    draw.text((24, y), "Task Summary:", fill=(180, 180, 180, 255), font=get_font(13, bold=True))
    draw.rectangle([24, y+20, w-24, y+52], fill=(45, 45, 48, 255), outline=(65, 65, 70, 255), width=1)
    draw.text((34, y+27), "Finalize quarterly audit filing and submit to accounts", fill=(255, 255, 255, 255), font=get_font(13))
    y += 66
    draw.text((24, y), "Quadrant Priority:", fill=(180, 180, 180, 255), font=get_font(13, bold=True))
    draw.rectangle([24, y+20, 260, y+52], fill=(45, 45, 48, 255), outline=(65, 65, 70, 255), width=1)
    draw.text((34, y+27), "Q1 — Urgent & Important", fill=(255, 120, 120, 255), font=get_font(13))
    draw.text((300, y), "Due Date / Time:", fill=(180, 180, 180, 255), font=get_font(13, bold=True))
    draw.rectangle([300, y+20, w-24, y+52], fill=(45, 45, 48, 255), outline=(65, 65, 70, 255), width=1)
    draw.text((310, y+27), "Today (5:00 PM)", fill=(255, 215, 0, 255), font=get_font(13))
    y += 66
    draw.text((24, y), "Detailed Description & Context Notes:", fill=(180, 180, 180, 255), font=get_font(13, bold=True))
    draw.rectangle([24, y+20, w-24, y+110], fill=(45, 45, 48, 255), outline=(65, 65, 70, 255), width=1)
    draw.text((34, y+28), "Captured via Double-Ctrl from client email.\nNeed to verify invoice #INV-2026-894 before signing off.\nContact CA Sharma if reverse GST calculation shows variance.", fill=(220, 220, 220, 255), font=get_font(13))
    y = h - 55
    draw.rectangle([24, y, 160, y+34], fill=(0, 122, 204, 255))
    draw.text((45, y+8), "Save Changes", fill=(255, 255, 255, 255), font=get_font(13, bold=True))
    draw.rectangle([175, y, 280, y+34], fill=(180, 40, 40, 255))
    draw.text((195, y+8), "Delete Task", fill=(255, 255, 255, 255), font=get_font(13, bold=True))
    draw.rectangle([w-120, y, w-24, y+34], fill=(60, 60, 65, 255))
    draw.text((w-95, y+8), "Close", fill=(220, 220, 220, 255), font=get_font(13))
    img.save(os.path.join(output_dir, "04_Task_Details_Modal.png"), "PNG")

def render_snippet_manager():
    w, h = 780, 480
    img = Image.new("RGBA", (w, h), (240, 240, 240, 255))
    draw = ImageDraw.Draw(img)
    draw.text((16, 16), "Filter:", fill=(50, 50, 50, 255), font=get_font(13, bold=True))
    draw.rectangle([75, 12, w-16, 38], fill=(255, 255, 255, 255), outline=(170, 170, 170, 255), width=1)
    draw.text((85, 17), "Type to search triggers or expansions...", fill=(150, 150, 150, 255), font=get_font(12))
    draw.rectangle([16, 48, w-16, h-70], fill=(255, 255, 255, 255), outline=(180, 180, 180, 255), width=1)
    draw.rectangle([16, 48, w-16, 76], fill=(230, 230, 230, 255))
    draw.text((28, 55), "Trigger", fill=(60, 60, 60, 255), font=get_font(13, bold=True))
    draw.text((140, 55), "Replacement Expansion Text", fill=(60, 60, 60, 255), font=get_font(13, bold=True))
    draw.text((670, 55), "Enabled", fill=(60, 60, 60, 255), font=get_font(13, bold=True))
    snippets = [
        ("gmd", "generate markdown code for content below as per instruction provided", "True"),
        ("fif", "follow exact instruction as in file provided", "True"),
        ("tdate", "Inserts current date YYYY-MM-DD (e.g. 2026-08-23)", "True"),
        ("ttime", "Inserts current 12-hour time (e.g. 07:15 PM)", "True"),
        ("rgst18", "Reverse GST Calculation (Base + 18% GST breakdown)", "True"),
        ("sig1", "Best regards,\nDr. Alex Sterling | Principal Consultant", "True"),
        ("zoomlnk", "https://zoom.us/j/984210984?pwd=meetingsync", "True"),
        ("panchk", "Validate PAN format: [A-Z]{5}[0-9]{4}[A-Z]{1}", "True")
    ]
    y = 86
    for idx, (trig, repl, en) in enumerate(snippets):
        if idx % 2 == 1:
            draw.rectangle([17, y-4, w-17, y+24], fill=(248, 248, 250, 255))
        draw.text((28, y), ":" + trig + ":", fill=(0, 102, 204, 255), font=get_font(13, bold=True))
        draw.text((140, y), repl.replace('\n', ' -> '), fill=(40, 40, 40, 255), font=get_font(12))
        draw.text((685, y), "Yes", fill=(0, 130, 0, 255), font=get_font(13, bold=True))
        y += 30
    by = h - 55
    btn_defs = [
        ("Add", 16, 75), ("Edit", 98, 75), ("Delete", 180, 75), ("Toggle", 262, 75),
        ("Import CSV", 430, 95), ("Export CSV", 535, 95), ("Help", 640, 120)
    ]
    for label, bx, bw in btn_defs:
        draw.rectangle([bx, by, bx+bw, by+30], fill=(240, 240, 240, 255), outline=(170, 170, 170, 255), width=1)
        draw.text((bx + (bw - len(label)*7)//2, by+6), label, fill=(30, 30, 30, 255), font=get_font(12))
    draw.rectangle([0, h-22, w, h], fill=(225, 225, 225, 255))
    draw.text((16, h-18), "Ready — 8 Snippets Loaded | Press Win+Esc to toggle", fill=(90, 90, 90, 255), font=get_font(11))
    img.save(os.path.join(output_dir, "05_Visual_Snippet_Manager.png"), "PNG")

if __name__ == "__main__":
    render_command_palette_default()
    render_command_palette_search()
    render_action_board()
    render_task_modal()
    render_snippet_manager()
    print("All screenshots generated.")
