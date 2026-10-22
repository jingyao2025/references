# References — PDF → Markdown conversions

Source repository: https://github.com/jingyao2025/references (commit `93c8acd`, cloned 2026-10-08).
Every PDF in `articles/` (24 files → 21 unique works) and `books/` (2 books) was converted to Markdown.

## Contents

```
articles/                 21 article/chapter files (+ figures/ with 53 cropped figure images)
books/
  sondel-cedarmas-berti-2022-the-right-wing-critique-of-europe/
      <slug>.md           complete book in one file (front matter at end, index omitted)
      chapters/           the same text split per part/chapter (27 files)
      figures/            2 figures
  green-pedersen-2019-the-reshaping-of-west-european-party-politics/
      <slug>.md           complete book in one file
      chapters/           14 files (Preface, Chapters 1–12, References)
      figures/            35 figures
_logs/                    one review log per article and per book chunk (removals, glyph fixes, issues)
_tools/                   the extraction / verification scripts and the review briefs used
CONVERSION_LOG.md         method, troubleshooting, issues and decisions
```

## Markdown conventions

- **YAML front matter**: bibliographic fields taken only from what is printed in the PDF (title, authors, journal, year, volume, issue, pages, DOI, publisher, the verbatim "To cite this article" line where one is printed, source file).
- `#` title once; `##` sections (in books: Parts, Chapters, Preface, Introduction, References); `###`/`####` subsections. Original numbering and wording of headings kept.
- **Page markers**: `<!-- page N (printed p. X) -->` before the content of every PDF page (N = PDF page, X = printed folio), inline where a paragraph runs across pages — so quotations can be cited by page.
- **Notes**: `[^n]` markers at the exact position of the superscript, definitions `[^n]: …` under the original Notes heading (books: `[^ch3-12]` = chapter 3, note 12).
- **Tables**: GitHub pipe tables (HTML `<table>` only where unavoidable); caption above as `**Table N.** …`, notes verbatim below. Spanning headers flattened ("Model 1: Coef.").
- **Figures**: cropped from the page as PNG and embedded (`![Figure N](figures/…)`), followed by the verbatim caption and notes. No descriptions were invented.
- Equations in LaTeX; italics/bold as printed; diacritics, minus signs, dashes and Greek letters preserved.
- References: one entry per paragraph, complete, line-break hyphens and broken URLs/DOIs repaired.
- Removed as non-content (all logged): running heads/feet, page numbers, download/licence watermarks (JSTOR, Wiley, EBSCO, OUP, APA), publisher download cover sheets (their facts moved to YAML), cover page, blank pages, the Index (Sondel-Cedarmas & Berti), web-print link labels ("Google Scholar", "WorldCat", …), chart tick/axis labels that leaked into prose.
- Authors' own typos are kept exactly as printed (not corrected).

## Articles

