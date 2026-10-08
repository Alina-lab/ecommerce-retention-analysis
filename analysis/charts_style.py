"""Charts for the Olist report. One conclusion per figure, counts beside rates."""
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch
from matplotlib.ticker import FuncFormatter
import numpy as np

INK = "#17233F"
MUTED = "#637087"
BLUE = "#3D5AFE"
ORANGE = "#FF8A3D"
GREY = "#B6C2D6"
GRID = "#E4E9F2"
BG = "#F3F5FB"
PALE = "#EDF0FF"


def count(value):
    return f"{int(value):,}".replace(",", " ")


def rate(value):
    return f"{100 * float(value):.2f}%".replace(".", ",")


def pp(value):
    return f"{float(value):.2f}".replace(".", ",")


def style_axis(ax, horizontal=False):
    for spine in ax.spines.values():
        spine.set_visible(False)
    ax.tick_params(length=0, pad=9, colors=MUTED)
    ax.set_axisbelow(True)
    ax.grid(axis="x" if horizontal else "y", color=GRID, linewidth=.8)


def heading(fig, title, subtitle):
    fig.text(.04, .925, title, fontsize=20, weight="bold", color=INK)
    fig.text(.04, .865, subtitle, fontsize=12, color=MUTED)


def save(fig, output, name):
    for extension in ["png", "svg"]:
        path = output / "charts" / f"{name}.{extension}"
        temporary = path.with_name(f"_render_{name}.{extension}")
        fig.savefig(temporary, dpi=180, facecolor="white")
        temporary.replace(path)
    plt.close(fig)


def category_comparison(categories, overall, output):
    rows = categories.set_index("first_category").loc[
        ["fashion_bags_accessories", "bed_bath_table", "cool_stuff"]]
    fig, ax = plt.subplots(figsize=(12, 5.8))
    fig.subplots_adjust(left=.30, right=.81, bottom=.23, top=.75)
    positions = [2, 1, 0]
    ax.barh(positions, rows.repeat_rate * 100, color=[BLUE, BLUE, ORANGE], height=.54)
    ax.set_yticks(positions, rows.label, fontsize=13, color=INK)
    ax.set_xlim(0, 6)
    ax.set_ylim(-.65, 2.7)
    ax.set_xticks(range(7))
    ax.xaxis.set_major_formatter(FuncFormatter(lambda x, _: f"{x:.0f}%"))
    ax.axvline(overall * 100, color=MUTED, lw=1.5, ls=(0, (3, 3)))
    ax.text(overall * 100, 2.68, "Вся выборка: 2,75%", ha="center", fontsize=11,
            color=MUTED, bbox={"facecolor": "white", "edgecolor": "none", "pad": 3})
    for y, row in zip(positions, rows.itertuples()):
        ax.text(row.repeat_rate * 100 + .12, y, rate(row.repeat_rate), va="center",
                fontsize=19, weight="bold", color=INK)
        ax.text(.03, y - .34, f"{count(row.returned_buyers)} повторных из {count(row.buyers)} покупателей",
                va="top", fontsize=11, color=MUTED,
                bbox={"facecolor": "white", "edgecolor": "none", "pad": .5})
    style_axis(ax, True)
    ax.set_xlabel("Доля покупателей, купивших снова за 180 дней", labelpad=15, fontsize=12)
    heading(fig, "Сумки и домашний текстиль лидируют среди крупных категорий",
            "Сравнение категорий первой покупки. В крупных категориях — не менее 1 000 покупателей.")
    fig.text(.04, .045, "У сумок доля повторных покупателей в 3,7 раза выше, чем у Cool stuff: 4,81% против 1,30%.", fontsize=11, color=INK)
    save(fig, output, "01_categories")


