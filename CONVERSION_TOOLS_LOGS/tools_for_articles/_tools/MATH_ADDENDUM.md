# Math addendum (read after /home/claude/pipeline/AGENT_BRIEF.md)

This document is a quantitative-methods paper. Its mathematics is the highest-risk content.

1. **Every** formula — display equations, inline math, theorem/assumption statements, matrices, estimators,
   notation in table/figure captions — must be written in LaTeX (`$…$` inline, `$$…$$` display) and must
   reproduce the printed formula EXACTLY: every symbol, sub/superscript, accent (hat, tilde, bar), bold,
   blackboard (𝔼 → `\mathbb{E}`), calligraphic, brackets, primes, indices, summation limits, conditioning bars,
   indicator functions, operators. Do not "simplify", "complete" or "fix" a formula; if the print has an
   apparent typo, reproduce it and note it in the log.
2. The text layer is unreliable for math (`(cid:N)` glyphs, split sub/superscripts like "Xi t", missing symbols).
   Read each formula from the page image at 200–300 dpi (render.sh or crop.sh), and use words.py to confirm
   characters where the text layer has them.
3. **Visual verification is mandatory for every display equation and every non-trivial inline formula**:
   write the LaTeX to a file and run `/home/claude/pipeline/eqcheck.sh <file> <out.png>`, then view both the
   rendered PNG and the PDF crop and compare symbol by symbol. Fix and re-render until they match. Record in
   your log the count of equations checked this way.
4. Keep printed equation numbers with `\tag{n}` inside the display math (e.g. `$$ … \tag{3} $$`).
   Multi-line displays: `$$\begin{aligned} … \end{aligned}$$`.
5. Theorems, Assumptions, Definitions, Propositions, Proofs: keep their printed labels in bold/italic as printed
   (e.g. `**Assumption 1 (No Spillover Effect).** text…`), as separate paragraphs; proofs ending in a printed
   □/∎ keep it.
6. Algorithm boxes / numbered step lists: Markdown ordered lists, with exact wording.
7. Prose words remain from the text layer (do not retype prose from images), except confirmed text-layer
   errors.
8. Verification numbers from verify.py will be lower than usual because the PDF text layer represents math
   as fragments; explain this in the log, but make sure ALL prose is present (check long missing runs of
   ordinary words).
