# =============================================================================
# Figure 2: Issue focus of far-right protest events, six countries, 2008-2021
# Streamgraphs built with ggstream (Sjoberg), following the ggstream /
# r-charts.com streamgraph template: geom_stream() + geom_stream_label(),
# minimal theme with vertical grid only, hue-matched darker outlines.
#
# Data: CFP - Comparative Far-Right Protest database, V1-2026
#       (Castelli Gattinara et al. 2026, https://doi.org/10.7910/DVN/T7BZ5I)
#
# Output (CFP/streams/output/):
#   fig2_issue_streams_pooled.{pdf,png,tiff}     A: issue frequency, B: issue share
#   fig3_issue_shares_by_country.{pdf,png,tiff}  share streams, one panel per country
#   fig3_<country>.{pdf,png}                     the same, one file per country
#   table_issue_counts_by_year.csv               numbers behind every stream
#   table_issue_ranking.csv                      how the five issues were chosen
#   qa_stream_accuracy.csv                       drawn band vs. true yearly value
#
# Run from the repository root:  Rscript CFP/streams/02_issue_streams.R
# =============================================================================

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(ggplot2)
  library(ggstream)
  library(colorspace)
  library(patchwork)
  library(scales)
})

invisible(Sys.setlocale("LC_CTYPE", "C.UTF-8"))
# Off-screen device for text-size calculations, so fonts resolve through Cairo
options(device = function(...) png(tempfile(), type = "cairo"))

data_file <- "CFP/CFP_Anonymized V1-2026.xlsx"
out_dir   <- "CFP/streams/output"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

focus <- c("Austria", "Germany", "Netherlands", "Poland", "Spain", "Sweden")
years <- 2008:2021
base_family <- "Liberation Sans"

# -----------------------------------------------------------------------------
# 1. Events and issue mentions
#    Each event carries up to three issue codes (Issue1-Issue3); the codebook
#    does not rank them. The unit is the issue mention: an event counts once
#    for every distinct issue it raises (115 events repeat an issue across
#    slots; these are counted once).
# -----------------------------------------------------------------------------
raw <- read_excel(data_file, sheet = "Data", guess_max = 10000)

ev <- raw |>
  filter(countryname %in% focus) |>
  mutate(year = as.integer(eventdate) %/% 10000L)
stopifnot(all(ev$year %in% years), !anyDuplicated(raw$eventid))

mentions <- ev |>
  select(countryname, eventid, year, Issue1, Issue2, Issue3) |>
  pivot_longer(Issue1:Issue3, names_to = "slot", values_to = "issue") |>
  filter(!is.na(issue)) |>
  distinct(countryname, eventid, year, issue)

# Five most frequent issues across the six countries combined
ranking <- mentions |>
  count(issue, name = "mentions", sort = TRUE) |>
  mutate(share = mentions / sum(mentions), rank = row_number())
# Robustness: ranking on the first-listed issue only
ranking_issue1 <- ev |> filter(!is.na(Issue1)) |> count(issue = Issue1, sort = TRUE)
ranking <- ranking |>
  left_join(ranking_issue1 |> mutate(rank_issue1 = row_number()) |>
              select(issue, events_issue1 = n, rank_issue1), by = "issue")
write.csv(ranking, file.path(out_dir, "table_issue_ranking.csv"), row.names = FALSE)

top5 <- ranking$issue[1:5]
stopifnot(setequal(top5, ranking_issue1$issue[1:5]))  # same five either way
print(ranking)

# Display labels: the dataset's own category labels without the numeric code
clean_label <- function(x) {
  x <- str_remove(x, "^\\d+\\s*-\\s*")
  x <- str_replace_all(x, " and ", " & ")
  paste0(str_sub(x, 1, 1), str_to_lower(str_sub(x, 2)))
}
other_lab <- "All other issues"
lv <- c(clean_label(top5), other_lab)

mentions <- mentions |>
  mutate(grp = factor(if_else(issue %in% top5, clean_label(issue), other_lab), levels = lv))

