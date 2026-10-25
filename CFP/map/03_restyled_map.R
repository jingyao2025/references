# =============================================================================
# Figure 1, restyled after an editorial reference map ("A species divided"):
#   - two-tone land (six countries analysed vs. all other countries), white sea,
#     white borders, no coastline stroke, no frame
#   - categorical colour per country, carried by circles, direct labels and bars
#     (no colour legend), italic water labels, plain one-line scale bar
#   - Inter typeface
# Two versions:
#   fig1r_restyled_circles   circles sized by events per location (counts kept)
#   fig1r_restyled_cells     50 km grid cells coloured by dominant protest form
#
# Reuses the cleaned data and geometry from 01_protest_map.R (sourced below,
# which also regenerates that script's outputs).
# Run from the repository root:  Rscript CFP/map/03_restyled_map.R
# =============================================================================

source("CFP/map/01_protest_map.R")
suppressPackageStartupMessages(library(colorspace))

base_family <- "Inter"
stopifnot(nzchar(systemfonts::match_font(base_family)$path),
          grepl("Inter", systemfonts::match_font(base_family)$path))

# -----------------------------------------------------------------------------
# Palette. Neighbouring countries on the map (Germany vs. Poland, the
# Netherlands and Austria) pass the colour-vision-deficiency check (deltaE >= 10);
# Spain and Sweden, the closest pair overall (deltaE 11.7 normal vision), never
# touch and are always named, which is the required secondary encoding.
# -----------------------------------------------------------------------------
pal_ctry <- c(Germany = "#B2182B", Poland = "#5E4FA2", Netherlands = "#EE8A2E",
              Austria = "#7A8B2E", Spain = "#C9655A", Sweden = "#9E5A8A")
col_sea   <- "white"
col_focus <- "#E4E3E0"   # six countries analysed
col_other <- "#C9C6C2"   # all other land
col_water_txt <- "#8C8C8C"
col_other_txt <- "#6F6B66"

to_xy <- function(lon, lat) {
  st_coordinates(st_transform(st_sfc(lapply(seq_along(lon), function(i)
    st_point(c(lon[i], lat[i]))), crs = 4326), crs_eu))
}
place <- function(df) { xy <- to_xy(df$lon, df$lat); df$x <- xy[, 1]; df$y <- xy[, 2]; df }

# Labels placed by hand in open space next to each country (lon, lat)
ctry_lab <- place(tribble(
  ~country,       ~lon,  ~lat,  ~label,
  "Germany",       4.2,  49.4,  "Germany",
  "Poland",       19.3,  53.9,  "Poland",
  "Netherlands",   3.3,  54.5,  "Netherlands",
  "Austria",      14.6,  46.1,  "Austria",
  "Spain",        -4.6,  38.4,  "Spain",
  "Sweden",       16.0,  64.6,  "Sweden"
))
water_lab <- place(tribble(
  ~lon,  ~lat,  ~label,
  -7.2,  45.4,  "Atlantic\nOcean",
   4.6,  56.6,  "North\nSea",
  19.6,  56.0,  "Baltic\nSea",
   5.6,  38.9,  "Mediterranean Sea"
))
other_lab <- place(tibble(lon = 2.2, lat = 46.4, label = "Countries not\nanalysed here"))

# One-line scale bar, bottom-right (as requested earlier)
scale_line <- function(xlim, ylim, km = 500, size = 2.1) {
  w <- km * 1000
  x1 <- xlim[2] - 0.06 * diff(xlim); x0 <- x1 - w
  y0 <- ylim[1] + 0.04 * diff(ylim); tk <- 0.008 * diff(ylim)
  list(
    annotate("segment", x = x0, xend = x1, y = y0, yend = y0, linewidth = 0.4, colour = "grey15"),
    annotate("segment", x = c(x0, x1), xend = c(x0, x1), y = y0, yend = y0 + tk,
             linewidth = 0.4, colour = "grey15"),
    ggrepel::geom_text_repel(data = data.frame(x = (x0 + x1) / 2, y = y0 + 1.2 * tk,
                                               label = paste(km, "km")),
                             aes(x, y, label = label), inherit.aes = FALSE, vjust = 0,
                             size = size, family = base_family, colour = "grey15",
                             bg.color = "white", bg.r = 0.12, force = 0, force_pull = 0,
                             segment.colour = NA, max.overlaps = Inf, seed = 1)
  )
}

halo_text <- function(data, size, colour = NULL, fontface = "plain", lineheight = 0.95) {
  args <- list(
    data = data,
    mapping = if (is.null(colour)) aes(x, y, label = label, colour = country) else aes(x, y, label = label),
    inherit.aes = FALSE, size = size, family = base_family, fontface = fontface,
    lineheight = lineheight, bg.color = "white", bg.r = 0.13, force = 0, force_pull = 0,
    segment.colour = NA, max.overlaps = Inf, seed = 1)
  if (!is.null(colour)) args$colour <- colour
  do.call(ggrepel::geom_text_repel, args)
}

