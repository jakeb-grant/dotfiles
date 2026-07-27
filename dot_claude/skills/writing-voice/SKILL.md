---
name: writing-skill
description: Write and revise prose in Jacob's voice — simple, elegant, teaching-first analytical writing, scaled by length from Slack messages to full papers. Use for papers, docs, memos, client letters, emails, blog posts, and any prose Jacob publishes under his own name; also for revising or critiquing a draft Jacob wrote.
---

# Writing in Jacob's Voice

> This file uses bullets and bold lead-ins for fast lookup. That is NOT the target
> output style. Jacob's prose contains zero bold in 8,190 words and about a dozen
> bulleted lines per 6,000 words. Do not let this file's format bleed into the draft.

Jacob writes analytical prose that teaches. The reader is assumed competent but never
assumed informed; every piece is the fastest honest path to understanding, with
personality rationed carefully enough to land. Every rule below was measured against
two of his published documents (a 6,256-word technical paper and a 1,934-word policy
essay); the counts are real, not vibes.

Reference files — load when the task needs them:

- `references/voice.md` — annotated excerpts, one reusable move each. Enough for most work.
- `references/mechanics.md` — sentence anatomy, punctuation, diction, crutches.
- `references/architecture.md` — full document shapes, figure handling, ethos, persuasion.
- `references/corrections.md` — the complete mechanical-corrections catalog.
- `references/samples/` — the two verbatim source documents. Read one only when you need
  to see a full-length piece's shape.

**Imitate the moves, never the wording.** The quoted lines in the reference files are
evidence, not templates. Never emit these strings or close variants: "So what just
happened?", "The villain in this case", "might seem a little strange", "In
non-<field> terms", "Simply put,", "To separate fact from fiction", "a bold (or
reckless)", "Effective or Overkill", "elegant solution that can be easily programmed".
Each was minted once for one moment. Reproduce the move — voice the reader's confusion,
personify the obstacle, translate the math back — in words that belong to this piece.
If a sentence could be found by string-search in the samples, rewrite it.

## Correctness outranks voice, always

No stylistic rule in this document licenses a claim you cannot support.

- **Every number is computed in front of the reader or attributed.** Jacob's 44,850 is
  derived from (N²−N)/2; his $2.8 trillion is sourced to the Tax Foundation. Never
  invent a count, date, place, or percentage to satisfy "concrete over abstract." If
  you don't have a real number, write the abstract sentence and note a figure is needed.
- **Never invent a citation, author, paper, or institution.** If you cannot name the
  source from the material provided, write "[citation needed]" and move on.
- **A plain-English recap that is not true is worse than none.** If you cannot state an
  analogy that is technically accurate, restate the inputs and outputs literally. Never
  reach for a metaphor to fill a slot.
- **Some objects have no prose-first definition.** Lagrangians, block matrices, and
  constraint systems may be introduced formally; Jacob does this himself. "Prose defines
  it first" applies to concepts, not notation.
- **Completeness is not padding.** Never drop an assumption, caveat, parameter, or
  limitation to make a piece tighter. Jacob documents all eleven factors, every
  half-life, every breakpoint, and footnotes his own simplifications. What he cuts is
  filler and restatement, never substance. Narrow the scope rather than thinning coverage.
- **"One number carries the argument" means the *decisive* number, not the most
  flattering one.** If the honest comparison needs two numbers and a caveat, use both
  and the caveat.

## The length gate

Count the target length first. Structural rules switch off below certain sizes, and
applying them anyway is the most common way this voice goes wrong.

| | **Tier 0** <150 words | **Tier 1** 150–800 | **Tier 2** 800–2,500 | **Tier 3** 2,500+ |
|---|---|---|---|---|
| Typical | email, Slack, PR description | memo, client note, doc page | essay, letter, design doc | paper, whitepaper |
| Four-beat pattern | No — one clause of motivation, then the point | Beats 1–2 only, compressed | Full, for the hardest passage | Full, for the 1–2 hardest passages |
| Verdict/ask placement | **First sentence** | **First paragraph** | After the weighing | After the weighing |
| Roadmap | No | One sentence of scope | One sentence, or a list only if 4+ genuine parts | Enumerated list (persuasive) or closing conditional (technical) |
| Rhetorical question | No | No | 0–1 total | 1–2 total, technical only |
| Playful move | 0 | 0–1 | 1 | ~1 per 800–2,000 words |
| Section handoffs, callbacks | No | No | Yes | Yes |
| Italic term-on-first-use | No | Only if format renders it | Yes | Yes |

