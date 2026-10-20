from PIL import Image, ImageDraw, ImageFilter
import sys, os

src = sys.argv[1]
dst = sys.argv[2]

img = Image.open(src).convert("RGBA")
w, h = img.size

# 用洋红色（图标中不存在的颜色）从四边泛洪，把与外部连通的近白色区域标记出来
marker = (255, 0, 255, 255)
seeds = [
    (0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1),
    (w // 2, 0), (w // 2, h - 1), (0, h // 2), (w - 1, h // 2),
]
for pt in seeds:
    try:
        ImageDraw.floodfill(img, pt, marker, thresh=60)
    except Exception:
        pass

px = img.load()
for y in range(h):
    for x in range(w):
        if px[x, y] == marker:
            px[x, y] = (0, 0, 0, 0)

# 轻微羽化 alpha 边缘，避免锯齿
alpha = img.getchannel("A").filter(ImageFilter.GaussianBlur(0.6))
img.putalpha(alpha)

img.save(dst)
print("saved:", dst)
print("size:", img.size, "mode:", img.mode)
