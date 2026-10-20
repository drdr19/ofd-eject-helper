# dmgbuild 配置：OFD 弹出助手 安装镜像
# 用法：python3 -m dmgbuild -s scripts/dmg_settings.py "OFD弹出助手" dist/OFD弹出助手.dmg
format = 'UDBZ'          # bzip2 压缩
size = None              # 自动计算

# 要放进 DMG 的文件
files = ['build/OFD弹出助手.app']

# Applications 软链接（拖拽安装用）
symlinks = {'Applications': '/Applications'}

# 背景图（dmgbuild 会自动隐藏该文件）
background = 'assets/dmg-background.png'

# 窗口位置和大小（屏幕坐标 + 宽高）
window_rect = ((200, 200), (820, 440))

# 图标视图
default_view = 'icon-view'
show_icon_preview = False

# 图标位置（DMG 窗口内坐标，窗口 820x440；左侧 170px 预留给侧边栏）
icon_locations = {
    'OFD弹出助手.app': (240, 230),
    'Applications':    (540, 230),
    '.background':     (0, 0),   # 藏到看不见的地方
}

# 图标大小
icon_size = 96
text_size = 14

# 不显示工具栏/状态栏/路径栏
include_icon_view_settings = True
include_list_view_settings = False
