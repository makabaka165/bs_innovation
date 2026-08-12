from __future__ import annotations

import csv
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
from matplotlib import font_manager
from matplotlib.patches import Circle, FancyArrowPatch, Polygon, Rectangle


ROOT = Path(r"E:\bs_innovation")
RESULTS = ROOT / "beamspace_ml_v18" / "source" / "stepwise_signal_model" / "steps" / (
    "step_11_6_shared_center_rotatable_beamspace_manifold_cache"
) / "results_step11_6_shared_center_rotatable_beamspace_manifold_cache"
OUT = ROOT / "zhuanli" / "canonical_beamspace_manifold_cache_patent_assets"
OUT.mkdir(parents=True, exist_ok=True)


def configure_font() -> None:
    candidates = [
        Path(r"C:\Windows\Fonts\simhei.ttf"),
        Path(r"C:\Windows\Fonts\simsun.ttc"),
        Path(r"C:\Windows\Fonts\msyh.ttc"),
    ]
    for path in candidates:
        if path.exists():
            font_manager.fontManager.addfont(path)
            chinese_name = font_manager.FontProperties(fname=path).get_name()
            plt.rcParams["font.family"] = [chinese_name, "DejaVu Sans"]
            break
    plt.rcParams["axes.unicode_minus"] = False
    plt.rcParams["font.size"] = 12
    plt.rcParams["mathtext.fontset"] = "dejavusans"


def save(fig: plt.Figure, name: str) -> None:
    fig.savefig(OUT / name, dpi=300, bbox_inches="tight", facecolor="white")
    plt.close(fig)


def add_box(ax, xy, wh, text, lw=1.5, fontsize=12, facecolor="white"):
    x, y = xy
    w, h = wh
    patch = Rectangle((x, y), w, h, linewidth=lw, edgecolor="black", facecolor=facecolor)
    ax.add_patch(patch)
    ax.text(x + w / 2, y + h / 2, text, ha="center", va="center", fontsize=fontsize, linespacing=1.35)
    return patch


def add_arrow(ax, start, end, text=None, text_offset=(0, 0), connectionstyle="arc3"):
    arrow = FancyArrowPatch(
        start,
        end,
        arrowstyle="-|>",
        mutation_scale=13,
        linewidth=1.35,
        color="black",
        connectionstyle=connectionstyle,
    )
    ax.add_patch(arrow)
    if text:
        mx = (start[0] + end[0]) / 2 + text_offset[0]
        my = (start[1] + end[1]) / 2 + text_offset[1]
        ax.text(mx, my, text, ha="center", va="center", fontsize=10, backgroundcolor="white")


def figure_1_flow() -> None:
    fig, ax = plt.subplots(figsize=(7.2, 10.2))
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 14)
    ax.axis("off")

    steps = [
        ("S101", "获取圆柱阵参数与目标工作中心\n选择最近物理列作为实际共享中心"),
        ("S102", "在参考中心构建规范局部子阵\n固定阵元的列层顺序"),
        ("S103", "建立旋转等价关系\n形成待用方位偏移－俯仰精确网格并集"),
        ("S104", "离线计算规范波束域流形\n写入缓存张量及身份元数据"),
        ("S105", "在线校验缓存身份\n将全局方位转换为规范局部方位偏移"),
        ("S106", "执行精确网格查表\n命中则输出；未命中则记录并直接构建回退"),
    ]
    y_values = [12.2, 10.25, 8.3, 6.35, 4.4, 2.15]
    for (label, text), y in zip(steps, y_values):
        add_box(ax, (1.65, y), (6.95, 1.15), text, fontsize=12.2)
        add_box(ax, (0.25, y + 0.25), (1.05, 0.65), label, fontsize=11)
    for y1, y2 in zip(y_values[:-1], y_values[1:]):
        add_arrow(ax, (5.125, y1), (5.125, y2 + 1.15))

    add_box(ax, (2.35, 0.5), (5.55, 0.85), "输出目标网格的波束域流形", fontsize=12)
    add_arrow(ax, (5.125, 2.15), (5.125, 1.35))
    ax.text(9.5, 0.25, "图中流程不包含插值", ha="right", va="bottom", fontsize=9.5)
    save(fig, "图1_CBMC方法流程图.png")