def monthly_comparison(monthly, output):
    rates = monthly.pivot(index="first_purchase_month", columns="first_category", values="repeat_rate")
    sizes = monthly.pivot(index="first_purchase_month", columns="first_category", values="buyers")
    delta = 100 * (rates.fashion_bags_accessories - rates.cool_stuff)
    x = np.arange(len(delta))
    fig, ax = plt.subplots(figsize=(12, 6.4))
    fig.subplots_adjust(left=.09, right=.97, top=.73, bottom=.24)
    colours = [BLUE if v >= 0 else ORANGE for v in delta]
    ax.bar(x, delta, color=colours, width=.65)
    ax.axhline(0, color=INK, lw=1)
    for i, value in enumerate(delta):
        label = ("+" if value > 0 else "−") + pp(abs(value))
        ax.text(i, value + (.35 if value >= 0 else -.4), label,
                ha="center", va="bottom" if value >= 0 else "top",
                fontsize=11, weight="bold", color=BLUE if value >= 0 else "#C65A15")
    ax.scatter([i for i, v in enumerate(delta) if v < 0], [v for v in delta if v < 0],
               s=30, color=ORANGE, zorder=4)
    ax.set_xticks(x, [m[5:] + "." + m[2:4] for m in rates.index], fontsize=11)
    ax.set_ylim(-3.4, 13)
    ax.set_yticks([0, 3, 6, 9, 12])
    ax.set_ylabel("Разница долей, п.п.\nСумки минус Cool stuff", fontsize=12)
    style_axis(ax)
    ax.text(0, -.23, "Покупатели: сумки / Cool stuff", transform=ax.transAxes,
            fontsize=10, color=MUTED)
    for i, month in enumerate(rates.index):
        ax.text(i, -.13, f"{int(sizes.loc[month, 'fashion_bags_accessories'])} / {int(sizes.loc[month, 'cool_stuff'])}",
                transform=ax.get_xaxis_transform(), ha="center", fontsize=9, color=MUTED)
    heading(fig, "У сумок доля повторных покупателей выше в 11 из 13 месяцев",
            "Синий — выше у сумок. Оранжевый — выше у Cool stuff. Январь 2017 — январь 2018.")
    fig.text(.04, .055, "Большой отрыв в январе 2017 — всего 3 повторных покупателя из 27. Отдельно на этот месяц не опираемся.", fontsize=11, color=INK)
    save(fig, output, "02_monthly_comparison")


def delivery_comparison(checks, output):
    rows = checks[checks.check.eq("delivery_180")].set_index("group").loc[["on_time", "late"]]
    fig, ax = plt.subplots(figsize=(12, 5.4))
    fig.subplots_adjust(left=.23, right=.69, top=.71, bottom=.24)
    ax.barh([1, 0], rows.repeat_rate * 100, color=[BLUE, ORANGE], height=.48)
    ax.set_yticks([1, 0], ["Доставка вовремя", "С опозданием"], fontsize=13)
    ax.set_ylim(-.55, 1.55)
    ax.set_xlim(0, 2.5)
    ax.set_xticks([0, .5, 1, 1.5, 2, 2.5])
    ax.xaxis.set_major_formatter(FuncFormatter(lambda x, _: f"{x:g}%".replace(".", ",")))
    for y, row in zip([1, 0], rows.itertuples()):
        ax.text(row.repeat_rate * 100 + .07, y, rate(row.repeat_rate), va="center", fontsize=21, weight="bold")
        ax.text(.015, y - .30, f"{count(row.returned_buyers)} повторных из {count(row.buyers)} покупателей", va="top", fontsize=11, color=MUTED)
    style_axis(ax, True)
    ax.set_xlabel("Повторная покупка за 180 дней после получения", fontsize=12, labelpad=14)
    heading(fig, "После опоздания повторно купили 1,37% покупателей",
            "При доставке вовремя — 1,87%. В обеих группах есть полные 180 дней после получения.")
    fig.text(.77, .51, "−0,50", fontsize=36, weight="bold", color="#C65A15")
    fig.text(.77, .435, "процентного пункта", fontsize=12, color=MUTED)
    fig.text(.04, .06, "Группы не уравнены по категории, цене, продавцу и региону. Разницу нельзя целиком приписать опозданию.", fontsize=11, color=INK)
    save(fig, output, "03_delivery_checks")