# -----------------------------------------------------------------------------
# 2. Yearly counts (pooled and by country), with zero-filled gaps
# -----------------------------------------------------------------------------
count_by_year <- function(df) {
  df |> count(year, grp, .drop = FALSE) |>
    complete(year = years, grp, fill = list(n = 0)) |>
    group_by(year) |> mutate(share = n / sum(n)) |> ungroup()
}
pooled  <- count_by_year(mentions)
by_ctry <- mentions |> group_by(country = countryname) |>
  group_modify(~ count_by_year(.x)) |> ungroup()

events_per_year <- ev |> count(country = countryname, year) |>
  complete(country = focus, year = years, fill = list(n = 0))
stopifnot(all(events_per_year$n > 0))   # every country-year has events

write.csv(bind_rows(mutate(pooled, country = "All six countries"), by_ctry) |>
            select(country, year, issue = grp, mentions = n, share) |>
            mutate(share = round(share, 4)),
          file.path(out_dir, "table_issue_counts_by_year.csv"), row.names = FALSE)

# -----------------------------------------------------------------------------
# 3. Smoothing that stays faithful to the yearly values
#    geom_stream() places the 14 yearly values on a fine grid, fills the gaps
#    with zeros and fits a smoothing spline. With the template defaults
#    (bw = 0.75) the drawn shares miss the yearly values by up to 6 points
#    (14 points for Austria). Instead, each issue's yearly count is
#    interpolated with a monotone (Fritsch-Carlson) spline, which passes
#    through every yearly value and never overshoots or goes negative, and
#    geom_stream() is run on that grid with bw = 0 (no extra smoothing).
#    Section 6 verifies the drawn bands against the yearly values.
# -----------------------------------------------------------------------------
step <- 0.05
grid_x <- seq(min(years), max(years), by = step)
interpolate <- function(cnt) {
  cnt |> group_by(grp) |>
    group_modify(~ tibble(year = grid_x,
                          n = pmax(0, splinefun(.x$year, .x$n, method = "monoH.FC")(grid_x)))) |>
    ungroup()
}
stream_args <- list(bw = 0, n_grid = length(grid_x), extra_span = 0)

pooled_fine  <- interpolate(pooled)
by_ctry_fine <- by_ctry |> group_by(country) |> group_modify(~ interpolate(.x)) |> ungroup()

# -----------------------------------------------------------------------------
# 4. Style (template: fill lightened, outline darkened in the same hue)
# -----------------------------------------------------------------------------
# Okabe-Ito hues; every pair of the five passes a colour-vision-deficiency
# separation check (deltaE >= 11 for deutan/protan). Grey = residual category.
pal <- setNames(c("#0072B2", "#E69F00", "#56B4E9", "#D55E00", "#009E73", "#BDBDBD"), lv)
pal_fill <- lighten(pal, 0.15)
pal_line <- darken(pal, 0.45)

year_breaks <- seq(2008, 2020, 2)

theme_stream <- theme_minimal(base_family = base_family, base_size = 8.5) +
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank(),
    panel.grid.minor.x = element_blank(),
    panel.grid.major.x = element_line(colour = "grey85", linewidth = 0.3),
    axis.text   = element_text(colour = "grey25"),
    axis.title  = element_text(colour = "grey25", size = 7.5),
    axis.ticks.x = element_line(colour = "grey60", linewidth = 0.3),
    axis.ticks.length.x = unit(2, "pt"),
    plot.title  = element_text(face = "bold", size = 9, margin = margin(b = 2)),
    plot.subtitle = element_text(size = 7.5, colour = "grey35", margin = margin(b = 4)),
    plot.title.position = "plot",
    legend.position = "bottom",
    legend.title = element_blank(),
    legend.text  = element_text(size = 7.5),
    legend.key.size = unit(0.35, "cm"),
    legend.spacing.x = unit(0.15, "cm")
  )