| File | Source PDF | PDF pages | Tables | Figures | Notes | Ref. entries* | Recall | Precision |
|---|---|---|---|---|---|---|---|---|
| [brader-tucker-2012-following-the-partys-lead](articles/brader-tucker-2012-following-the-partys-lead.md) | `Brader-FollowingPartysLead-2012.pdf` | 19 | 3 | 0 | 50 | 0 | 0.9648 | 0.9894 |
| [hooghe-marks-2018-cleavage-theory-meets-europes-crises](articles/hooghe-marks-2018-cleavage-theory-meets-europes-crises.md) | `Cleavage theory meets Europe s crises  Lipset  Rokkan  and the transnational cleavage.pdf` | 29 | 1 | 4 | 15 | 109 | 0.9885 | 0.9976 |
| [spoon-kluver-2014-do-parties-respond](articles/spoon-kluver-2014-do-parties-respond.md) | `Do parties respond_How electoral context influences party.pdf` | 13 | 6 | 2 | 8 | 65 | 0.9951 | 0.9878 |
| [green-pedersen-mortensen-2010-who-sets-the-agenda](articles/green-pedersen-mortensen-2010-who-sets-the-agenda.md) | `European J Political Res - 2010 - GREEN‐PEDERSEN - Who sets the agenda and who responds to it in the Danish parliament  A.pdf` | 25 | 6 | 1 | 15 | 53 | 0.9830 | 0.9780 |
| [hobolt-spoon-2012-motivating-the-european-voter](articles/hobolt-spoon-2012-motivating-the-european-voter.md) | `European J Political Res - 2012 - HOBOLT - Motivating the European voter  Parties  issues and campaigns in European.pdf` | 27 | 8 | 3 | 14 | 62 | 0.9831 | 0.9955 |
| [spoon-kluver-2015-voter-polarisation-and-party-responsiveness](articles/spoon-kluver-2015-voter-polarisation-and-party-responsiveness.md) | `European J Political Res - 2015 - Spoon - Voter polarisation and party responsiveness  Why parties emphasise divided issues.pdf` | 20 | 5 | 2 | 10 | 81 | 0.9922 | 0.9977 |
| [hobolt-tilley-2016-fleeing-the-centre](articles/hobolt-tilley-2016-fleeing-the-centre.md) | `Fleeing the centre  the rise of challenger parties in the aftermath of the euro crisis.pdf` | 22 | 4 | 3 | 13 | 52 | 0.9724 | 0.9961 |
| [green-pedersen-odmalm-2008-going-different-ways](articles/green-pedersen-odmalm-2008-going-different-ways.md) | `Going different ways  Right-wing parties and the immigrant issue in Denmark and Sweden.pdf` | 16 | 0 | 0 | 6 | 40 | 0.9796 | 0.9960 |
| [belanger-meguid-2008-issue-salience-issue-ownership](articles/belanger-meguid-2008-issue-salience-issue-ownership.md) | `Issue salience, issue ownership, and issue-based vote choice.pdf` | 15 | 5 | 0 | 31 | 62 | 0.9878 | 0.9785 |
| [coffe-et-al-2023-parties-issues-and-gender](articles/coffe-et-al-2023-parties-issues-and-gender.md) | `Parties_Issues_and_gender_Ch27_Coffe_et_al_2023.pdf` | 11 | 0 | 2 | 1 | 84 | 0.9980 | 0.9975 |
| [grande-schwarzbozl-fatke-2019-politicizing-immigration](articles/grande-schwarzbozl-fatke-2019-politicizing-immigration.md) | `Politicizing immigration in Western Europe.pdf` | 21 | 1 | 4 | 9 | 41 | 0.9850 | 0.9981 |
| [kluver-sagarzazu-2016-setting-the-agenda-or-responding-to-voters](articles/kluver-sagarzazu-2016-setting-the-agenda-or-responding-to-voters.md) | `Setting the Agenda or Responding to Voters  Political Parties  Voters and Issue Attention.pdf` | 20 | 2 | 2 | 1 | 42 | 0.9685 | 0.9950 |
| [feinberg-willer-kovacheff-2020-the-activist-dilemma](articles/feinberg-willer-kovacheff-2020-the-activist-dilemma.md) | `The_activist_dilemma.pdf` | 26 | 7 | 8 | 16 | 103 | 0.9869 | 0.9926 |
| [ivanusch-2025-where-do-parties-talk-about-what](articles/ivanusch-2025-where-do-parties-talk-about-what.md) | `Where do parties talk about what  Party issue salience across communication channels.pdf` | 28 | 3 | 3 | 14 | 55 | 0.9874 | 0.9992 |
| [schumacher-giger-2017-who-leads-the-party](articles/schumacher-giger-2017-who-leads-the-party.md) | `Who Leads the Party_On.pdf` | 21 | 5 | 4 | 10 | 82 | 0.9755 | 0.9966 |
| [edwards-arnon-2024-contentious-politics-in-the-borderlands](articles/edwards-arnon-2024-contentious-politics-in-the-borderlands.md) | `edwards-arnon-2024-contentious-politics-in-the-borderlands-how-nonviolence-and-migrant-characteristics-affect-public.pdf` | 18 | 2 | 7 | 18 | 60 | 0.9929 | 0.9933 |
| [green-pedersen-2007-the-growing-importance-of-issue-competition](articles/green-pedersen-2007-the-growing-importance-of-issue-competition.md) | `green-pedersen-2007-the-growing-importance-of-issue-competition-the-changing-nat.pdf` | 22 | 14 | 0 | 16 | 60 | 0.9958 | 0.9931 |
| [green-pedersen-mortensen-2015-avoidance-and-engagement](articles/green-pedersen-mortensen-2015-avoidance-and-engagement.md) | `green-pedersen-mortensen-2014-avoidance-and-engagement-issue-competition-in-multiparty-systems.pdf` | 18 | 6 | 1 | 17 | 35 | 0.9873 | 0.9766 |
| [hobolt-de-vries-2015-issue-entrepreneurship](articles/hobolt-de-vries-2015-issue-entrepreneurship.md) | `hobolt-de-vries-2015-issue-entrepreneurship-and-multiparty-competition.pdf` | 27 | 2 | 1 | 12 | 59 | 0.9948 | 0.9974 |
| [meguid-et-al-2025-strategic-inclusion-without-transformation](articles/meguid-et-al-2025-strategic-inclusion-without-transformation.md) | `meguid-et-al-2025-strategic-inclusion-without-transformation-how-populist-radical-right-parties-engage-with-women-s.pdf` | 41 | 3 | 3 | 13 | 159 | 0.9871 | 0.9900 |
| [seeberg-2023-avoidance-and-engagement-societal-problems](articles/seeberg-2023-avoidance-and-engagement-societal-problems.md) | `seeberg-2021-avoidance-and-engagement-do-societal-problems-fuel-political-parties-issue-attention.pdf` | 11 | 1 | 3 | 3 | 43 | 0.9956 | 0.9931 |

