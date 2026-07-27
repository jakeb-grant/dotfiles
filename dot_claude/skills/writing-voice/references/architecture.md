# Architecture: Document Shapes, Figures, and Persuasion

Extracted from the two samples. Setup-to-payload ratios: the technical paper spends
9% of its words before the first body section, with no roadmap; the persuasive essay
spends 18%, with an explicit five-item roadmap. The two shapes below are reusable
skeletons — port the shape, not the subject matter.

## Shape A: the technical explainer

```
TITLE — plain noun phrase, no subtitle

INTRODUCTION  [~8–10% of total]
  One field-trajectory sentence (where this class of method came from, where it
  arrived), one sentence on what it buys you.
  The problem — first principles, no citations. Quantify the pain with a real,
  computed number. The document's one exclamation point may live here.
  The approach — intuition in one plain sentence → minimal formalism → the same
  number, transformed (44,850 → 601).
  Close on a conditional whose antecedent the body will discharge: "If we can
  specify a reasonable factor model such that..., we should be able to reduce the
  dimensionality." That conditional IS the roadmap. No abstract, no literature
  review, no roadmap list.

BODY — one H2 per pipeline stage, ordered by the order the thing is actually built,
  each stage a precondition of the next. Every section opens with a handoff
  (While / Once / Recall + the previous section's conclusion).

  Within a stage:
  - Problem subsections run the four-beat (rationed decompression).
  - Catalog subsections run the strict repeated template: [Term] is defined as
    [complete one-sentence definition]. [Scope sentence]. → equation → "Where..."
    gloss → edge case. Identical rhythm per entry, no motivation beats.
  - Validation gets its own named subsection AFTER construction: restate the purpose
    → formula → announce figure → cite external threshold → read the data → small
    verdict ("acceptable," "a strong match"). Build, then audit; never interleaved.
  - Set acceptance criteria as a numbered list early; discharge each in a later
    subsection that opens by recalling it.
  - Defer explicitly by name: put the parameter table where the reader needs it and
    say where its justification lives ("discussed later in this section" — once,
    not twice in two sentences). Plant curiosity: "(more on the intercept later, as
    it has unique economic significance)."

APPENDIX: TOPIC — formalism-first, motivation-free. Every derivation that would
  interrupt the teaching line goes here. The appendix is what keeps the body simple.

Headings: H2 ALL CAPS, bare 1–3 word noun phrases, no articles. H3 Title Case, often
"X and Y" compounds. H4 = catalog item names. Never numbered — equation numbers are
the cross-reference spine ("defined in equation (33)"). Reserve the "HEADING:
subtitle" colon form for special-status sections (appendix, conclusion).

Citations: bare surnames, no dates ("as proposed in Vasicek", "(Sheather)") — pointers
to a shared canon that license design choices; they never carry the argument.
Footnotes carry data provenance, caveats, self-corrections, and helper links (a
Wikipedia link is fine if it's the fastest way to help the reader).
```

## Shape B: the persuasive essay

```
TITLE: A Question?    (byline)

OPENING  [~18% of total, no heading]
  1. Sourced striking statistic — the fact that proves the topic is live.
  2. Name and abbreviate the thing: "commonly referred to as X (ABBR)".
  3. Second independent proof of topicality, often a figure (gloss its scale for a
     general reader: "Values of 100 indicate peak search interest").
  4. The stakes as a question: "The difficult question for [audience] is whether..."
  5. The TWO-CAMPS SENTENCE: "Detractors believe A and B, while proponents insist
     C." Symmetric verbs for the two camps. This sentence generates the roadmap.
  6. Roadmap: a phrase naming the piece's job in about six words, then the camps'
     claims restated as things to be tested, enumerated.
  7. One line on why the reader must understand these.
  NO thesis — the reader must not be able to tell your position yet.

BODY — each H2 restates its roadmap item verbatim, in order. Headings may carry the
  verdict where the evidence is strong ("THE MYTH OF..."). Each section:
  - Opens with a handoff: "Though/Despite [last section's finding], [this claim]."
  - Voices the opposing view colloquially, after a colon: "One common criticism is
    this: if you give people a bunch of undeserved money..."
  - Attributes every claim: Name, role at institution, verb, quote at length.
  - Lets one honest number carry the section, stated without adjectives.
  - Announces figure → figure → reads the numbers in words → implication.
  - Closes on a calibrated mini-verdict, usually concede-and-reclaim: "While the
    study shows X, it also illustrates Y." Strongest variant: a real actor's
    decision as the verdict ("For this reason, Finland has decided to forgo...").
  Sections roughly even in length — except the section with the thinnest evidence
  is the SHORTEST. Never pad a weak section; brevity there is an honest signal.
  Pull quotes (≤2 per piece) restate your own adjacent sentence, verbatim, at a
  section's center of gravity.

CONCLUSION — the only asserting heading in the piece, "WRAPPING UP: [THESIS AS A
  CLAUSE]" form, not a roadmap item. Then the three-rung ladder, each rung plainer
  and broader than the last:
  1. Measured: "In summary, ... fail to demonstrate that ..."
  2. Quotable at dinner: one sentence a non-specialist could repeat.
  3. Generalizes past the topic: the transferable principle the reader keeps.
  Then a direct instruction asking for the reader's independent judgment ("Please
  use this understanding to evaluate the claims of..."), and a final sentence that
  ECHOES the title's words without answering the question — the verdict landed at
  rung 1–2; the close hands the final call to future evidence.

Citations: numbered endnotes plus a full Sources list.
```