fill_scale <- list(
  scale_fill_manual(values = pal_fill, breaks = lv, drop = FALSE),
  scale_colour_manual(values = pal_line, breaks = lv, drop = FALSE, guide = "none"),
  guides(fill = guide_legend(nrow = 2, byrow = TRUE,
                             override.aes = list(colour = pal_line, linewidth = 0.3)))
)
x_scale <- scale_x_continuous(breaks = year_breaks, minor_breaks = years,
                              expand = expansion(mult = c(0.01, 0.01)))
x_lim_ctry <- range(years) + c(-0.5, 0.5)   # shared by stream and bar strip
x_scale_ctry <- scale_x_continuous(breaks = c(2008, 2012, 2016, 2020), limits = x_lim_ctry,
                                   expand = expansion(mult = c(0, 0)))

stream_layer <- function(type, lw = 0.25) {
  do.call(geom_stream, c(list(type = type, linewidth = lw), stream_args))
}
# Direct labels: geom_stream_label() places labels at the widest window and can
# push them past the panel edge. Here each label sits at the year (away from
# the edges) where its band is thickest, at the band's vertical midpoint, read
# from the polygons ggstream actually draws.
band_labels <- function(p, xrange = c(2009.5, 2019.5)) {
  b <- layer_data(p, 1)
  bind_rows(lapply(sort(unique(b$group)), function(g) {
    bb <- b[b$group == g & b$x >= xrange[1] & b$x <= xrange[2], ]
    xs <- sort(unique(bb$x))
    w <- sapply(xs, function(x0) { v <- bb$y[bb$x == x0]; c(diff(range(v)), mean(range(v))) })
    i <- which.max(w[1, ])
    tibble(x = xs[i], y = w[2, i], grp = factor(lv[g], levels = lv))
  }))
}

fmt <- label_comma()
n_events <- nrow(ev)
n_mentions <- nrow(mentions)

# -----------------------------------------------------------------------------
# 5. Figure 2: pooled streams. A = frequency (mirror), B = share (proportional)
# -----------------------------------------------------------------------------
pA <- ggplot(pooled_fine, aes(year, n, fill = grp, colour = grp)) +
  stream_layer("mirror") +
  fill_scale + x_scale +
  scale_y_continuous(labels = function(b) fmt(abs(b)),
                     breaks = seq(-400, 400, 200)) +
  labs(title = "A. Frequency: issue mentions per year",
       subtitle = "Stream width = number of issue mentions in that year",
       x = NULL, y = "Issue mentions") +
  theme_stream + theme(legend.position = "none")

pB0 <- ggplot(pooled_fine, aes(year, n, fill = grp, colour = grp)) + stream_layer("proportional")
labs_B <- band_labels(pB0)
pB <- ggplot(pooled_fine, aes(year, n, fill = grp, colour = grp)) +
  stream_layer("proportional") +
  geom_text(data = labs_B, aes(x, y, label = grp), inherit.aes = FALSE,
            size = 2.5, family = base_family, fontface = "bold", colour = "grey10") +
  fill_scale + x_scale +
  scale_y_continuous(labels = label_percent(accuracy = 1), breaks = seq(0, 1, 0.25),
                     expand = expansion(mult = c(0, 0))) +
  labs(title = "B. Share: each issue's share of all issue mentions in that year",
       x = NULL, y = "Share of issue mentions") +
  theme_stream + theme(legend.position = "none")

# Data-derived facts quoted in the note (computed, not typed in)
other_note <- list(econ_2015 = label_percent(accuracy = 1)(
  with(filter(mentions, year == 2015), mean(issue == "8 - Economy & Welfare"))))
stopifnot(other_note$econ_2015 == "22%")

caption_pooled <- paste0(
  "Note: Austria, Germany, the Netherlands, Poland, Spain and Sweden combined; ", fmt(n_events),
  " events with ", fmt(n_mentions), " issue mentions (each event can raise up to three issues).\n",
  "The five issues are those mentioned most often over 2008–2021; ranking on the first-listed issue ",
  "alone gives the same five. Issue labels as coded in the dataset.\n",
  "The grey band is large in 2015 mainly because of 'Economy & welfare' (", other_note$econ_2015,
  " of that year's mentions) and in 2020\u20132021 because of 'Other' and 'Health'.\n",
  "Streams interpolate the yearly values with a monotone spline and pass through every yearly value.\n",
  "Source: CFP – Comparative Far-Right Protest database, V1-2026 (Castelli Gattinara et al. 2026)."
)