*Paragraph count in the References section (may include sub-lists such as election-study lists; Brader & Tucker cite in notes only).

**Recall / precision** = share of the PDF's own text-layer words (pdftotext) found in the Markdown, and share of Markdown words found in the PDF (bag-of-words, running heads excluded). Values below 1.0 are explained, document by document, in `_logs/`: deliberately removed cover sheets and chart-axis labels, table cells re-ordered row-wise, superscripts/subscripts and note labels split by markup, hyphenation differences, broken font encodings in the PDF text layer that were corrected from the page images, and (Brader & Tucker) OCR errors in a scanned JSTOR text layer that were corrected from the page images. No unexplained missing passages remain.

## Books

| Book | Pages converted | Chapters | Tables | Figures | Notes | Recall | Precision |
|---|---|---|---|---|---|---|---|
| Sondel-Cedarmas & Berti (eds.) 2022, *The Right-Wing Critique of Europe* (Routledge) | PDF 2–273 (main text = printed 1–260; Index pp. 261–278 omitted) | Introduction + 17 chapters in 4 Parts | 16 | 2 | 700 | 0.9938 | 0.9799 |
| Green-Pedersen 2019, *The Reshaping of West European Party Politics* (OUP) | PDF 1–213 (all) | Preface + 12 chapters + References (299 entries) | 29 | 35 | 122 | 0.9713 | 0.9909 |

Book precision is lowered mainly by the chapter-prefixed note labels; Reshaping recall by the removed web-print labels ("Google Scholar"/"WorldCat" ≈ 290 rows) and ~1,000 chart-label tokens now inside the figure images.

## Duplicates in the repository (not converted twice)

- `articles/seeberg-2021-…-fuel-political-partie.pdf` is byte-identical (MD5) to `…-fuel-political-parties-issue-attention.pdf` → one file: `seeberg-2023-avoidance-and-engagement-societal-problems.md` (the article is Party Politics 29(2), 2023).
- `articles/European J Political Res - 2015 - Spoon … (1).pdf` has identical text to the copy without "(1)" (files differ by 3 bytes of metadata) → `spoon-kluver-2015-…md`.
- `articles/Do parties respond___.pdf` is an image-only "Microsoft Print to PDF" scan of the same article as `Do parties respond_How electoral context influences party.pdf` (Spoon & Klüver 2014). OCR of all 13 scanned pages matched the text-layer version (97% word overlap; differences are OCR noise) → converted once from the text-layer PDF.
- `The reshaping of WE party politics….pdf` in the repository root is byte-identical to the copy in `books/`.

See `CONVERSION_LOG.md` for the method, troubleshooting and known limitations.
