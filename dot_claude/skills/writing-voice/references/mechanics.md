# Mechanics: Sentence Anatomy, Punctuation, and Diction

All counts measured on prose only (headings, equations, captions, tables, and source
lists excluded) across the two samples: risk-model.md (~4,000 prose words, 243
sentences) and ubi-essay.md (~1,390 prose words, 60 sentences).

## Sentence length

| | technical | persuasive |
|---|---|---|
| mean words | 20.9 | 23.4 |
| median | 18 | 23 |
| 9–25 words | 65% | 63% |
| over 50 words | 2% | 2% |
| maximum observed | 65 | 53 |

Target 15–25; hard stop near 50. The distribution is a tight band, not high variance.
There is no "long sentence then short punch" pattern — that adjacency occurs at chance
frequency (3–6%). The real closing patterns are register-specific (see Paragraphs).

## Clause architecture

**Front-load the adverbial.** 40% of technical and 58% of persuasive sentences open
with an introductory element set off by a comma before the subject arrives. The
working inventory:

- Concessive: "While the phrasing of Yang's plan makes a UBI appear attractive, it
  ignores the issue of fiscal costs."
- Purpose/scope: "To maintain consistency in model application, winsorization
  breakpoints are determined exclusively within the estimation universe."
- Conditional: "If return observations are sparse, the beta estimate will be shrunk
  towards the median industry beta."
- Attribution (persuasive): "According to the Tax Foundation, Yang's proposal would
  cost around $2.8 trillion."
- Single-word connective: Unfortunately · Additionally · Hence · Therefore · Namely.

Reserve subject-first openings for sentences whose subject is the news. Back-load only
the verdict-tail (persuasive closers) and the "Where..." gloss.

**Link sentences with demonstratives, not conjunctive adverbs.** The next sentence
opens with This / These / Such pointing at the last one, and almost always with a
summarizing noun attached: "This assessment, however, is highly speculative...",
"These binary indicators introduce another problem...", "Such proposals, commonly
referred to as...". Bare "This means that..." is allowed about twice per document, as
decompression. Moreover / Furthermore / Nevertheless / Nonetheless: zero occurrences
in 8,190 words. "However" appears ~5 times total; in argument it sits inside the
sentence, comma-flanked, never at the front.

## Punctuation

Per 1,000 prose words:

| mark | technical | persuasive |
|---|---|---|
| parentheses | 9.0 | 2.9 |
| colon | 6.7 | 1.4 |
| italics | 5.7 | 1.4 |
| em-dash | 0.7 | 2.9 |
| semicolon | 0.0 | 0.7 |
| question mark | 0.5 | 0 |
| exclamation | 0.2 | 0 |

- **Parentheses are the aside device**, outnumbering em-dashes 12:1 in technical prose.
  Their job is translation — restate a term in the other vocabulary immediately:
  "(a very simple factor model)", "(also called *sensitivity*)", "(i.e., the return
  streams associated with each factor exposure)", "(either a one or zero)", "(or
  idiosyncratic returns)", "(by nature of being universal)". In argument a parenthesis
  may smuggle in the sharper word: "a bold (or reckless) course of action."
- **Em-dashes: unspaced, two licensed forms, ~1 per 1,000 words ceiling.**
  1. The `—namely` pivot: "...introduce another problem into our regression
     model—namely that these industry and region exposures violate two key assumptions."
  2. A paired appositive wedged between subject and verb, attaching a credential or
     sponsor: "The experiment—sponsored by Kela, the Social Insurance Institution of
     Finland—was designed to observe whether..."
  Never a single spaced em-dash for a dramatic pause. (Spaced ` — ` asides are the #1
  LLM tell; Jacob does not produce them.)
- **Semicolons: one per document at most.** Exactly one exists in both samples
  combined, hinging a concession. Default to a period.
- **Colons announce; they don't decorate.** A colon or an explicit announcement ("as
  follows:", "is given by:") introduces every display equation and inline enumeration;
  no equation is ever dropped in unannounced. Inline enumerations use `1) ... 2) ...`
  numbering inside the sentence when items are short, closed by "respectively" when
  paired values follow.
- **Bold: zero occurrences in the samples — as prose emphasis, don't use it.** Italics
  carry emphasis. This is not a ban on technical notation: the samples contain no
  programming content, so they measure prose habits only. When writing about code or
  systems, render identifiers in code font exactly as the system spells them —
  `TABLE_1`, `semaphore()`, `SELECT`, file paths, env vars — and use bold, LaTeX math,
  or other markup where the material genuinely warrants it. A term in code font does
  not also get the italics-on-first-use treatment; the code font already marks it.

## Licensed fragments

Two shapes, always trailing a complete sentence:

1. The `Where` gloss after a display equation — one paragraph, unpacking each symbol
   in order of appearance: "Where $D_{i,t}$ and $P_{i,t}$ are the per-share dividend
   and price of stock $i$ on day $t$." The first equation introducing a symbol glosses
   it; chained equations inherit.
2. The `Namely, that` amplifier: "Namely, that recipients of basic income are likely
   to feel a better sense of economic security."

## Italics: two jobs

1. A technical term, once, at its definition — packaged as italics + defining
   appositive + acronym in one clause: "a robust estimator of standard deviation
   called cross-sectional *median absolute deviation from the median* (MAD)"; "our
   model employs a *volatility regime adjustment* (VRA)". Other framing verbs:
   "referred to as," "also known as," "also called," "a statistical property called,"
   scare-quoted "so-called" for jargon he's distancing from.
