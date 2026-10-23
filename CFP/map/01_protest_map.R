# =============================================================================
# Figure: Far-right protest events in six European countries, 2008-2021
# Data:   CFP - Comparative Far-Right Protest database, V1-2026
#         (Castelli Gattinara, Segers, Froio, Jupskas & Pirro 2026,
#          https://doi.org/10.7910/DVN/T7BZ5I)
# Basemap: Natural Earth 1:50m admin-0 countries (via rnaturalearthdata)
#
# Output (in CFP/map/output/):
#   fig1_protest_locations_map.{pdf,png,tiff}  bubble map + country totals
#   fig1b_protest_totals_choropleth.{pdf,png}   choropleth of country totals
#   table_country_totals.csv                    numbers behind the labels
#   table_location_counts.csv                   numbers behind the bubbles
#   qa_events_not_mapped.csv                    every event not drawn as a point
#
# Run from the repository root:  Rscript CFP/map/01_protest_map.R
# =============================================================================

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(sf)
  library(ggplot2)
  library(ggrepel)
  library(scales)
})

sf_use_s2(FALSE)
invisible(Sys.setlocale("LC_CTYPE", "C.UTF-8"))

data_file <- "CFP/CFP_Anonymized V1-2026.xlsx"
out_dir   <- "CFP/map/output"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

focus <- c("Austria", "Germany", "Netherlands", "Poland", "Spain", "Sweden")
crs_eu <- 3035            # ETRS89 / LAEA Europe, the EU standard for pan-European maps
coast_tolerance_m  <- 25000 # coastal cities can fall just outside the 1:50m coastline
border_tolerance_m <- 2000  # border towns (Guben, Ostritz, Konstanz, Freilassing; all
                            # <= 1.4 km) fall just across the 1:50m border; the nearest
                            # genuinely foreign location in the data is 21.8 km away

# -----------------------------------------------------------------------------
# 1. Load and clean events
# -----------------------------------------------------------------------------
raw <- read_excel(data_file, sheet = "Data", guess_max = 10000)

# lat/long are stored as text; two rows use a decimal comma ("54,30663")
to_num <- function(x) suppressWarnings(as.numeric(str_replace(str_trim(x), ",", ".")))

ev <- raw |>
  filter(countryname %in% focus) |>
  mutate(lat_n = to_num(lat), lon_n = to_num(long))

stopifnot(!anyDuplicated(raw$eventid))

# Country totals: the unit is the event, attributed to the country of coding
# (countrycode), which is how the CFP database defines its national cases.
totals <- ev |>
  group_by(country = countryname) |>
  summarise(events = n(),
            first_event = min(eventdate), last_event = max(eventdate),
            .groups = "drop") |>
  arrange(desc(events))
write.csv(totals, file.path(out_dir, "table_country_totals.csv"), row.names = FALSE, fileEncoding = "UTF-8")
n_total <- sum(totals$events)

# -----------------------------------------------------------------------------
# 2. Basemap
# -----------------------------------------------------------------------------
world <- rnaturalearthdata::countries50 |>
  st_make_valid() |>
  select(admin) |>
  st_transform(crs_eu)

focus_poly <- world |> filter(admin %in% focus)
stopifnot(setequal(focus_poly$admin, focus))

# -----------------------------------------------------------------------------
# 3. Classify each event's primary location
#    - no coordinates / "Online" / "Unknown"    -> not mapped
#    - "Nationwide" (coded at a capital)         -> not mapped (no point location)
#    - inside the coding country, in the sea within 25 km of it, or inside a
#      neighbour within 2 km of it (generalised border)  -> mapped
#    - inside another country or open sea        -> not mapped (abroad)
# -----------------------------------------------------------------------------
pts <- ev |>
  filter(!is.na(lat_n), !is.na(lon_n)) |>
  st_as_sf(coords = c("lon_n", "lat_n"), crs = 4326, remove = FALSE) |>
  st_transform(crs_eu)

inside_idx <- st_intersects(pts, world)
pts$inside <- vapply(inside_idx, function(i) if (length(i)) world$admin[i[1]] else NA_character_, "")