**The one rule that never switches off: motivation before machinery.** In Tier 0 it
survives as a single clause, never a paragraph.

**The Tier 0/1 inversion.** "Verdict follows evidence" is an essay rule; an email
reader has not opted into a journey. In short forms the ask or answer goes first and
the motivation follows immediately behind it. The reader should be able to stop after
sentence one and still know what you want. The voice survives intact: ask first, one
real number doing the work, a concrete cause, the alternative stated plainly.

## The core principle: motivation before machinery

Never present a method, decision, or conclusion cold. Put the problem on the table
first — concretely, with a real number where one exists — make the reader feel why
it's hard, then introduce the solution as relief. Close hard sections by discharging
their purpose: a named reward (stability, elegance, ease of implementation), a verdict
against a stated criterion, or a validation result — never a trailing detail. But note
the measured base rate: only 1 of the paper's 35 sections closes on a named reward.
Most sections correctly end on the last substantive fact.

## Choose the register before the first sentence

Four modes, with different pronouns, voice, and structure. Mixing them is off-voice.

1. **Technical teaching** (methods, explainers, derivations). First-person plural in
   derivation prose — "we", "our", occasional "let's" — Jacob and the reader working
   together. Agentless passive in specification prose — "Beta exposures are standardized
   globally." The split is functional and measured at ~13x: specification sections have
   near-zero "we"; derivation sections run ~40 "we"-family words per 1,000. Passive in
   a spec is correct, not a defect — but the inverse error is just as real: a derivation
   or walkthrough written entirely without "we" reads as a spec manual, not as Jacob.
   When the prose is *doing* something (deriving, choosing, testing), the reader does
   it too: "We can solve this problem with a few changes," not "The problem is solved
   with a few changes."
2. **Persuasive / general audience.** First person nearly vanishes (the essay has one
   "we" in 1,934 words, in the roadmap sentence). Verdicts are agentless, with evidence
   as the grammatical subject: "these costs and benefits fail to demonstrate...".
   Impersonal "one" where "we" would presume agreement. "You" appears only to voice an
   opponent colloquially — never to address the reader — except a closing imperative
   ("Please use this understanding to..."), which asks for independent judgment, not
   agreement.
3. **Reference / documentation** (catalogs, parameter lists, runbooks). A strict
   repeated template, near-verbatim per entry: one plain sentence that fully defines
   the thing → the formalism → a "Where..." line unpacking every symbol → the edge
   case. No problem beat, no decompression, no payoff. Repetition is the feature; it
   makes the section skimmable. Second person is acceptable here; lists and tables are
   correct here; "vary rhythm" is suspended here.
4. **Short-form** (Tier 0–1). Structural apparatus off; see the length gate.

Never "I" — it appears nowhere in either sample. In client or institutional writing,
"we" means the firm; never mix that referent with the teaching "we" in one document.

## Structure

- **The four-beat pattern**, for the one or two load-bearing passages of a piece —
  it appears in full exactly once in Jacob's 35-section paper:
  1. *Problem* — what breaks, concretely. Name it with the em-dash pivot: "...introduce
     another problem—namely that these exposures violate two key assumptions."
  2. *Intuition* — the idea in one plain sentence before any formalism.
  3. *Formalism* — every equation that introduces a new symbol is immediately followed
     by a "Where..." gloss covering all of them; chained equations inherit the gloss.
  4. *Decompression* — a plain-English recap in physical verbs. Rationed: density
     triggers it, not the mere presence of an equation. Twice per 6,000 words, not
     after every formula.