## Figures, tables, and data

- **Every figure is announced in prose before it appears** — `Figure N + verb`
  (illustrates, shows, gives, is reported in). Never a bare figure, never "(see
  Fig. 1)". 14 of 14 figures in the samples follow this.
- **The reading may sit before or after the figure** — both are in voice. Before,
  when the figure confirms a point being made; after, when the figure is evidence
  the reader must see first. What is never optional: the figure gets read.
- **A claim-supporting figure gets a verdict benchmarked externally**, in three
  sentences: cite the published threshold → read the data → state the conclusion.
  "Values higher than 5 have been suggested to show high collinearity (Sheather).
  One can see that all the values stay below 4... These results indicate that there
  is little multicollinearity." Verdicts stay small: "acceptable," "a strong match."
  Pure context figures need only a description.
- **The prose must survive the figures being deleted.** Every load-bearing number
  appears in a sentence. If a number exists only inside an image, it isn't in the
  argument yet. But state each number's meaning once — don't repeat caption numbers
  in the body verbatim a second time without adding interpretation.
- **Tables are lookups, not evidence.** Announce a parameter table and move on; never
  read tables back in prose the way figures are read.
- **Gloss the scale on first use** for a general reader.
- If the piece has a key metaphor (an "Iron Triangle"), it must be named in the
  prose, not only in a figure caption.

## Ethos in depth

- **Self-limitation first.** Name the product's own failure mode in body text, in
  your own words, before anyone else can. ("Because risk models utilize historical
  data..., they have the potential to underestimate risk in periods of rising
  volatility.") The UBI essay undercuts its own evidence base: "proponents and
  detractors are both plagued by the lack of data available."
- **Understatement on results**, always: "appear acceptable," "a strong match," "One
  can see that all the values stay below 4." Never triumphant.
- **Flat on construction, hedged on interpretation.** Parameters and design choices
  are stated without justification theatre. Claims about the world get calibrated,
  sourced hedges.
- **The rejected standard practice gets its due:** "the common solution is to omit
  one of the dummy variable categories... However, this also drops one of our
  factor columns, which compromises our economic analysis." Why the normal answer
  is normally right, then its specific cost here.
- **Footnotes serve the sharp reader so the body serves the learner.** Three jobs:
  pre-empt the expert's objection, record provenance, link outward generously.
  Never footnote for prestige. (But never let a footnote concede an error the text
  should just fix — that's a correction, not a caveat.)
- **Gloss what the audience probably knows, in a parenthetical** — "(a very simple
  factor model)" written for professionals. Never "as you know"; never "obviously"
  about a concept. The plain-English version sits alongside the formalism, never
  in place of it.
- **Restate, never repeat.** After a claim that took more than a clause to build,
  re-say it shorter ("In other words...", "Simply put..." — in your own fresh
  phrasing). A restatement longer than the original is a defect.
- **Opponents:** no one has bad motives. The named opponent's strongest numbers are
  quoted verbatim and at length, then answered on arithmetic alone. Detractors
  "believe"; proponents "insist" — symmetric verbs, symmetric respect.
- **Direct appeals ask for independence, not agreement** — equip the reader to judge
  all claims, including this piece's.
- **Emotional register:** feeling attaches to genuine difficulty ("Unfortunately," at
  most once per piece, at the point of real obstruction) and to the people at stake
  ("those who desperately need it") — never to your own results, never to opponents.
- **Evidence is never spent twice in opposite directions.** If a finding was used as
  a concession to the other side, it cannot later be re-cited as ammunition against
  them. Track what each source has been used to show.
- **"This is because" and "For this reason" must be earned** — the cited source must
  actually assert the causal link, or the computation must show it. Never attach
  your own causal story to someone else's conclusion.