basemap <- function() {
  list(
    geom_sf(data = world, fill = col_other, colour = "white", linewidth = 0.18),
    geom_sf(data = focus_poly, fill = col_focus, colour = "white", linewidth = 0.3)
  )
}
water_labels <- function() list(
  geom_text(data = water_lab, aes(x, y, label = label), inherit.aes = FALSE,
            size = 2.2, family = base_family, fontface = "italic", colour = col_water_txt,
            lineheight = 0.9),
  geom_text(data = other_lab, aes(x, y, label = label), inherit.aes = FALSE,
            size = 2.1, family = base_family, fontface = "italic", colour = col_other_txt,
            lineheight = 0.9)
)

theme_ed <- theme_void(base_family = base_family, base_size = 8.5) +
  theme(
    panel.background = element_rect(fill = col_sea, colour = NA),
    plot.background  = element_rect(fill = "white", colour = NA),
    plot.title       = element_text(face = "bold", size = 8.5, margin = margin(b = 3)),
    plot.title.position = "plot",
    legend.position  = c(0.02, 0.98),
    legend.justification = c(0, 1),
    legend.background = element_rect(fill = alpha("white", 0.92), colour = NA),
    legend.margin    = margin(3, 5, 3, 4),
    legend.title     = element_text(size = 6.5, face = "bold", colour = "grey20"),
    legend.text      = element_text(size = 6.3, colour = "grey20"),
    legend.key       = element_blank(),
    legend.key.size  = unit(0.3, "cm"),
    plot.margin      = margin(0, 4, 0, 0)
  )

# -----------------------------------------------------------------------------
# Panel B (shared by both versions): ranked totals in the country colours
# -----------------------------------------------------------------------------
bar_df <- totals |>
  mutate(share = events / n_total,
         country = factor(country, levels = rev(country)),
         value_lab = paste0(fmt(events), " (", label_percent(accuracy = 0.1)(share), ")"))
stopifnot(sum(bar_df$events) == n_total, all(names(pal_ctry) %in% bar_df$country))

p_bar_r <- ggplot(bar_df, aes(x = events, y = country, fill = country)) +
  geom_col(width = 0.62) +
  geom_text(aes(label = value_lab), hjust = -0.08, size = 2.45,
            family = base_family, colour = "grey15") +
  scale_fill_manual(values = pal_ctry, guide = "none") +
  scale_x_continuous(name = "Number of protest events, 2008–2021", labels = fmt,
                     breaks = seq(0, 1500, 500), limits = c(0, 2150), expand = expansion(0)) +
  labs(y = NULL, title = "B. Total events by country") +
  theme_minimal(base_family = base_family, base_size = 8) +
  theme(plot.title = element_text(face = "bold", size = 8.5, margin = margin(b = 3)),
        plot.title.position = "plot",
        panel.grid.major.y = element_blank(), panel.grid.minor = element_blank(),
        panel.grid.major.x = element_line(colour = "grey90", linewidth = 0.25),
        # one colour per row, bottom to top in factor-level order
        axis.text.y = element_text(size = 8, face = "bold",
                                   colour = unname(darken(pal_ctry[levels(bar_df$country)], 0.15))),
        axis.text.x = element_text(size = 7, colour = "grey35"),
        axis.title.x = element_text(size = 7, colour = "grey35", margin = margin(t = 4)),
        axis.line.x = element_line(colour = "grey45", linewidth = 0.3),
        plot.margin = margin(0, 2, 0, 8))

# -----------------------------------------------------------------------------
# Version 1: circles (counts kept), coloured by country
# -----------------------------------------------------------------------------
loc_r <- loc |> arrange(desc(events))   # large circles first, small ones on top

p_map_circles <- ggplot() +
  basemap() +
  geom_sf(data = loc_r, aes(size = events, fill = countryname, colour = countryname),
          shape = 21, stroke = 0.2, alpha = 0.6) +
  water_labels() +
  halo_text(ctry_lab |> mutate(country = factor(country, levels = names(pal_ctry))),
            size = 2.7, fontface = "bold") +
  scale_line(xlim_ls, ylim_ls) +
  scale_fill_manual(values = pal_ctry, guide = "none") +
  scale_colour_manual(values = darken(pal_ctry, 0.3), guide = "none") +
  scale_size_area(name = "Events per location", max_size = 8.5,
                  breaks = size_breaks, labels = fmt) +
  guides(size = guide_legend(override.aes = list(fill = "grey70", colour = "grey35", alpha = 1))) +
  coord_sf(crs = crs_eu, xlim = xlim_ls, ylim = ylim_ls, expand = FALSE, datum = NA) +
  labs(title = "A. Location of events") +
  theme_ed