fig2 <- (pA / pB) +
  plot_layout(heights = c(1, 1.1)) +
  plot_annotation(
    title = "Issue focus of far-right protest events in six European countries, 2008–2021",
    caption = caption_pooled,
    theme = theme(
      plot.title = element_text(family = base_family, face = "bold", size = 10.5, margin = margin(b = 6)),
      plot.caption = element_text(family = base_family, size = 6.3, colour = "grey30", hjust = 0,
                                  lineheight = 1.15, margin = margin(t = 6)),
      plot.margin = margin(6, 8, 6, 6)))

save_fig <- function(p, name, w, h, tiff = FALSE) {
  ggsave(file.path(out_dir, paste0(name, ".pdf")), p, width = w, height = h, device = cairo_pdf)
  ggsave(file.path(out_dir, paste0(name, ".png")), p, width = w, height = h, dpi = 600, bg = "white")
  if (tiff) ggsave(file.path(out_dir, paste0(name, ".tiff")), p, width = w, height = h,
                   dpi = 600, bg = "white", compression = "lzw")
}
save_fig(fig2, "fig2_issue_streams_pooled", 6.5, 6.9, tiff = TRUE)

# -----------------------------------------------------------------------------
# 6. Figure 3: share streams by country, each with its yearly event count
# -----------------------------------------------------------------------------
country_panel <- function(cc, title_size = 8.5, legend = FALSE) {
  fine <- filter(by_ctry_fine, country == cc)
  epy  <- filter(events_per_year, country == cc)
  ymax <- max(epy$n)
  s <- ggplot(fine, aes(year, n, fill = grp, colour = grp)) +
    stream_layer("proportional", lw = 0.2) +
    fill_scale + x_scale_ctry +
    scale_y_continuous(labels = label_percent(accuracy = 1), breaks = c(0, 0.5, 1),
                       expand = expansion(mult = c(0, 0))) +
    labs(title = paste0(if (cc == "Netherlands") "The Netherlands" else cc,
                        "  (", fmt(sum(epy$n)), " events)"),
         x = NULL, y = "Share") +
    theme_stream +
    theme(plot.title = element_text(size = title_size, face = "bold"),
          axis.text.x = element_blank(), axis.ticks.x = element_blank(),
          legend.position = if (legend) "bottom" else "none")
  b <- ggplot(epy, aes(year, n)) +
    geom_col(fill = "grey55", width = 0.7) +
    x_scale_ctry +
    scale_y_continuous(breaks = ymax, expand = expansion(mult = c(0, 0.05))) +
    labs(x = NULL, y = "Events") +
    theme_stream +
    theme(panel.grid.major.x = element_blank(),
          panel.grid.major.y = element_line(colour = "grey85", linewidth = 0.25),
          axis.text.y = element_text(size = 6.5),
          legend.position = "none")
  s / b + plot_layout(heights = c(4, 1))
}

panels <- lapply(c("Germany", "Spain", "Sweden", "Poland", "Netherlands", "Austria"),
                 country_panel)  # ordered by number of events

caption_ctry <- paste0(
  "Note: Bands show each issue's share of all issue mentions in a year (each event can raise up to three issues); ",
  "grey bars show the number of\nevents per year. Shares in years with few events (e.g. one event in the Netherlands ",
  "in 2011 and in Poland in 2009) rest on very few cases.\n",
  "The five issues are the most frequent across the six countries combined, so the grey band can be large ",
  "where a country's protests centre on other issues\n(e.g. Poland: civil rights & religion; Spain: other). ",
  "Issue labels as coded in the dataset. Streams pass through every yearly value.\n",
  "Source: CFP – Comparative Far-Right Protest database, V1-2026 (Castelli Gattinara et al. 2026)."
)