def small_group(cross, output):
    row = cross.set_index(["first_category", "delivery_group"]).loc[("fashion_bags_accessories", "late")]
    assert int(row.buyers) == 52 and int(row.returned_buyers) == 3
    fig = plt.figure(figsize=(12, 5.4))
    heading(fig, "5,77% — это всего три повторных покупателя",
            "Сумки и аксессуары · первая доставка с опозданием · январь 2017 — январь 2018.")
    fig.text(.055, .57, "3 из 52", fontsize=42, weight="bold", color=INK)
    fig.text(.055, .49, "купили снова за 180 дней", fontsize=13, color=MUTED)
    fig.text(.055, .40, "2 из этих 3", fontsize=22, weight="bold", color=INK)
    fig.text(.055, .35, "оформили повтор ещё до\nполучения первой покупки", va="top", fontsize=12, color=MUTED)
    ax = fig.add_axes([.44, .30, .50, .40])
    xx = np.tile(np.arange(13), 4)
    yy = np.repeat(np.arange(4)[::-1], 13)
    colours = [ORANGE] * 3 + [GRID] * 49
    ax.scatter(xx, yy, s=230, c=colours)
    ax.set_xlim(-.6, 12.6)
    ax.set_ylim(-.55, 3.55)
    ax.axis("off")
    fig.text(.46, .24, "Одна точка = один покупатель. Оранжевые купили повторно.", fontsize=10, color=MUTED)
    fig.text(.055, .12, "Ещё один повторный покупатель — и доля была бы уже 7,69% (+1,92 п.п.).", fontsize=14, weight="bold", color=INK)
    fig.text(.055, .055, "Сравнивать 5,77% с 4,71% у доставки вовремя как устойчивое преимущество здесь нельзя.", fontsize=11, color=MUTED)
    save(fig, output, "04_small_groups")


def category_ranking(categories, overall, output):
    rows = categories[categories.buyers.ge(1000)].sort_values("repeat_rate")
    assert rows.tail(2).first_category.tolist() == ["bed_bath_table", "fashion_bags_accessories"]
    fig, ax = plt.subplots(figsize=(12, 9))
    fig.subplots_adjust(left=.29, right=.78, top=.85, bottom=.15)
    yy = np.arange(len(rows))
    colours = [BLUE if c in ["fashion_bags_accessories", "bed_bath_table"] else
               ORANGE if c == "cool_stuff" else GREY for c in rows.first_category]
    ax.barh(yy, rows.repeat_rate * 100, color=colours, height=.67)
    ax.set_yticks(yy, rows.label, fontsize=11)
    ax.set_xlim(0, 5.5)
    ax.xaxis.set_major_formatter(FuncFormatter(lambda x, _: f"{x:g}%"))
    ax.axvline(overall * 100, color=MUTED, ls="--", lw=1.3)
    for y, row in zip(yy, rows.itertuples()):
        ax.text(row.repeat_rate * 100 + .08, y, rate(row.repeat_rate), va="center", fontsize=11,
                bbox={"facecolor": "white", "edgecolor": "none", "pad": .6})
        ax.text(1.04, y, f"{count(row.returned_buyers)} / {count(row.buyers)}", va="center",
                transform=ax.get_yaxis_transform(), fontsize=10, color=MUTED)
    ax.text(1.04, 1.035, "Повторные / все", transform=ax.transAxes, fontsize=11)
    ax.set_xlabel("Повторная покупка за 180 дней от первой, %", labelpad=14)
    style_axis(ax, True)
    heading(fig, "Рейтинг 17 крупных категорий: сумки и текстиль — первые",
            "Все 17 категорий с ≥ 1 000 покупателей. Пунктир — общий показатель 2,75%.")
    fig.text(.04, .025, "Порог 1 000 выбран для читаемости. Все 74 группы, включая малые и смешанные, есть в таблице отчёта.", fontsize=11, color=MUTED)
    save(fig, output, "05_category_ranking")