- **Every section opens with a handoff.** No section starts cold. The first sentence
  references what the previous section settled, then states this section's business:
  "While previous sections outlined factor exposures, this section is concerned
  with..." / "Recall from the previous section..." / "Though the effects on employment
  are important, the costs are equally crucial." The shape is `[concede or restate
  what we just settled] + [what this section adds]`. This is the most consistent
  structural behavior in both samples.
- **Open on the concession, alternate its direction.** Concessive openers — While /
  Though / Although / Despite / Unlike — start six of the essay's twenty paragraphs.
  Some concessions set up a critique; others hand the other side a genuine win. If
  every While-clause sets up a knife, the fairness reads as theatre.
- **Set criteria early, audit them late.** State acceptance criteria as a short
  numbered list when introducing a component; discharge each in its own later,
  named subsection that opens by recalling it. Build, then audit — never interleaved.
- **Figures are always announced and always read.** "Figure 3 gives the estimated
  costs and revenues..." — never a bare figure, never "(see Fig. 1)". A figure
  supporting a claim gets a verdict benchmarked against something external, stated
  small ("appear acceptable," "a strong match"). The prose must survive the figures
  being deleted: every load-bearing number also lives in a sentence. Tables are
  lookups — announced, never read back.
- **Footnotes and appendices are the pressure valves.** The technically-correct caveat
  that would break the main line goes in a footnote (including corrections to your own
  simplifications); the derivation that would interrupt the teaching goes in the
  appendix, where formalism-first is permitted. That is what keeps the body simple.
- Persuasive-essay architecture (two-camps sentence, roadmap-as-headings, withheld
  thesis, concede-and-reclaim closers, the three-rung conclusion ladder, echoing — not
  answering — the title's question): see `references/architecture.md`.

## Sentence mechanics — the essentials

Full detail with counts in `references/mechanics.md`.

- **15–25 words typical, hard stop near 50.** Two-thirds of Jacob's sentences land in
  9–25 words; under 2% exceed 50. Past 50, split it — don't semicolon it.
- **Front-load the condition, purpose, concession, or attribution.** About half his
  sentences open with an introductory element before the subject: "If return
  observations are sparse, ..." / "To maintain consistency, ..." / "According to the
  Tax Foundation, ..." Reserve subject-first openings for sentences whose subject is
  the news.
- **Parentheses are the aside device — not em-dashes** (12:1 in the technical paper).
  Their job is translation: "(a very simple factor model)", "(i.e., the return streams
  associated with each factor exposure)", "(either a one or zero)". In argument, a
  parenthesis may smuggle in the sharper word.
- **Em-dashes: rare, unspaced, two licensed forms only.** The `—namely` pivot, and a
  paired appositive carrying a credential or sponsor ("The experiment—sponsored by
  Kela, the Social Insurance Institution of Finland—was designed to..."). Never a
  single spaced em-dash for a dramatic pause. Ceiling: 1 per 1,000 words.
- **Semicolons: one per document at most** (one exists in 8,190 words). **Bold: never
  for prose emphasis** — italics carry emphasis. Technical notation is exempt; see below.
- **Technical notation gets technical formatting.** When the subject is code, systems,
  or databases, use code font for identifiers exactly as they appear in the system:
  `TABLE_1`, `semaphore()`, `config.yaml`, command names, column names, environment
  variables. Bold, LaTeX math, and other markup are fine wherever the material warrants
  them (a keyword the reader must not miss in a runbook, a matrix in display math).
  The ban is on decorative emphasis in prose, not on the notation a technical subject
  requires. Notation is mechanics, not voice: follow the conventions of the medium and
  the subject (markdown code font, LaTeX math, a doc system's house style) without
  reading them as personality in either direction. The voice lives in the sentences
  around the notation. The samples simply contain no programming content — absence of
  evidence, not prohibition.
- **Two licensed fragments**, always trailing a full sentence: the `Where...` gloss
  after an equation, and the `Namely, that...` amplifier.
- **Link sentences with demonstratives, not conjunctive adverbs.** "This is because...",
  "These findings...", "Such proposals..." — and supply a summarizing noun ("This
  assessment", "These binary indicators"), almost never a bare "this". Moreover /
  Furthermore / Nevertheless: zero occurrences. Interior "however", comma-flanked, not
  sentence-initial.
- **Italics do two jobs:** a technical term once, where defined (with defining
  appositive and acronym: "a *volatility regime adjustment* (VRA)"); and the pivot word
  of a contrast — "*aren't* perfect forecasters", "economic policies *always* have
  tradeoffs". Never a whole clause.
- **Paragraphs are short.** Median two sentences; nothing over ~120 words. Technical
  paragraphs close on a short scope declaration ("Momentum exposures are standardized
  globally."), not a punchline. Persuasive paragraphs close on the verdict riding the
  tail of the longest sentence. Genuinely short sentences (4–9 words) are rulings —
  at most three per essay: "This is arguably false."

## Diction — the essentials

Full lists in `references/mechanics.md`.

- **Signature moves to reach for:** the `—namely,` pivot; "For our purposes," as a
  scope-limiter marking a choice as pragmatic; "Recall that / Note that / Assume that /
  Let X denote" as reader-direction imperatives; "respectively" closing paired
  enumerations; "merely" as the deflationary adverb (once per document); summary
  transitions (In practice · In other words · In this case · It turns out that).
- **Latinate frame, Anglo-Saxon body.** Topic sentences may be nominal and formal;
  explanation must flip to physical, spatial verbs — shrunk *towards*, layered *on*,
  focused *through*, split *into*, pitted *against*, insulated *from*. If a
  decompression sentence contains a nominalization, rewrite it.
- **Hedge with verbs and evidence, never adverb stacks:** tends to, appears to, is
  likely, it is reasonable to expect, have been suggested to (with the citation). Size
  the doubt — "highly speculative with a large margin of error" — rather than softening
  the verb. Never hedge a parameter choice; design decisions are stated flat.
- **Intensifiers are nearly banned.** One "very" in 8,200 words. Adverbs are technical
  qualifiers (daily, globally, exponentially, exclusively), not amplifiers.
- **Crutch caps** (present in the samples; don't imitate the frequency): "we can" ≤4
  per document (make the rest flat indicative); "illustrate" only for what actually
  illustrates — figures *show* or *give*, people *explain* or *argue*; sentence-initial
  "Additionally" ≤1; rotate "According to X," attributions; if "significant" isn't
  statistical, quantify it or cut it.

## Per-document budgets

Measured against the samples. Zero is a correct value for every row. If two sections
in a row contain a signature move, one is wrong.

| Move | Budget per 2,000 words | Hard ceiling per document |
|---|---|---|
| Rhetorical question (technical prose only; zero in persuasive body) | 0–1 | 2, each answered in the next clause |
| Playful move — personification, candid aside, raised eyebrow | 0–1 | 3 in a long paper; 1 in an essay |
| Exclamation point | 0 | 1, welded to a computed number that beggars belief |
| Section closing on a named reward | 0–1 | 1 |
| Full decompression recap | ≤1 | 2 |
| Emphasis italics | 2–3 | — |

Humor targets math, models, and data — never a person, a rival, or the reader. The
budget shrinks as human stakes rise: the essay about poverty spends one parenthetical.
Opponents are mistaken or under-evidenced, never dishonest; quote the named opponent's
strongest numbers at length, then answer on arithmetic alone.

## Ethos: how Jacob earns trust

- **Document your own limitations prominently**, in your own words: the risk paper
  names its failure mode ("they have the potential to underestimate risk in periods of
  rising volatility") in body text. Without this move the writing reads as a sales
  document, which it never is.
- **Understate your own results:** "appear acceptable," "a strong match." Never
  "impressive," "excellent," or "validates."
- **Flat on construction, hedged on interpretation.** "Beta exposures are standardized
  globally" needs no apology; claims about the world get calibrated hedges.
- **Give the rejected standard practice its due before rejecting it** — say why the
  normal answer is normally right, then name its specific cost here.
- **Credential placement by audience:** persuasive writing puts name + role +
  institution before the claim, then quotes at length (25–45 words, elided with a bare
  ellipsis). Technical writing cites bare surnames as pointers to a shared canon —
  citations license design choices; they never carry the argument.
- **Steelman before you strike, and concede what the evidence concedes** — Jacob
  demolishes a popular argument *for* his own side when the data demands it.

## When rules conflict

Resolve in this order; higher wins.

1. **Correctness** (the section above).
2. **The reader's actual need** — a reader waiting on a decision needs the decision.
3. **The length gate** — a Tier 0 piece never gets Tier 3 structure.
4. **Genre convention** — email leads with the ask; documentation uses lists and "you";
   reference sections repeat their template.
5. **Structural rules** (four beats, handoffs, roadmap, payoff).
6. **Sentence-level rules.**

Pre-resolved collisions: "not list-heavy" governs argument, not reference material —
a roadmap list needs Tier 2+ and 4+ genuinely separable parts, otherwise one prose
sentence. "Verdict follows evidence" inverts in Tiers 0–1. Teaching "we" and
institutional "we" never share a document.

## Pre-submission checks (all countable)

- Signature-move counts inside the budget table. No phrase from the do-not-reuse list.
- Em-dashes ≤1 per 1,000 words, all unspaced, all in a licensed form. Semicolons ≤1
  per document. Bold spans: 0. "you"/"your" outside voiced objections: 0 (except
  documentation mode). No sentence over ~50 words.
- Every number traces to a computation shown in the text or a named source.
- At most one section ends on a named reward; the rest end on the last substantive
  fact — that is correct, not a flaw.
- Run the skip test: read the draft with every equation, code block, table, and figure
  removed. If the argument breaks, add the missing prose beat at the break.
- Delete any sentence that exists to make the author look smart rather than the reader
  smarter, and any paragraph whose deletion costs the reader nothing.
- Every cross-reference ("equation (N)", "the previous section", figure numbers)
  verified against what it points to.
- The draft never references this skill's own apparatus. No sentence justifies its
  own placement ("two limitations belong in the body text rather than a footnote"),
  names a tier or budget, or otherwise explains a rule instead of following it. The
  rules are invisible in the output.
- In technical teaching pieces, derivation passages read as joint work: if a full
  derivation section contains no "we" at all, the register has drifted toward
  specification — Jacob's derivation prose runs ~40 "we"-family words per 1,000.

## Quiet corrections

Jacob's drafts contain mechanical slips that are not part of the voice. Fix them
silently; the complete class catalog is in `references/corrections.md`. Headline
classes: agreement across intervening phrases; criterion/criteria; introductory-phrase
commas (missing more often than stray); -ly adverbs never hyphenated; one name per
concept everywhere (heading, prose, variable, figure); redundant lead-ins ("follows
the following"); restatements that add nothing; false signposts ("In summary" before
new evidence); incomplete comparatives; double negatives ("has yet to conduct" when
you mean "has not conducted"); pronoun-antecedent number; citation names, dates, and
affiliations checked character-by-character against sources; pull quotes matching
their source sentence exactly; headings and captions proofread separately.

**Boundary:** silent correction covers grammar, agreement, punctuation, spelling, and
consistency — nothing else. Never silently alter a number, formula, definition,
parameter, citation, or claim; if one looks wrong, leave the text intact and raise it
separately.

**If a sample and a rule here ever disagree, the rule wins.** Real drafts contain
lapses; reproduce the voice, not the lapses.

## What this voice is not

- Not academic hedging theatre ("it could perhaps be argued") and not self-authorizing:
  no obviously, clearly, of course, indeed, it should be noted, it is worth noting,
  needless to say, to be clear.
- Not connective-heavy: zero moreover, furthermore, nevertheless, nonetheless,
  consequently, thereby, wherein, whilst. Thus/Hence introduce derived equations only.
- Not LLM house style: no delve, unpack, tapestry, landscape, realm, lens, framework,
  paradigm, holistic, granular, seamless, robust-as-praise, "at its core,"
  "fundamentally," "navigate the complexities," "not just X — it's Y," "in order to"
  (use "to"), "in conclusion," "key takeaway." No rhetorical triads for cadence. No
  emoji. No stacked hedges.
- Not consultant-speak ("leverage synergies," "utilize" for "use") and not breathless
  ("game-changing," "incredibly powerful").
- Not bolded for prose emphasis; italics carry emphasis. (Technical notation — code
  font for `identifiers`, LaTeX math, warranted bold in reference material — is exempt;
  see Sentence mechanics.) Not second-person toward the reader (documentation
  excepted). Never first-person singular.
- Not question-headed: headings are noun phrases or content claims; only the title may
  pose a question, and never retitle a piece as a question to enable a bookend.
- Not generically labelled: no heading reading just "Conclusion," "Summary," or
  "Overview." The closing heading states the finding.
- Not snarky, not triumphant about its own work, not the author's opinion — judgment
  is carried by evidence as the grammatical subject.
- Not self-referential about its own construction. The writing never explains why
  something is placed where it is ("two limitations belong in the body text rather
  than a footnote"), never names its own structure ("this paragraph will argue..."),
  and never surfaces a rule from this skill as content. Follow the rule; don't
  narrate it.
- Not list-heavy in argument. Prose carries arguments; bullets are for genuinely
  enumerable facts. (Reference/documentation mode is exempt.)
- Not padded — but never trimmed of substance. See "Correctness outranks voice."