own_poly <- focus_poly[match(pts$countryname, focus_poly$admin), ]
pts$dist_own_m <- as.numeric(st_distance(pts, own_poly, by_element = TRUE))

pts <- pts |>
  mutate(status = case_when(
    str_detect(place, regex("^nationwide$", ignore_case = TRUE)) ~ "Nationwide (no single location)",
    inside == countryname                                         ~ "mapped",
    is.na(inside) & dist_own_m <= coast_tolerance_m              ~ "mapped",
    dist_own_m <= border_tolerance_m                              ~ "mapped",
    TRUE                                                          ~ "Outside the coding country"
  ))

not_mapped <- bind_rows(
  ev |> filter(is.na(lat_n) | is.na(lon_n)) |>
    mutate(status = "No coordinates (incl. Online/Unknown)"),
  pts |> st_drop_geometry() |> filter(status != "mapped")
) |>
  select(countryname, eventid, eventdate, place, lat_n, lon_n, status)
write.csv(not_mapped, file.path(out_dir, "qa_events_not_mapped.csv"), row.names = FALSE, fileEncoding = "UTF-8")

mapped <- pts |> filter(status == "mapped")
stopifnot(nrow(mapped) + nrow(not_mapped) == nrow(ev))

# Aggregate events by location. CFP geocodes at city level, but the same city is
# sometimes stored with different decimal precision (e.g. Berlin 52.52001 vs
# 52.5200066), so coordinates are grouped at 0.01 degrees (~1 km).
loc <- mapped |>
  st_drop_geometry() |>
  mutate(lat_k = round(lat_n, 2), lon_k = round(lon_n, 2)) |>
  group_by(countryname, lat_k, lon_k) |>
  summarise(events = n(), place = names(sort(table(place), decreasing = TRUE))[1],
            lat_n = mean(lat_n), lon_n = mean(lon_n), .groups = "drop") |>
  arrange(desc(events)) |>
  st_as_sf(coords = c("lon_n", "lat_n"), crs = 4326, remove = FALSE) |>
  st_transform(crs_eu)
stopifnot(sum(loc$events) == nrow(mapped))
write.csv(st_drop_geometry(loc) |> select(countryname, place, lat_n, lon_n, events),
          file.path(out_dir, "table_location_counts.csv"), row.names = FALSE, fileEncoding = "UTF-8")

coverage <- ev |> count(countryname, name = "events") |>
  left_join(st_drop_geometry(mapped) |> count(countryname, name = "mapped"), by = "countryname")
print(totals); print(coverage)
cat("Total events:", n_total, " mapped as points:", nrow(mapped), "\n")

# -----------------------------------------------------------------------------
# 4. Map frame and labels
# -----------------------------------------------------------------------------
# Map window in EPSG:3035 metres: mainland Spain to northern Sweden
# (Sweden's northern tip is at y = 5.13 million; the Canary Islands are outside)
xlim <- c(2620000, 5420000)
ylim <- c(1560000, 5200000)

fmt <- label_comma()
lab <- totals |>
  mutate(label = paste0(country, "\n", fmt(events), " events"))

# Hand-placed label anchors (lon, lat) chosen to sit in open space,
# with leader lines back to each country's interior point
anchors <- tribble(
  ~country,       ~lon,  ~lat,
  "Germany",       3.3,  49.2,
  "Poland",       24.6,  55.6,
  "Netherlands",   1.0,  54.6,
  "Austria",      16.5,  45.2,
  "Spain",        -6.5,  44.3,
  "Sweden",        9.4,  63.8
)
anchor_pts <- anchors |>
  st_as_sf(coords = c("lon", "lat"), crs = 4326) |> st_transform(crs_eu)
anchor_xy <- cbind(st_drop_geometry(anchor_pts), st_coordinates(anchor_pts)) |>
  rename(lx = X, ly = Y)

