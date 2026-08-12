from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


SOURCE = Path(r"E:\bs_innovation\.tmp_patent_cache\final_render_v4")
OUT = Path(r"E:\bs_innovation\.tmp_patent_cache\final_contact_sheets_v4")
OUT.mkdir(parents=True, exist_ok=True)

pages = sorted(SOURCE.glob("page-*.png"))
font_path = Path(r"C:\Windows\Fonts\arial.ttf")
font = ImageFont.truetype(str(font_path), 22) if font_path.exists() else ImageFont.load_default()

thumb_width = 560
label_height = 38
gap = 24
cols = 2
per_sheet = 6

for sheet_index in range(0, len(pages), per_sheet):
    group = pages[sheet_index : sheet_index + per_sheet]
    thumbs = []
    for page in group:
        image = Image.open(page).convert("RGB")
        height = round(image.height * thumb_width / image.width)
        image = image.resize((thumb_width, height), Image.Resampling.LANCZOS)
        panel = Image.new("RGB", (thumb_width, height + label_height), "white")
        panel.paste(image, (0, label_height))
        draw = ImageDraw.Draw(panel)
        draw.text((8, 6), page.stem, fill="black", font=font)
        thumbs.append(panel)

    rows = (len(thumbs) + cols - 1) // cols
    cell_height = max(panel.height for panel in thumbs)
    sheet = Image.new(
        "RGB",
        (cols * thumb_width + (cols + 1) * gap, rows * cell_height + (rows + 1) * gap),
        (220, 220, 220),
    )
    for idx, panel in enumerate(thumbs):
        x = gap + (idx % cols) * (thumb_width + gap)
        y = gap + (idx // cols) * (cell_height + gap)
        sheet.paste(panel, (x, y))
    target = OUT / f"sheet-{sheet_index // per_sheet + 1:02d}.png"
    sheet.save(target)
    print(target)
