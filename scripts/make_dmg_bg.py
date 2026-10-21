from PIL import Image, ImageDraw, ImageFont
import os

# 画布加宽到 820x440：左侧 ~170px 预留给 Finder 侧边栏遮挡区域
W, H = 820, 440
img = Image.new("RGB", (W, H), (238, 243, 250))
d = ImageDraw.Draw(img)

# 整体垂直渐变：浅天蓝 -> 深一点的蓝
for y in range(H):
    t = y / H
    r = int(238 - t * 70)
    g = int(243 - t * 80)
    b = int(250 - t * 70)
    d.line([(0, y), (W, y)], fill=(r, g, b))

d.rectangle([0, 0, W, 3], fill=(255, 255, 255))

def font(size):
    candidates = [
        "/System/Library/Fonts/PingFang.ttc",
        "/System/Library/Fonts/STHeiti Light.ttc",
        "/System/Library/Fonts/Hiragino Sans GB.ttc",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for p in candidates:
        if os.path.exists(p):
            try:
                return ImageFont.truetype(p, size)
            except Exception:
                continue
    return ImageFont.load_default()

title_font = font(34)
sub_font = font(16)
hint_font = font(15)

# 标题 + 副标题（x=185 起，避开侧边栏）
d.text((185, 40), "WH-1：OFD弹出助手", fill=(35, 60, 95), font=title_font)
d.text((187, 88), "清理卡住的缩略图进程，让移动硬盘顺利弹出", fill=(105, 125, 155), font=sub_font)

# 中间箭头（App 图标约在 x 240-336，Applications 约 540-636，箭头放 380-490 之间）
arrow_y = 290
d.line([(385, arrow_y), (475, arrow_y)], fill=(250, 251, 253), width=6)
d.polygon([(490, arrow_y), (470, arrow_y - 10), (470, arrow_y + 10)], fill=(250, 251, 253))
d.line([(385, arrow_y - 4), (475, arrow_y - 4)], fill=(160, 180, 210), width=1)
d.line([(385, arrow_y + 4), (475, arrow_y + 4)], fill=(160, 180, 210), width=1)

# 底部提示（以内容区中心为基准居中，即 x 170~820 的中点 ≈ 495）
hint = "将「WH-1：OFD弹出助手」拖入右侧「应用程序」文件夹，即完成安装"
tw = d.textlength(hint, font=hint_font)
d.text((int(170 + (W - 170 - tw) / 2), H - 56), hint, fill=(90, 110, 145), font=hint_font)

# 右上装饰闪光
d.regular_polygon((760, 70, 3), 4, rotation=15, fill=(255, 255, 255))
d.regular_polygon((790, 110, 2), 4, rotation=40, fill=(255, 255, 255))
d.regular_polygon((735, 130, 2), 4, rotation=70, fill=(255, 255, 255))

# 固定写到仓库内的 assets/，避免从别的目录运行时产出落到当前目录
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "dmg-background.png")
img.save(OUT)
print("saved:", OUT, img.size)