2. The pivot word of a contrast — usually a negation, absolute, or paired opposition:
   "active managers *aren't* perfect forecasters"; "variation that is *common* ...
   and variation that is *stock-specific*"; "in the *cross section* rather than in
   the *time series*"; "economic policies *always* have tradeoffs". About one per 700
   words; never a whole clause.

## Paragraph shape

- Median two sentences; a third of the paper's paragraphs are a single sentence;
  nothing over ~120 words. If a paragraph reaches four sentences, look for the seam.
- **Technical close: the scope declaration.** Long definitional sentence, then a 4–6
  word scope sentence — "Momentum exposures are standardized globally." The short
  sentence declares scope; it is not a rhetorical punch. Do not reach for a punchy
  closer in technical prose.
- **Persuasive close: the verdict rides the tail.** Closing sentences run *longer*
  than openers (28 vs 24 words), with judgment arriving after a comma as an appositive
  or subordinate tail: "...a bold (or reckless) course of action considering a UBI's
  negligible effect on individual employment and its inability to efficiently target
  financial relief to the most impoverished."
- **Rulings.** Genuinely short sentences (4–9 words) are reserved for verdicts, at
  most three per essay: "This is arguably false." / "Such a proposal would likely
  never be budget neutral." / "True universal programs are few and far between."

## Signature lexicon (reach for these)

- `—namely,` — the house move: assert a problem exists, then em-dash into its
  specification.
- `For our purposes,` / `For the purposes of this [document],` — marks a parameter
  choice as local and pragmatic rather than principled.
- Demonstrative + summarizing noun as subject: "This aspect of financial market
  structure introduces...", "This explanatory power is the primary objective...".
- Reader-direction imperatives: `Recall that...`, `Note that...`, `Notice that...`,
  `Assume that...` (the hypothesis-setting verb), `Let X denote...` (notation setup).
- `respectively` closing paired enumerations: "breakpoints at 21 and 220 observations,
  respectively."
- `Upon visual inspection,` when reading a figure (sparingly — it pairs badly with
  "we can see"; use one or the other).
- `constitute` for *amounts to*; `merely` as the deflationary adverb, once per
  document, on the sentence that punctures something.
- Summary transitions: In summary · In practice · In other words · In this case ·
  In this setting · In theory · It turns out that. (Each only where literally true —
  "In summary" may only precede an actual summary.)
- Quant idiom worth keeping: "greater than 99%"-style comparatives for thresholds,
  spelled-out operators in prose ("at 30 or fewer observations", not "at <=30").

## Verbs: Latinate frame, Anglo-Saxon body

Framing/topic sentences may be nominal and Latinate: "Factor model construction
involves the computation of a time series of daily factor returns." Explanatory and
decompression sentences flip to physical, spatial verbs — mathematical operations get
spatial metaphors: shrunk *towards*, blended *towards*, layered *on*, focused
*through*, split *into*, broken *into*, immunized *from*, insulated *from*, brought
*closer to*, pitted *against*, dethrone, plagued by, nested in. If a decompression
sentence has a nominalization in it, rewrite it.

## Hedging and intensity

- Hedge with verbs and evidence: tends to · appears to · is likely · might · may ·
  it is reasonable to expect · suggests · arguably · have been suggested to (with the
  citation attached: "Values higher than 5 have been suggested to show high
  collinearity (Sheather)").
- Size the doubt instead of softening the verb: "highly speculative with a large
  margin of error"; "if existing evidence is any indicator."
- Never hedge a parameter or design choice: "we augment the factor correlation matrix
  using J = 1 principal components and a shrinkage weight w = 0.3" — flat, no
  justification theatre.
- Intensifiers are nearly absent: one "very" in 8,200 words. The -ly adverb inventory
  is technical (daily, weekly, globally, locally, exponentially, linearly,
  exclusively, respectively), not amplifying. No extremely, incredibly, hugely,
  massively, really, quite, fundamentally, notably.

## Crutches to ration (in the samples; don't imitate the frequency)

- `we can` — 15 uses in one paper, the top collocate. Cap at 3–4 per document; make
  the rest flat indicative ("The model then...", "This gives...", "Equation (34)
  yields...").
- `illustrate` — 11 uses, semantically overstretched. Figures *show* or *give*;
  people *explain* or *argue*; sections *outline*. Figures never "explore."
- Equation-introduction boilerplate — `as follows` (8), `is given by` (6), `the
  following [noun]` (12). Fine as a strict template inside a reference section;
  rotate elsewhere. Never "follows the following."
- Sentence-initial `Additionally` (6) — replace with the actual relation or fold the
  sentence in; never "Additionally... also."
- `robust`, `adjustment`, `significant`, `important`, `unique`, `relief` — each
  drifts into filler on repetition; `unique` appears in four different senses in one
  paper. If `significant` isn't statistical, quantify or cut.
- `According to X,` — vary the attribution frame; don't open four paragraphs with it.
- `denote` misused for *refer to* / *call for*; `treated` as bare jargon — give it an
  object ("treated for outliers").

## Quotation mechanics (persuasive register)

Credential the source in an appositive, then quote at length: name + role +
institution, comma-set, then a 25–45 word quotation, never trimmed to a phrase.
Elide with a bare ellipsis (…), no brackets. Split a long quote with interior
attribution: `"The UBI," he states, "does not resolve the fundamental trade-offs…"`.
Never anonymous attribution ("researchers say," "critics argue" without names).
