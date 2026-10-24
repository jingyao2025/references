# Figures 2–3: Issue focus of far-right protests, six countries, 2008–2021

Reproduce from the repository root with `Rscript CFP/streams/02_issue_streams.R`
(R 4.3; ggplot2, ggstream 0.1.0, dplyr, tidyr, stringr, colorspace, patchwork, scales).
ggstream was installed from its GitHub source (davidsjoberg/ggstream, commit a64b8d0),
because CRAN cannot be reached from this environment.

## Files in `output/`

| File | Content |
|---|---|
| `fig2_issue_streams_pooled.{pdf,png,tiff}` | Main figure, 6.5 × 6.9 in. All six countries combined. **A** is a mirror streamgraph of issue mentions per year (frequency). **B** is a proportional streamgraph of each issue's share per year. |
| `fig3_issue_shares_by_country.{pdf,png,tiff}` | Share streams for each country, 6.5 × 6.4 in, ordered by number of events. Each panel has a strip below it showing events per year. |
| `fig3_<country>.{pdf,png}` | The same panel for one country, 6.5 × 3.4 in. |
| `table_issue_ranking.csv` | All 13 issue categories, ranked by mentions and by first-listed issue. |
| `table_issue_counts_by_year.csv` | Mentions and shares by year for each issue, pooled and per country. These are the numbers behind every stream. |
| `qa_stream_accuracy.csv` | For every year, issue and panel: the drawn band width compared with the true value. |

## Choices and why

- **Unit = issue mention.** The codebook allows up to three issues per event and does
  not rank them. So each event counts once for every distinct issue it raises.
  - In 115 events, the same issue appears in two slots; these are counted once.
  - Result: 2,523 events, 4,415 issue mentions.
- **Top five issues** are those with the most mentions across the six countries:

  | Issue | Mentions |
  |---|---:|
  | Immigration | 974 |
  | Political opponents | 701 |
  | National identity | 639 |
  | Islam & internal minorities | 627 |
  | Anniversaries | 375 |
  | *Next: Economy & welfare* | *328* |

  Ranking on the first-listed issue (Issue1) alone gives the same five.
- **The same five issues and colours are used in every country panel**, so the panels can
  be compared. Where a country's protests centre on other issues, the grey "All other
  issues" band is large:
  - Poland: "Civil rights & religion" is 18% of mentions.
  - Spain: "Other" is 16% of mentions.
- **Issue labels are the dataset's own.** The released file codes Issue1–3 in a 13-category
  scheme ("0 - Other" … "12 - Anniversaries"). That scheme differs from the 27 categories
  in the PDF codebook and the "Variable values" sheet. No crosswalk is documented, so the
  labels are used exactly as coded, with the number prefix removed.
- **Accuracy of the streams.**
  - **The problem:** ggstream's default smoothing (`bw = 0.75`) puts the yearly values on
    a grid with zeros in between and fits a spline. Drawn shares then miss the true yearly
    values by up to 6 percentage points pooled, and 14 points for Austria. Drawn counts
    miss by up to about 100 mentions.
  - **What I did instead:** interpolated each issue's yearly counts with a monotone
    Fritsch–Carlson spline, which never overshoots and never goes negative. I then ran
    `geom_stream(bw = 0)` on that grid.
  - **Measured result** (all values in `qa_stream_accuracy.csv`; the script stops if
    either limit is exceeded):

    | Panel | Largest gap between drawn band and true value |
    |---|---|
    | Pooled shares | 0.03 percentage points |
    | Pooled counts | 0.16 mentions |
    | Single countries | 1.25 percentage points (Poland 2009, a one-event year) |

- **Small numbers.** Shares in thin years rest on very few events. The events-per-year
  strip under each country panel makes this visible. For example:
  - Netherlands 2011: 1 event, coded "Political opponents", so that year shows 100%.
  - Poland 2009: 1 event.
- **Colours.** Okabe–Ito hues, with fills lightened and outlines darkened in the same hue
  as in the ggstream template. Every pair of the five issue colours passes a
  colour-vision-deficiency check (ΔE ≥ 11). The neutral grey is reserved for the
  residual category.
- **Dates.** Four German events have day or month "00" or "32" in `eventdate`
  (e.g. 20210000). Only the year is used, and all four years are valid.