# Leader target: point on surface of the mainland polygon
centre <- focus_poly |>
  st_cast("MULTIPOLYGON") |> st_cast("POLYGON") |>
  mutate(a = st_area(geometry)) |>
  group_by(admin) |> slice_max(a, n = 1) |> ungroup() |>
  st_point_on_surface() |> suppressWarnings()
centre_xy <- cbind(st_drop_geometry(centre)["admin"], st_coordinates(centre)) |>
  rename(country = admin, cx = X, cy = Y)

lab <- lab |> left_join(anchor_xy, by = "country") |> left_join(centre_xy, by = "country")

# -----------------------------------------------------------------------------
# 5. Theme
# -----------------------------------------------------------------------------
col_sea      <- "#EEF3F7"
col_land     <- "#F7F7F5"
col_border   <- "#C9C9C4"
col_focus    <- "#DEDBD3"
col_focus_bd <- "#6E6A60"
col_dot      <- "#A50F15"
base_family  <- "Liberation Sans"   # metric-compatible with Arial/Helvetica

theme_map <- theme_void(base_family = base_family, base_size = 9) +
  theme(
    panel.background = element_rect(fill = col_sea, colour = NA),
    panel.border     = element_rect(fill = NA, colour = "grey55", linewidth = 0.3),
    plot.background  = element_rect(fill = "white", colour = NA),
    plot.title       = element_text(face = "bold", size = 11, margin = margin(b = 3)),
    plot.subtitle    = element_text(size = 8.5, colour = "grey25", margin = margin(b = 6)),
    plot.caption     = element_text(size = 6.5, colour = "grey30", hjust = 0,
                                    lineheight = 1.15, margin = margin(t = 6)),
    plot.caption.position = "plot",
    plot.title.position   = "plot",
    legend.position  = c(0.015, 0.985),
    legend.justification   = c(0, 1),
    legend.background = element_rect(fill = alpha("white", 0.9), colour = "grey70", linewidth = 0.25),
    legend.margin    = margin(4, 6, 4, 6),
    legend.title     = element_text(size = 7.5, face = "bold"),
    legend.text      = element_text(size = 7),
    plot.margin      = margin(6, 6, 6, 6)
  )

# Scale bar (drawn by hand; ggspatial is not available). LAEA is equal-area, so
# scale varies slightly with position: a 500 km bar measures 493-501 km on the
# ground anywhere in these frames (checked with geodesic distances), i.e. <1.5%.
scale_bar <- function(xlim, ylim, km = 500, text_size = 2.3, height_frac = 0.009) {
  w  <- km * 1000
  x1 <- xlim[2] - 0.09 * diff(xlim); x0 <- x1 - w
  y0 <- ylim[1] + 0.035 * diff(ylim); y1 <- y0 + height_frac * diff(ylim)
  segs <- data.frame(xmin = x0 + c(0, w / 2), xmax = x0 + c(w / 2, w),
                     fill = c("grey15", "white"))
  ticks <- data.frame(x = c(x0, x0 + w / 2, x0 + w),
                      lab = c("0", format(km / 2), format(km)))
  list(
    annotate("rect", xmin = x0 - 0.025 * diff(xlim), xmax = x1 + 0.07 * diff(xlim),
             ymin = y0 - 0.012 * diff(ylim), ymax = y1 + 0.045 * diff(ylim),
             fill = alpha("white", 0.85), colour = NA),
    geom_rect(data = segs, aes(xmin = xmin, xmax = xmax, ymin = y0, ymax = y1),
              fill = segs$fill, colour = "grey15", linewidth = 0.25, inherit.aes = FALSE),
    geom_text(data = ticks, aes(x = x, y = y1 + 0.008 * diff(ylim), label = lab),
              vjust = 0, size = text_size, family = base_family, colour = "grey15",
              inherit.aes = FALSE),
    annotate("text", x = x1 + 0.015 * diff(xlim), y = (y0 + y1) / 2, label = "km",
             hjust = 0, vjust = 0.5, size = text_size, family = base_family, colour = "grey15")
  )
}