def figure_2_rotation() -> None:
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(10.8, 5.8), gridspec_kw={"width_ratios": [1.15, 0.85]})

    ax1.set_aspect("equal")
    ax1.set_xlim(-1.55, 1.75)
    ax1.set_ylim(-1.45, 1.55)
    ax1.axis("off")
    ax1.add_patch(Circle((0, 0), 1, fill=False, linewidth=1.4, color="black"))
    ax1.plot([-1.25, 1.4], [0, 0], color="black", linewidth=0.8)
    ax1.plot([0, 0], [-1.25, 1.4], color="black", linewidth=0.8)
    ax1.text(1.43, -0.08, "x", fontsize=11)
    ax1.text(0.05, 1.48, "y", fontsize=11)
    ax1.text(-0.08, -0.16, "O", fontsize=10)
    ax1.text(-1.35, -0.75, "圆柱横截面 201", fontsize=10.2, rotation=54)
    ax1.text(-0.55, -0.20, "旋转轴 202", fontsize=10.2)

    canon_angles = np.deg2rad(np.linspace(-18, 18, 11))
    actual_center_deg = 52
    actual_angles = np.deg2rad(np.linspace(actual_center_deg - 18, actual_center_deg + 18, 11))
    ax1.scatter(np.cos(canon_angles), np.sin(canon_angles), s=30, facecolors="white", edgecolors="black", zorder=3)
    ax1.scatter(np.cos(actual_angles), np.sin(actual_angles), s=34, marker="s", facecolors="0.78", edgecolors="black", zorder=3)
    ax1.text(0.68, -0.48, "规范局部子阵 203", fontsize=10.5, ha="center")
    ax1.text(0.83, 1.12, "实际局部子阵 204", fontsize=10.5, ha="center")

    theta = np.deg2rad(np.linspace(5, actual_center_deg - 5, 60))
    ax1.plot(0.62 * np.cos(theta), 0.62 * np.sin(theta), color="black", linewidth=1.2)
    add_arrow(ax1, (0.62 * np.cos(theta[-2]), 0.62 * np.sin(theta[-2])),
              (0.62 * np.cos(theta[-1]), 0.62 * np.sin(theta[-1])))
    ax1.text(0.48, 0.29, r"旋转 $R_z(\theta_c)$ 205", fontsize=10.5, rotation=26)

    delta_deg = 18
    for ang_deg, label, shift in [
        (delta_deg, r"$\mathbf{u}(\delta,\varepsilon)$ 206", (0.02, -0.11)),
        (actual_center_deg + delta_deg, r"$\mathbf{u}(\theta_c+\delta,\varepsilon)$ 207", (0.18, 0.04)),
    ]:
        ang = np.deg2rad(ang_deg)
        add_arrow(ax1, (0, 0), (1.38 * np.cos(ang), 1.38 * np.sin(ang)))
        ax1.text(1.42 * np.cos(ang) + shift[0], 1.42 * np.sin(ang) + shift[1], label, fontsize=9.8, ha="center")
    ax1.text(-1.45, 1.42, "（a）俯视旋转关系", fontsize=11)

    ax2.set_xlim(0, 8)
    ax2.set_ylim(0, 9)
    ax2.axis("off")
    x_cols = np.linspace(1.0, 7.0, 9)
    z_layers = np.linspace(1.2, 7.8, 8)
    for j, z in enumerate(z_layers):
        for i, x in enumerate(x_cols):
            ax2.plot(x, z, "o", markersize=3.8, markerfacecolor="white", markeredgecolor="black")
    ax2.add_patch(Rectangle((0.65, 0.83), 6.7, 7.35, fill=False, linewidth=1.2, linestyle="--"))
    ax2.annotate("列方向固定次序", xy=(6.8, 8.45), xytext=(1.1, 8.45), arrowprops=dict(arrowstyle="-|>", color="black"), va="center")
    ax2.annotate("层方向固定次序", xy=(7.62, 7.65), xytext=(7.62, 1.25), arrowprops=dict(arrowstyle="-|>", color="black"), rotation=90, ha="center")
    ax2.text(4, 0.25, "同一列－层索引映射 208", ha="center", fontsize=10.5)
    ax2.text(0.15, 8.65, "（b）规范阵元顺序", fontsize=11)
    save(fig, "图2_圆柱阵共享中心旋转等价示意图.png")