legend_src <- ggplot(pooled_fine, aes(year, n, fill = grp)) + stream_layer("proportional") +
  fill_scale + theme_stream +
  guides(fill = guide_legend(nrow = 1, override.aes = list(colour = pal_line, linewidth = 0.3))) +
  theme(legend.text = element_text(size = 6.8), legend.key.size = unit(0.3, "cm"))
legend_grob <- patchwork::wrap_elements(
  full = ggplotGrob(legend_src)$grobs[[which(sapply(ggplotGrob(legend_src)$grobs,
                                                     function(g) g$name) == "guide-box")]])

fig3 <- wrap_plots(panels, ncol = 3) / legend_grob +
  plot_layout(heights = c(1, 0.07)) +
  plot_annotation(
    title = "Issue shares of far-right protest events by country, 2008–2021",
    caption = caption_ctry,
    theme = theme(
      plot.title = element_text(family = base_family, face = "bold", size = 10.5, margin = margin(b = 6)),
      plot.caption = element_text(family = base_family, size = 6.1, colour = "grey30", hjust = 0,
                                  lineheight = 1.15, margin = margin(t = 4)),
      plot.margin = margin(6, 8, 6, 6)))
save_fig(fig3, "fig3_issue_shares_by_country", 6.5, 6.4, tiff = TRUE)

for (cc in focus) {
  p <- country_panel(cc, title_size = 9.5, legend = FALSE) / legend_grob +
    plot_layout(heights = c(4, 1, 0.45)) +
    plot_annotation(caption = paste0(
      "Note: Share of all issue mentions per year; grey bars = events per year. ",
      "Source: CFP database V1-2026 (Castelli Gattinara et al. 2026)."),
      theme = theme(plot.caption = element_text(family = base_family, size = 6.3, colour = "grey30",
                                                hjust = 0), plot.margin = margin(6, 8, 6, 6)))
  save_fig(p, paste0("fig3_", str_to_lower(cc)), 6.5, 3.4)
}

# -----------------------------------------------------------------------------
# 7. Verification: drawn band thickness at each year vs. the true yearly value
# -----------------------------------------------------------------------------
band_at_years <- function(p) {
  b <- layer_data(p, 1)
  bind_rows(lapply(years, function(yy) {
    bind_rows(lapply(sort(unique(b$group)), function(g) {
      bb <- b[b$group == g, ]
      xs <- bb$x[which.min(abs(bb$x - yy))]
      tibble(year = yy, group = g, drawn = diff(range(bb$y[abs(bb$x - xs) < 1e-9])))
    }))
  }))
}
check <- function(cnt, fine, type, label) {
  p <- ggplot(fine, aes(year, n, fill = grp)) + stream_layer(type)
  drawn <- band_at_years(p) |> mutate(grp = factor(lv[group], levels = lv))
  truth <- cnt |> transmute(year, grp, true = if (type == "proportional") share else n)
  inner_join(drawn, truth, by = c("year", "grp")) |>
    mutate(panel = label, type = type, error = drawn - true)
}
qa <- bind_rows(
  check(pooled, pooled_fine, "mirror", "All six countries"),
  check(pooled, pooled_fine, "proportional", "All six countries"),
  lapply(focus, function(cc) check(filter(by_ctry, country == cc),
                                   filter(by_ctry_fine, country == cc), "proportional", cc))
)
write.csv(qa |> select(panel, type, year, issue = grp, true, drawn, error),
          file.path(out_dir, "qa_stream_accuracy.csv"), row.names = FALSE)
qa_sum <- qa |> group_by(panel, type) |>
  summarise(max_abs_error = max(abs(error)), mean_abs_error = mean(abs(error)), .groups = "drop")
print(qa_sum)
stopifnot(with(filter(qa_sum, type == "mirror"), max_abs_error < 0.5),          # < half a mention
          with(filter(qa_sum, type == "proportional"), max_abs_error < 0.015))  # < 1.5 points

writeLines(capture.output(sessionInfo()), file.path(out_dir, "sessionInfo.txt"))