n_status <- function(x) sum(not_mapped$status == x)
caption_txt <- paste0(
  "Note: Labels give all events coded for each country, 2008–2021 (unit = protest event). ",
  "Circles show the primary location of the\n", fmt(nrow(mapped)),
  " events held inside the coding country. Not drawn but included in the totals: ", nrow(not_mapped),
  " events (no coordinates, online or\nunknown location: ", n_status("No coordinates (incl. Online/Unknown)"),
  "; coded as nationwide: ", n_status("Nationwide (no single location)"),
  "; held abroad or at sea: ", n_status("Outside the coding country"), ").\n",
  "Source: CFP – Comparative Far-Right Protest database, V1-2026 (Castelli Gattinara et al. 2026). ",
  "Boundaries: Natural Earth 1:50m.\nProjection: ETRS89-LAEA (EPSG:3035)."
)

# -----------------------------------------------------------------------------
# 6. Figure 1: proportional-symbol map with country totals
# -----------------------------------------------------------------------------
size_breaks <- c(1, 10, 50, 150, 300)
stopifnot(max(loc$events) >= max(size_breaks))

p1 <- ggplot() +
  geom_sf(data = world, fill = col_land, colour = col_border, linewidth = 0.2) +
  geom_sf(data = focus_poly, fill = col_focus, colour = col_focus_bd, linewidth = 0.35) +
  geom_sf(data = loc, aes(size = events),
          shape = 21, fill = alpha(col_dot, 0.45), colour = col_dot, stroke = 0.25) +
  geom_segment(data = lab, aes(x = lx, y = ly, xend = cx, yend = cy),
               colour = "grey20", linewidth = 0.25) +
  geom_label(data = lab, aes(x = lx, y = ly, label = label),
             family = base_family, size = 2.7, lineheight = 0.95, fontface = "bold",
             fill = "white", colour = "grey10", label.size = 0.25,
             label.padding = unit(0.15, "lines"), label.r = unit(0.05, "lines")) +
  scale_size_area(name = "Protest events\nper location", max_size = 13,
                  breaks = size_breaks, labels = fmt) +
  guides(size = guide_legend(override.aes = list(fill = alpha(col_dot, 0.45)))) +
  scale_bar(xlim, ylim) +
  coord_sf(crs = crs_eu, xlim = xlim, ylim = ylim, expand = FALSE, datum = NA) +
  labs(title = "Far-right protest events in six European countries, 2008–2021",
       subtitle = paste0("Total events by country (labels) and location of events (circles); N = ",
                         fmt(n_total), " events"),
       caption = caption_txt) +
  theme_map

# Sizes fit a US-letter text block (6.5 x 9 in with 1-inch margins).
# "_clean" versions drop title/subtitle/note so they can go in the manuscript caption.
save_fig <- function(p, name, w = 6.5, h = 8.9, tiff = FALSE) {
  ggsave(file.path(out_dir, paste0(name, ".pdf")), p, width = w, height = h, device = cairo_pdf)
  ggsave(file.path(out_dir, paste0(name, ".png")), p, width = w, height = h, dpi = 600, bg = "white")
  if (tiff) ggsave(file.path(out_dir, paste0(name, ".tiff")), p, width = w, height = h,
                   dpi = 600, bg = "white", compression = "lzw")
}
no_text <- labs(title = NULL, subtitle = NULL, caption = NULL)

save_fig(p1, "fig1_protest_locations_map", tiff = TRUE)
save_fig(p1 + no_text, "fig1_protest_locations_map_clean", h = 8.35, tiff = TRUE)

# -----------------------------------------------------------------------------
# 7. Figure 1b: choropleth of country totals (alternative, totals only)
# -----------------------------------------------------------------------------
focus_tot <- focus_poly |> left_join(totals, by = c("admin" = "country"))
bins <- c(0, 150, 250, 300, 1500)
stopifnot(all(totals$events > min(bins) & totals$events <= max(bins)))
focus_tot$cls <- cut(focus_tot$events, bins, dig.lab = 5,
                     labels = c("Up to 150", "151–250", "251–300", "More than 300"))