note_circles <- paste0(
  "Note: Unit = protest event, attributed to the country of coding; N = ", fmt(n_total),
  ". Circles show the primary location of the ", fmt(nrow(mapped)),
  " events held inside the coding country; ", nrow(not_mapped),
  "\nevents are counted in panel B but not drawn (no coordinates, online or unknown: ",
  n_status("No coordinates (incl. Online/Unknown)"), "; nationwide: ",
  n_status("Nationwide (no single location)"), "; abroad or at sea: ",
  n_status("Outside the coding country"), ").\n",
  "Source: CFP – Comparative Far-Right Protest database, V1-2026 (Castelli Gattinara et al. 2026). ",
  "Boundaries: Natural Earth 1:50m; projection ETRS89-LAEA."
)

compose <- function(p_map, note, title) {
  (p_map | p_bar_r) + plot_layout(widths = c(1.15, 1)) +
    plot_annotation(
      title = title, caption = note,
      theme = theme(
        plot.title = element_text(family = base_family, face = "bold", size = 10.5,
                                  margin = margin(b = 6)),
        plot.caption = element_text(family = base_family, size = 5.9, colour = "grey30",
                                    hjust = 0, lineheight = 1.2, margin = margin(t = 6)),
        plot.margin = margin(6, 6, 6, 6)))
}
compose_clean <- function(p_map) {
  (p_map | p_bar_r) + plot_layout(widths = c(1.15, 1)) +
    plot_annotation(theme = theme(plot.margin = margin(4, 4, 4, 4)))
}

title_r <- "Far-right protest events in six European countries, 2008–2021"
save_fig(compose(p_map_circles, note_circles, title_r), "fig1r_restyled_circles", 6.5, 5.0, tiff = TRUE)
save_fig(compose_clean(p_map_circles), "fig1r_restyled_circles_clean", 6.5, 4.5, tiff = TRUE)

# -----------------------------------------------------------------------------
# Version 2: 50 km grid cells coloured by the cell's dominant protest form
#   Grid: 50 x 50 km cells aligned to the ETRS89-LAEA origin (the basis of the
#   EEA reference grid). Dominant form = the most frequent form among the
#   cell's events; ties go to the more contentious form, and are counted.
# -----------------------------------------------------------------------------
cell_m <- 50000
form_lv <- c("Demonstrative", "Confrontational", "Violent")
stopifnot(all(mapped$protest_form %in% form_lv))

xy <- st_coordinates(mapped)
cells <- st_drop_geometry(mapped) |>
  mutate(cx = floor(xy[, 1] / cell_m) * cell_m, cy = floor(xy[, 2] / cell_m) * cell_m,
         form = factor(protest_form, levels = form_lv)) |>
  count(cx, cy, form, name = "k") |>      # cells are shared across borders
  group_by(cx, cy) |>
  mutate(events = sum(k), tie = sum(k == max(k)) > 1) |>
  arrange(desc(k), desc(as.integer(form)), .by_group = TRUE) |>
  slice(1) |> ungroup()
stopifnot(sum(cells$events) == nrow(mapped), !anyDuplicated(cells[c("cx", "cy")]))
n_ties <- sum(cells$tie)
cat("cells:", nrow(cells), " ties broken toward the more contentious form:", n_ties, "\n")
write.csv(cells |> transmute(cell_x = cx, cell_y = cy, events,
                             dominant_form = form, tie),
          file.path(out_dir, "table_cells_50km.csv"), row.names = FALSE, fileEncoding = "UTF-8")

pal_form <- c(Demonstrative = "#F2A65A", Confrontational = "#D9572B", Violent = "#7F1D1D")

p_map_cells <- ggplot() +
  basemap() +
  geom_rect(data = cells, aes(xmin = cx, xmax = cx + cell_m, ymin = cy, ymax = cy + cell_m,
                              fill = form), colour = NA) +
  water_labels() +
  halo_text(ctry_lab, size = 2.7, fontface = "bold", colour = "grey15") +
  scale_line(xlim_ls, ylim_ls) +
  scale_fill_manual(values = pal_form, name = "Most frequent\nprotest form", drop = FALSE) +
  coord_sf(crs = crs_eu, xlim = xlim_ls, ylim = ylim_ls, expand = FALSE, datum = NA) +
  labs(title = "A. Most frequent protest form, 50 km cells") +
  theme_ed

note_cells <- paste0(
  "Note: Panel A groups the ", fmt(nrow(mapped)), " events with a location inside the coding country into ",
  nrow(cells), " cells of 50 × 50 km (ETRS89-LAEA grid) and colours each by\nits most frequent ",
  "protest form (CFP recoded categories); ", n_ties, " ties go to the more contentious form. Cells do not ",
  "show how many events they hold.\nPanel B counts all ", fmt(n_total), " events. ",
  "Source: CFP – Comparative Far-Right Protest database, V1-2026 (Castelli Gattinara et al. 2026). ",
  "Boundaries: Natural Earth 1:50m."
)
save_fig(compose(p_map_cells, note_cells, title_r), "fig1r_restyled_cells", 6.5, 5.0)
save_fig(compose_clean(p_map_cells), "fig1r_restyled_cells_clean", 6.5, 4.5)