def overview(categories, checks, totals, output):
    fig = plt.figure(figsize=(14, 9.5), facecolor=BG)
    fig.text(.045, .94, "OLIST  /  ПОВТОРНЫЕ ПОКУПКИ", fontsize=12, weight="bold", color=BLUE)
    fig.text(.045, .855, "За полгода снова купили только 2,75% покупателей", fontsize=27, weight="bold", color=INK)
    fig.text(.045, .805, "1 358 из 49 452 покупателей. У каждого есть полные 180 дней наблюдения.", fontsize=15, color=MUTED)
    for x in [.035, .515]:
        fig.add_artist(FancyBboxPatch((x, .195), .445, .54, boxstyle="round,pad=0.008,rounding_size=0.018",
                                     transform=fig.transFigure, facecolor="white", edgecolor="none", zorder=0))
    fig.text(.06, .69, "КАТЕГОРИЯ ПЕРВОЙ ПОКУПКИ", fontsize=11, color=MUTED, weight="bold")
    fig.text(.06, .625, "В 3,7 раза выше", fontsize=26, color=BLUE, weight="bold")
    fig.text(.06, .58, "доля повторных покупателей: сумки и Cool stuff", fontsize=12, color=INK)
    fig.text(.54, .69, "180 ДНЕЙ ПОСЛЕ ПОЛУЧЕНИЯ", fontsize=11, color=MUTED, weight="bold")
    fig.text(.54, .625, "На 0,50 п.п. ниже", fontsize=26, color="#C65A15", weight="bold")
    fig.text(.54, .58, "доля повторных покупателей при опоздании", fontsize=12, color=INK)
    cat = categories.set_index("first_category")
    delivery = checks[checks.check.eq("delivery_180")].set_index("group")
    panels = [(.17, .26, .265, [cat.loc[c] for c in ["fashion_bags_accessories", "cool_stuff"]],
               ["Сумки", "Cool stuff"], 6, "180 дней от первой покупки"),
              (.665, .26, .26, [delivery.loc[g] for g in ["on_time", "late"]],
               ["Вовремя", "Опоздание"], 2.5, "180 дней после получения")]
    for x, bottom, width, rows, labels, limit, xlabel in panels:
        ax = fig.add_axes([x, bottom, width, .245], facecolor="white")
        for y, row, colour in zip([1, 0], rows, [BLUE, ORANGE]):
            ax.barh(y, row.repeat_rate * 100, height=.44, color=colour)
            ax.text(row.repeat_rate * 100 + limit * .025, y, rate(row.repeat_rate),
                    va="center", fontsize=17, weight="bold")
            ax.text(0, y - .27, f"{count(row.returned_buyers)} из {count(row.buyers)}", va="top", fontsize=10, color=MUTED)
        ax.set_yticks([1, 0], labels, fontsize=12)
        ax.set_xlim(0, limit)
        ax.set_ylim(-.57, 1.6)
        ax.set_xticks([0, 2, 4, 6] if limit == 6 else [0, 1, 2])
        ax.xaxis.set_major_formatter(FuncFormatter(lambda v, _: f"{v:g}%"))
        ax.set_xlabel(xlabel, fontsize=10, labelpad=10)
        style_axis(ax, True)
    fig.text(.045, .145, "Первый CRM-пилот: предложение второй покупки после заказа домашнего текстиля.", fontsize=15, weight="bold", color=INK)
    fig.text(.045, .105, "Здесь 214 повторных покупателей из 4 769 (4,49%). Эффект предложения проверяем в A/B-тесте.", fontsize=13, color=MUTED)
    fig.text(.045, .047, "Результаты описывают эту выборку. Разницу по доставке нельзя целиком приписать задержке. Граница данных: 31.07.2018.", fontsize=10, color=MUTED)
    temporary = output / "_render_overview.png"
    fig.savefig(temporary, dpi=180, facecolor=BG)
    temporary.replace(output / "olist_overview.png")
    plt.close(fig)


def build_charts(categories, monthly, checks, cross, totals, output: Path):
    plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 12,
                         "text.color": INK, "axes.labelcolor": MUTED, "svg.fonttype": "none"})
    category_comparison(categories, totals["repeat_rate"], output)
    monthly_comparison(monthly, output)
    delivery_comparison(checks, output)
    small_group(cross, output)
    category_ranking(categories, totals["repeat_rate"], output)
    overview(categories, checks, totals, output)