def draw_tensor(ax, origin=(4.1, 4.7), size=(2.2, 1.55), layers=4):
    x, y = origin
    w, h = size
    for k in range(layers - 1, -1, -1):
        off = k * 0.16
        ax.add_patch(Rectangle((x + off, y + off), w, h, facecolor="white", edgecolor="black", linewidth=1.0))
    ax.text(x + w / 2 + 0.25, y + h / 2 + 0.25, r"$\mathcal{G}[b,i,j]$", ha="center", va="center", fontsize=13)
    ax.text(x + w / 2 + 0.25, y - 0.35, r"$B\times N_\delta\times N_\varepsilon$ 规范缓存 305", ha="center", fontsize=10.5)


def figure_3_cache() -> None:
    fig, ax = plt.subplots(figsize=(11.2, 7.2))
    ax.set_xlim(0, 14)
    ax.set_ylim(0, 10)
    ax.axis("off")
    ax.plot([7, 7], [0.6, 9.45], color="black", linewidth=1.0, linestyle="--")
    ax.text(3.5, 9.55, "离线构建阶段", ha="center", va="bottom", fontsize=13)
    ax.text(10.5, 9.55, "在线查表阶段", ha="center", va="bottom", fontsize=13)

    add_box(ax, (0.45, 7.6), (2.5, 1.05), "规范几何与\n固定阵元顺序 301", fontsize=10.5)
    add_box(ax, (3.65, 7.6), (2.5, 1.05), "精确方位偏移－俯仰\n网格并集 302", fontsize=10.5)
    add_box(ax, (0.45, 5.25), (2.5, 1.05), "波束变换矩阵 W\n及导向约定 303", fontsize=10.5)
    add_box(ax, (3.65, 5.25), (2.5, 1.05), "逐网格计算\n" + r"$G=W^H a_0(\delta,\varepsilon)$ 304", fontsize=10.5)
    draw_tensor(ax, origin=(3.7, 2.55), size=(2.1, 1.45), layers=4)
    add_box(ax, (0.45, 2.4), (2.5, 1.45), "身份元数据 306\n顺序、W、波长、相位约定\n网格、精度与版本", fontsize=9.8)

    add_arrow(ax, (2.95, 8.12), (3.65, 8.12))
    add_arrow(ax, (1.7, 7.6), (1.7, 6.3))
    add_arrow(ax, (2.95, 5.78), (3.65, 5.78))
    add_arrow(ax, (4.9, 7.6), (4.9, 6.3))
    add_arrow(ax, (4.9, 5.25), (4.9, 4.25))
    add_arrow(ax, (2.95, 3.1), (3.7, 3.1))

    add_box(ax, (7.55, 7.65), (2.6, 1.1), "全局查询\n" + r"$(\theta,\varepsilon,\theta_c)$ 307", fontsize=10.5)
    add_box(ax, (10.75, 7.65), (2.6, 1.1), "局部键生成\n" + r"$\delta=\mathrm{wrap}_{180}(\theta-\theta_c)$ 308", fontsize=9.8)
    add_box(ax, (8.9, 5.45), (3.0, 1.1), "缓存身份校验与\n精确网格索引 309", fontsize=10.5)

    diamond = Polygon([[10.4, 4.85], [11.8, 3.9], [10.4, 2.95], [9.0, 3.9]], closed=True, fill=False, linewidth=1.35)
    ax.add_patch(diamond)
    ax.text(10.4, 3.9, "身份一致且\n网格命中？", ha="center", va="center", fontsize=10.5)
    add_box(ax, (7.45, 1.0), (2.55, 1.05), "输出缓存流形切片 310", fontsize=10.5)
    add_box(ax, (11.0, 1.0), (2.55, 1.05), "记录缺失并直接构建回退 311\n不执行静默插值", fontsize=9.7)

    add_arrow(ax, (10.15, 8.2), (10.75, 8.2))
    add_arrow(ax, (12.05, 7.65), (11.05, 6.55))
    add_arrow(ax, (10.4, 5.45), (10.4, 4.85))
    add_arrow(ax, (9.55, 3.25), (8.75, 2.05), text="是", text_offset=(-0.12, 0.08))
    add_arrow(ax, (11.25, 3.25), (12.3, 2.05), text="否", text_offset=(0.12, 0.08))
    save(fig, "图3_缓存构建与精确查表示意图.png")