seq_cols <- c("#FCBBA1", "#FB6A4A", "#CB181D", "#67000D")  # ColorBrewer Reds (sequential)

p2 <- ggplot() +
  geom_sf(data = world, fill = col_land, colour = col_border, linewidth = 0.2) +
  geom_sf(data = focus_tot, aes(fill = cls), colour = "white", linewidth = 0.35) +
  geom_segment(data = lab, aes(x = lx, y = ly, xend = cx, yend = cy),
               colour = "grey20", linewidth = 0.25) +
  geom_label(data = lab, aes(x = lx, y = ly, label = label),
             family = base_family, size = 2.7, lineheight = 0.95, fontface = "bold",
             fill = "white", colour = "grey10", label.size = 0.25,
             label.padding = unit(0.15, "lines"), label.r = unit(0.05, "lines")) +
  scale_fill_manual(name = "Protest events,\n2008–2021", values = seq_cols, drop = FALSE) +
  scale_bar(xlim, ylim) +
  coord_sf(crs = crs_eu, xlim = xlim, ylim = ylim, expand = FALSE, datum = NA) +
  labs(title = "Far-right protest events in six European countries, 2008–2021",
       subtitle = paste0("Total number of events by country; N = ", fmt(n_total), " events"),
       caption = paste0(
         "Note: Unit = protest event, attributed to the country of coding.\n",
         "Source: CFP – Comparative Far-Right Protest database V1-2026 (Castelli Gattinara et al. 2026).\n",
         "Boundaries: Natural Earth (1:50m). Projection: ETRS89-LAEA (EPSG:3035).")) +
  theme_map

save_fig(p2, "fig1b_protest_totals_choropleth", h = 8.6)
save_fig(p2 + no_text, "fig1b_protest_totals_choropleth_clean", h = 8.35)

# -----------------------------------------------------------------------------
# 8. Figure 1, landscape: location map (left) + ranked country totals (right)
#    The Spain-to-Sweden extent is taller than wide (about 1.3:1), so a
#    north-up map cannot fill a landscape frame without shrinking the six
#    countries; the freed width carries the totals as a bar chart instead.
# -----------------------------------------------------------------------------
library(patchwork)

# Same anchors as the portrait map, except Poland's label is pulled in from the edge
poland_ls <- st_coordinates(st_transform(st_sfc(st_point(c(21.3, 56.6)), crs = 4326), crs_eu))
lab_ls <- lab |>
  mutate(label = country,
         lx = ifelse(country == "Poland", poland_ls[1, "X"], lx),
         ly = ifelse(country == "Poland", poland_ls[1, "Y"], ly))
xlim_ls <- c(2640000, 5360000)   # trimmed to the six countries' extent
ylim_ls <- c(1560000, 5170000)

p_map_ls <- ggplot() +
  geom_sf(data = world, fill = col_land, colour = col_border, linewidth = 0.15) +
  geom_sf(data = focus_poly, fill = col_focus, colour = col_focus_bd, linewidth = 0.3) +
  geom_sf(data = loc, aes(size = events),
          shape = 21, fill = alpha(col_dot, 0.45), colour = col_dot, stroke = 0.2) +
  geom_segment(data = lab_ls, aes(x = lx, y = ly, xend = cx, yend = cy),
               colour = "grey20", linewidth = 0.2) +
  geom_label(data = lab_ls, aes(x = lx, y = ly, label = label),
             family = base_family, size = 2.4, fontface = "bold",
             fill = "white", colour = "grey10", label.size = 0.2,
             label.padding = unit(0.12, "lines"), label.r = unit(0.05, "lines")) +
  scale_size_area(name = "Events per\nlocation", max_size = 8.5,
                  breaks = size_breaks, labels = fmt) +
  guides(size = guide_legend(override.aes = list(fill = alpha(col_dot, 0.45)))) +
  scale_bar(xlim_ls, ylim_ls, text_size = 2.0) +
  coord_sf(crs = crs_eu, xlim = xlim_ls, ylim = ylim_ls, expand = FALSE, datum = NA) +
  labs(title = "A. Location of events") +
  theme_map +
  theme(plot.title = element_text(face = "bold", size = 8.5, margin = margin(b = 3)),
        legend.title = element_text(size = 6.5, face = "bold"),
        legend.text  = element_text(size = 6.5),
        legend.key.size = unit(0.32, "cm"),
        legend.margin = margin(3, 4, 3, 4),
        plot.margin = margin(0, 4, 0, 0))

