# Patana (2022): article and Appendix in Markdown

Source: `Combined_Residential Constraints and the Political Geography of the Populist Radical Right_Evidence from France.pdf` in https://github.com/jingyao2025/references (repository root, commit `cee6ef8`, pulled 2026-10-19). It is one 24-page PDF in two parts:

| PDF pages | Content |
|---|---|
| 1–18 | Pauliina Patana, "Residential Constraints and the Political Geography of the Populist Radical Right: Evidence from France", *Perspectives on Politics* 20(3), September 2022, pp. 842–859, DOI 10.1017/S153759272100219X (Cambridge University Press, open access) |
| 19–24 | "Appendix" (supplementary material, no printed page numbers): A. Descriptive Statistics; B. Robustness of Results to Different Model Specifications; C. Qualitative Research |

## Files

| File | What it is |
|---|---|
| `patana-2022-residential-constraints.md` | **Main deliverable**: the whole PDF in reading order, with the article followed by the Appendix. |
| `patana-2022-residential-constraints-article.md` | The article on its own. |
| `patana-2022-residential-constraints-supplement.md` | The Appendix on its own. |
| `figures/` | Figures 1 and 2, cropped from the pages. |
| `_logs/` | The conversion log and three review logs (article PDF pp. 1–9 and 10–18; Appendix pp. 19–24). `_logs/parts/` holds the reviewed fragments. |
| `_tools/` | The scripts and review briefs used. |

## Contents at a glance

| | Article | Appendix |
|---|---|---|
| Sections | Abstract; 7 main sections with 6 subsections; Supplementary Materials; Acknowledgement; Notes; References | A. Descriptive Statistics; B. Robustness (Tables B1–B4); C. Qualitative Research (C1 Descriptive Statistics, C2 Qualitative Interview Protocol, 14 questions) |
| Tables | 2 | 6 (A descriptives, B1–B4, C1) |
| Figures | 2 | none |
| Notes | 55 endnotes, under the printed "Notes" heading | none |
| References | 80 | none |

## Conventions
- **YAML front matter**: only facts printed in the PDF (article p. 1).
- **Page markers**: `<!-- page N (printed p. X) -->` use the page numbers of the whole 24-page PDF; Appendix pages print no folio and are marked `<!-- page N -->`.
- **Abstract heading**: the abstract prints no heading; `## Abstract` was added (the only added heading).
- **Endnotes**: markers `[^n]` with the printed numbers, sitting where the superscripts stand. The definitions are in the `## Notes` section where the article prints its notes.
- **Tables**: every cell is checked against the page. Standard errors stay on their own rows, and significance stars are escaped (`\*\*\*`).
- **Interviews**: interview exchanges are block quotes, as printed.
- **Removed**: running heads and feet ("Article | Political Geography and the Radical Right", "Perspectives on Politics", "September 2022 | Vol. 20/No. 3") and page numbers.
- **Typos**: printed typos are kept as printed and listed in the logs.
