# Figure 1: Far-right protest events in six countries, 2008–2021

Reproduce from the repository root with `Rscript CFP/map/01_protest_map.R`
(R 4.3; ggplot2, sf, rnaturalearthdata, readxl, dplyr, tidyr, stringr, scales).

## Files in `output/`

| File | Use |
|---|---|
| `fig1_protest_locations_map.{pdf,png,tiff}` | Main figure: country totals in the labels, event locations as circles. It has its own title and note. |
| `fig1_protest_locations_map_clean.{pdf,png,tiff}` | Same map with no title or note. Use this one when the caption goes in the manuscript. |
| `fig1b_protest_totals_choropleth[_clean].{pdf,png}` | Alternative figure: a choropleth of the country totals only. |
| `table_country_totals.csv` | The numbers behind the labels. |
| `table_location_counts.csv` | The numbers behind the circles. |
| `qa_events_not_mapped.csv` | Every event that is counted in the totals but not drawn, with the reason. |

Size: 6.5 in wide, which fits a US-letter page with 1-inch margins. The PDFs are vector
with embedded fonts. The PNG and TIFF files are 600 dpi.

## Counts (by `countryname`, the country of coding)

| Country | Events |
|---|---:|
| Germany | 1,449 |
| Spain | 286 |
| Sweden | 269 |
| Poland | 252 |
| Netherlands | 165 |
| Austria | 102 |
| **Total** | **2,523** |

These counts were checked twice: once in R and once separately in Python (pandas).

## Methodological choices

- **Unit:** one row is one protest event (`eventid` is unique). Each event belongs to the
  country it was coded for, as defined in the CFP documentation.
- **Circles:** each event is drawn at its primary location (`lat`/`long`). Coordinates
  within about 1 km of each other are grouped together. This is needed because the same
  city is sometimes stored at different precision (e.g. Berlin is 52.52001 in some rows
  and 52.5200066 in others).
- **Events not drawn (141 of 2,523; they are still counted in the totals):**
  - 60 have no coordinates (Online, Unknown, or missing).
  - 42 are coded "Nationwide". These rows carry the capital's coordinates, so they have
    no real point location.
  - 39 took place abroad or at sea, for example Dutch actors in Berlin or Defend Europe
    in the Mediterranean. The codebook allows these (footnote 10).
- **Point-in-country check:** done against Natural Earth 1:50m borders, with two
  tolerances:
  - 25 km for coastal points that fall in the sea, such as Stockholm.
  - 2 km for border towns: Guben, Ostritz, Konstanz and Freilassing are all at most
    1.4 km across the simplified border. The nearest truly foreign location in the data
    is 21.8 km away.
- **Two text fixes:** lat/long are stored as text in the source file, and two values use
  a decimal comma. Both were converted to numbers.

## Data-quality flags (left unchanged in the data, reported here)

- Sweden, "Kristianstad": the coordinates (58.16 N, 8.02 E) point to Kristiansand in
  Norway, so this event is treated as abroad.
- Sweden, "Bohuslän": the coordinates (60.13 N, 18.64 E) are on the Uppland coast, not
  in Bohuslän on the west coast. The point is drawn where the coordinates put it.
- Germany: "Rendsburg" (2 events) and "Rotenburg an der Wümme" (1 event) have no
  coordinates, so they are not drawn.