bar_df <- totals |>
  mutate(share = events / n_total,
         country = factor(country, levels = rev(country)),
         value_lab = paste0(fmt(events), " (", label_percent(accuracy = 0.1)(share), ")"))
stopifnot(sum(bar_df$events) == n_total)

p_bar <- ggplot(bar_df, aes(x = events, y = country)) +
  geom_col(fill = col_dot, width = 0.62) +
  geom_text(aes(label = value_lab), hjust = -0.08, size = 2.5,
            family = base_family, colour = "grey10") +
  scale_x_continuous(name = "Number of protest events, 2008–2021",
                     labels = fmt, breaks = seq(0, 1500, 500),
                     limits = c(0, 2150), expand = expansion(mult = c(0, 0))) +
  labs(y = NULL, title = "B. Total events by country") +
  theme_minimal(base_family = base_family, base_size = 8) +
  theme(plot.title = element_text(face = "bold", size = 8.5, margin = margin(b = 3)),
        plot.title.position = "plot",
        panel.grid.major.y = element_blank(),
        panel.grid.minor   = element_blank(),
        panel.grid.major.x = element_line(colour = "grey88", linewidth = 0.25),
        axis.text.y  = element_text(size = 8, colour = "grey10", face = "bold"),
        axis.text.x  = element_text(size = 7, colour = "grey30"),
        axis.title.x = element_text(size = 7, colour = "grey30", margin = margin(t = 4)),
        axis.line.x  = element_line(colour = "grey40", linewidth = 0.3),
        plot.margin  = margin(0, 2, 0, 8))

caption_ls <- paste0(
  "Note: Unit = protest event, attributed to the country of coding; N = ", fmt(n_total),
  ". Panel A shows the primary location of the ", fmt(nrow(mapped)),
  " events held inside the\ncoding country; ", nrow(not_mapped),
  " events are counted in panel B but not drawn (no coordinates, online or unknown: ",
  n_status("No coordinates (incl. Online/Unknown)"), "; nationwide: ",
  n_status("Nationwide (no single location)"), "; abroad or at sea: ",
  n_status("Outside the coding country"), ").\n",
  "Source: CFP – Comparative Far-Right Protest database, V1-2026 (Castelli Gattinara et al. 2026). ",
  "Boundaries: Natural Earth 1:50m.\nProjection: ETRS89-LAEA; the scale bar is accurate to within 1.5% across panel A."
)

p_ls <- (p_map_ls | p_bar) +
  plot_layout(widths = c(1.15, 1)) +
  plot_annotation(
    title = "Far-right protest events in six European countries, 2008–2021",
    caption = caption_ls,
    theme = theme(
      plot.title   = element_text(family = base_family, face = "bold", size = 10.5,
                                  margin = margin(b = 6)),
      plot.caption = element_text(family = base_family, size = 6, colour = "grey30",
                                  hjust = 0, lineheight = 1.15, margin = margin(t = 6)),
      plot.margin  = margin(6, 6, 6, 6)))

p_ls_clean <- (p_map_ls | p_bar) + plot_layout(widths = c(1.15, 1)) +
  plot_annotation(theme = theme(plot.margin = margin(4, 4, 4, 4)))

save_fig(p_ls,       "fig1_landscape_map_and_totals",       w = 6.5, h = 5.0, tiff = TRUE)
save_fig(p_ls_clean, "fig1_landscape_map_and_totals_clean", w = 6.5, h = 4.5, tiff = TRUE)

writeLines(capture.output(sessionInfo()), file.path(out_dir, "sessionInfo.txt"))
