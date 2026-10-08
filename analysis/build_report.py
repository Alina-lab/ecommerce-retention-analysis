"""Build the Olist portfolio report from the verified buyer-level SQL export.

Usage: python build_report.py --input buyer_analysis.csv --output report_output
Requires pandas and matplotlib. Supplemental delivery results are verified SQL
aggregates, supplied separately; they cannot be reconstructed from next_purchase_at.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import html
import json
from pathlib import Path

from charts_style import build_charts
import pandas as pd

NAMES = {
    "bed_bath_table": "Текстиль для дома",
    "sports_leisure": "Спорт и досуг",
    "health_beauty": "Здоровье и красота",
    "furniture_decor": "Мебель и декор",
    "computers_accessories": "Компьютеры и аксессуары",
    "housewares": "Товары для дома",
    "toys": "Игрушки",
    "cool_stuff": "Cool stuff",
    "watches_gifts": "Часы и подарки",
    "telephony": "Телефония",
    "garden_tools": "Садовые инструменты",
    "perfumery": "Парфюмерия",
    "auto": "Автотовары",
    "baby": "Товары для малышей",
    "stationery": "Канцтовары",
    "electronics": "Электроника",
    "fashion_bags_accessories": "Сумки и аксессуары",
    "mixed_categories": "Смешанные категории",
    "unknown_category": "Неизвестная категория",
}


def integer(value):
    return f"{int(value):,}".replace(",", " ")


def percent(value):
    return f"{100 * float(value):.2f}%".replace(".", ",")


def summarize(frame, keys):
    result = frame.groupby(keys, dropna=False)["returned_180"].agg(
        buyers="size", returned_buyers="sum"
    ).reset_index()
    result["repeat_rate"] = result["returned_buyers"] / result["buyers"]
    return result


def embedded_image(output, name, alt):
    payload = base64.b64encode((output / "charts" / f"{name}.png").read_bytes()).decode()
    return f'<img src="data:image/png;base64,{payload}" alt="{html.escape(alt)}" loading="lazy">'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, default=Path("buyer_analysis.csv"))
    parser.add_argument("--output", type=Path, default=Path("report_output"))
    args = parser.parse_args()
    output = args.output.resolve()
    (output / "charts").mkdir(parents=True, exist_ok=True)
    (output / "tables").mkdir(exist_ok=True)
    df = pd.read_csv(args.input)
    required = {
        "customer_unique_id", "first_purchase_at", "first_purchase_month",
        "next_purchase_at", "returned_180", "first_category", "delivery_group",
        "first_order_count", "first_purchase_delivered_at",
    }
    if not required.issubset(df.columns):
        raise ValueError(f"Missing columns: {required - set(df.columns)}")
    assert df.customer_unique_id.is_unique, "Buyer IDs must be unique"
    assert df.returned_180.isin([0, 1]).all(), "Return flag must be binary"
    assert df[list(required - {"next_purchase_at", "first_purchase_delivered_at"})].notna().all().all()
    assert df.delivery_group.isin(["on_time", "late", "unknown_delivery"]).all()
    for column in ["first_purchase_at", "next_purchase_at", "first_purchase_delivered_at"]:
        df[column] = pd.to_datetime(df[column], errors="raise")
    first = df.first_purchase_at
    assert (first + pd.Timedelta(days=180) <= pd.Timestamp("2018-07-31 23:59:59")).all()
    expected_return = (
        df.next_purchase_at.gt(first)
        & df.next_purchase_at.le(first + pd.Timedelta(days=180))
    ).astype(int)
    assert expected_return.equals(df.returned_180), "Return flags disagree with dates"
    assert (df.first_purchase_month == first.dt.strftime("%Y-%m")).all()
    df["repeat_before_delivery"] = (
        df.returned_180.eq(1)
        & df.next_purchase_at.le(df.first_purchase_delivered_at)
    ).astype(int)
    totals = {"buyers": len(df), "returned_buyers": int(df.returned_180.sum()),
              "repeat_rate": float(df.returned_180.mean())}
    assert totals["buyers"] == 49452 and totals["returned_buyers"] == 1358
    assert int(df.repeat_before_delivery.sum()) == 526
    categories = summarize(df, "first_category").sort_values("buyers", ascending=False)
    categories["label"] = categories.first_category.map(NAMES).fillna(categories.first_category)
    months = summarize(df, "first_purchase_month")
    delivery = summarize(df, "delivery_group")
    window = df.first_purchase_month.between("2017-01", "2018-01")
    cohort_df = df[window]
    selected = ["fashion_bags_accessories", "cool_stuff"]
    selected_months = summarize(cohort_df[cohort_df.first_category.isin(selected)],
                                ["first_purchase_month", "first_category"])
    cross = summarize(cohort_df[cohort_df.first_category.isin(selected)
                               & cohort_df.delivery_group.isin(["on_time", "late"])],
                      ["first_category", "delivery_group"])
    cross = cross.merge(
        cohort_df.groupby(["first_category", "delivery_group"]).repeat_before_delivery.sum().reset_index(),
        on=["first_category", "delivery_group"], how="left", validate="one_to_one")
    pivot = selected_months.pivot(index="first_purchase_month", columns="first_category", values="repeat_rate")
    higher_months = int((pivot[selected[0]] > pivot[selected[1]]).sum())
    for name, frame in [("categories", categories), ("monthly_cohorts", months),
                        ("delivery", delivery), ("selected_category_months", selected_months),
                        ("selected_category_delivery", cross)]:
        frame.to_csv(output / "tables" / f"{name}.csv", index=False)

    supplement = json.loads((Path(__file__).parent / "delivery_checks.json").read_text())
    # Additional SQL flags inspect ALL later orders, rather than only the next one.
    # Keep those aggregates separate from metrics recomputed from this CSV.
    for row in supplement["results"]:
        row["repeat_rate"] = row["returned_buyers"] / row["buyers"]
    (output / "tables" / "delivery_checks.json").write_text(
        json.dumps(supplement, ensure_ascii=False, indent=2), encoding="utf-8")

    original = delivery.set_index("delivery_group")
    base_checks = [
        {"check": "purchase_180", "group": group,
         "buyers": int(original.loc[group, "buyers"]),
         "returned_buyers": int(original.loc[group, "returned_buyers"]),
         "repeat_rate": float(original.loc[group, "repeat_rate"])}
        for group in ["on_time", "late"]
    ]
    checks = pd.DataFrame(base_checks + supplement["results"])
    checks.to_csv(output / "tables" / "delivery_all_checks.csv", index=False)
    # The prose below describes this exact export, not arbitrary future data.
    assert int((df.returned_180.eq(1) & df.next_purchase_at.eq(df.first_purchase_delivered_at)).sum()) == 0
    assert higher_months == 11
    assert int(categories.set_index("first_category").loc["bed_bath_table", "returned_buyers"]) == 214
    build_charts(categories, selected_months, checks, cross, totals, output)

    page = (Path(__file__).parent / "report_template.html").read_text(encoding="utf-8")
    replacements = {
        "TOTAL_BUYERS": integer(totals["buyers"]),
        "TOTAL_RETURNS": integer(totals["returned_buyers"]),
        "TOTAL_RATE": percent(totals["repeat_rate"]),
    }
    names = ["01_categories", "02_monthly_comparison", "03_delivery_checks", "04_small_groups", "05_category_ranking"]
    alts = [
        "Сумки: 4,81%; домашний текстиль: 4,49%; Cool stuff: 1,30%. Доли повторных покупателей за 180 дней от первой покупки.",
        "Доля повторных покупателей сумок выше Cool stuff в 11 из 13 месяцев. Размеры групп указаны под месяцами.",
        "За 180 дней после получения: доставка вовремя — 829 из 44 279 (1,87%); опоздание — 32 из 2 332 (1,37%).",
        "В группе сумок с опозданием повторно купили 3 покупателя из 52; двое оформили повтор до получения.",
        "Рейтинг всех 17 категорий с не менее чем 1 000 покупателей; лидируют сумки и домашний текстиль.",
    ]
    for i, (name, alt) in enumerate(zip(names, alts), 1):
        replacements[f"CHART_{i:02}"] = embedded_image(output, name, alt)
    replacements["CATEGORY_ROWS"] = "".join(
        f'<tr data-buyers="{int(row.buyers)}"><td>{html.escape(row.label)}<small>{html.escape(row.first_category)}</small></td>'
        f'<td>{integer(row.buyers)}</td><td>{integer(row.returned_buyers)}</td><td>{percent(row.repeat_rate)}</td></tr>'
        for row in categories.itertuples()
    )
    month_rows = []
    month_index = selected_months.set_index(["first_purchase_month", "first_category"])
    for month in pivot.index:
        bags = month_index.loc[(month, "fashion_bags_accessories")]
        cool = month_index.loc[(month, "cool_stuff")]
        delta = 100 * (bags.repeat_rate - cool.repeat_rate)
        delta_text = f"{delta:+.2f}".replace(".", ",")
        month_rows.append(f'<tr><td>{month}</td><td>{percent(bags.repeat_rate)}<small>{integer(bags.returned_buyers)} из {integer(bags.buyers)}</small></td>'
                          f'<td>{percent(cool.repeat_rate)}<small>{integer(cool.returned_buyers)} из {integer(cool.buyers)}</small></td>'
                          f'<td>{delta_text} п.п.</td></tr>')
    replacements["MONTH_TABLE"] = table(["Месяц первой покупки", "Сумки", "Cool stuff", "Разница"], month_rows)
    delivery_rows = []
    for key, label in [
        ("purchase_180", "Любой повтор за 180 дней от оформления"),
        ("after_delivery_in_purchase_180", "Повтор после получения, внутри 180 дней от оформления"),
        ("delivery_180", "Повтор за полные 180 дней после получения"),
    ]:
        groups = checks[checks.check.eq(key)].set_index("group")
        on_time, late = groups.loc["on_time"], groups.loc["late"]
        delta = 100 * (on_time.repeat_rate - late.repeat_rate)
        delta_text = f"{delta:.2f}".replace(".", ",")
        delivery_rows.append(f'<tr><td>{label}</td><td>{percent(on_time.repeat_rate)}<small>{integer(on_time.returned_buyers)} из {integer(on_time.buyers)}</small></td>'
                             f'<td>{percent(late.repeat_rate)}<small>{integer(late.returned_buyers)} из {integer(late.buyers)}</small></td><td>{delta_text} п.п.</td></tr>')
    replacements["DELIVERY_TABLE"] = table(["Способ расчёта", "Вовремя", "С опозданием", "Разница"], delivery_rows)
    cross_rows = []
    for row in cross.itertuples():
        group = "вовремя" if row.delivery_group == "on_time" else "с опозданием"
        label = f"{NAMES[row.first_category]} · {group}"
        cross_rows.append(f'<tr><td>{html.escape(label)}</td><td>{integer(row.buyers)}</td><td>{integer(row.returned_buyers)}</td>'
                          f'<td>{percent(row.repeat_rate)}</td><td>{integer(row.repeat_before_delivery)}</td></tr>')
    replacements["CROSS_TABLE"] = table(["Первая категория и доставка", "Покупатели", "Купили снова", "Доля", "Из них до получения"], cross_rows)
    for key, value in replacements.items():
        page = page.replace("{{" + key + "}}", value)
    assert "{{" not in page, "Unresolved report placeholder"
    (output / "olist_report.html").write_text(page, encoding="utf-8")
    audit = {
        "source": "buyer_analysis.csv", "source_sha256": hashlib.sha256(args.input.read_bytes()).hexdigest(),
        **totals, "categories": int(df.first_category.nunique()),
        "unique_buyers": int(df.customer_unique_id.nunique()),
        "missing_delivery_dates": int(df.first_purchase_delivered_at.isna().sum()),
        "repeat_before_or_at_delivery": int(df.repeat_before_delivery.sum()),
        "bags_higher_months": higher_months, "cohort_range": ["2017-01", "2018-01"],
        "observation_cutoff": "2018-07-31 23:59:59",
        "supplement_source": "SQL verified on source orders/customers; all later orders considered",
        "presentation_version": 2,
    }
    (output / "validation.json").write_text(json.dumps(audit, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(audit, ensure_ascii=False))


def table(headers, rows):
    header = "".join(f'<th scope="col">{html.escape(h)}</th>' for h in headers)
    return f"<table><thead><tr>{header}</tr></thead><tbody>{''.join(rows)}</tbody></table>"


if __name__ == "__main__":
    main()