def read_stage4_rows():
    path = RESULTS / "step11_6_stage4_cross_center_cache_reuse_trial.csv"
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def figure_4_results() -> None:
    rows = read_stage4_rows()
    centers = np.array([float(r["actual_center_az"]) for r in rows])
    errors = np.array([float(r["max_rel_G_error"]) for r in rows])

    fig = plt.figure(figsize=(10.8, 6.8))
    gs = fig.add_gridspec(2, 2, height_ratios=[1.0, 0.72], hspace=0.42, wspace=0.32)
    ax1 = fig.add_subplot(gs[0, 0])
    ax1.semilogy(centers, errors, color="black", marker="o", markerfacecolor="white", linewidth=1.5)
    ax1.set_xlabel("实际共享中心方位角（度）")
    ax1.set_ylabel("最大相对波束域流形误差")
    ax1.grid(True, which="both", linestyle=":", linewidth=0.65, color="0.5")
    ax1.set_ylim(1e-15, 1e-13)
    ax1.set_yticks([1e-15, 1e-14, 1e-13])
    ax1.set_yticklabels([r"$10^{-15}$", r"$10^{-14}$", r"$10^{-13}$"])
    ax1.set_title("（a）跨中心复用误差", fontsize=12)

    ax2 = fig.add_subplot(gs[0, 1])
    ax2.axis("off")
    metric_rows = [
        ("缓存维数", "7 × 112 × 174（复数）"),
        ("一次构建时间", "0.937862 s"),
        ("缓存占用", "2.081543 MB"),
        ("最大相对流形误差", r"$3.23\times10^{-14}$"),
        ("缓存缺失次数", "0"),
        ("跨中心通过", "6 / 6"),
    ]
    y = 0.94
    row_h = 0.142
    for idx, (label, value) in enumerate(metric_rows):
        shade = "0.93" if idx % 2 == 0 else "white"
        ax2.add_patch(Rectangle((0.02, y - row_h), 0.46, row_h, facecolor=shade, edgecolor="black", linewidth=0.8))
        ax2.add_patch(Rectangle((0.48, y - row_h), 0.50, row_h, facecolor=shade, edgecolor="black", linewidth=0.8))
        ax2.text(0.25, y - row_h / 2, label, ha="center", va="center", fontsize=10.5)
        ax2.text(0.73, y - row_h / 2, value, ha="center", va="center", fontsize=10.5)
        y -= row_h
    ax2.set_title("（b）规范缓存代码输出", fontsize=12)

    ax3 = fig.add_subplot(gs[1, :])
    ax3.axis("off")
    summary = [
        ("阵元域导向矢量最大相对误差", r"$3.82\times10^{-14}$"),
        ("波束域流形最大相对误差", r"$3.23\times10^{-14}$"),
        ("流形构造时间中位降幅", "99.7734%"),
        ("精确查表缓存缺失次数", "0"),
    ]
    x0s = [0.015, 0.265, 0.515, 0.765]
    for x0, (label, value) in zip(x0s, summary):
        ax3.add_patch(Rectangle((x0, 0.16), 0.22, 0.68, facecolor="white", edgecolor="black", linewidth=1.0))
        ax3.text(x0 + 0.11, 0.61, label, ha="center", va="center", fontsize=9.5, wrap=True)
        ax3.text(x0 + 0.11, 0.34, value, ha="center", va="center", fontsize=12, fontweight="bold")
    ax3.text(0.5, 0.02, "（c）等价性与运行效果汇总", ha="center", va="bottom", fontsize=12)
    save(fig, "图4_Step11_6缓存代码运行结果.png")


def main() -> None:
    configure_font()
    figure_1_flow()
    figure_2_rotation()
    figure_3_cache()
    figure_4_results()
    for path in sorted(OUT.glob("*.png")):
        print(f"{path.name}\t{path.stat().st_size}")


if __name__ == "__main__":
    main()
