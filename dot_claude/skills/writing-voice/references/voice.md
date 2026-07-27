# Voice Reference: Annotated Examples

Excerpts come from two of Jacob's pieces in different genres: a global equity risk
model paper (technical, expert audience) and "A Universal Basic Income: Effective or
Overkill?" (policy explainer, general audience). Moves that appear in both are the
core of the voice. When drafting, imitate the *moves* — never the subject matter and
never the wording. Every quoted line below was minted once for one moment; a draft
that reuses any of these phrasings verbatim is an impression of Jacob, not Jacob.
SKILL.md's do-not-reuse list is binding here.

## Part 1: The risk model paper (technical writing)

### Motivation before machinery

> For example, if one has a portfolio consisting of N different assets, they must
> estimate (N² − N)/2 unique covariance terms to capture all the pairwise co-movement
> in their portfolio. In the case of a 300-stock portfolio, one would need to estimate
> 44,850 unique parameters!

The problem is made concrete with a real count before factor models are ever mentioned.
The lone exclamation point in the paper is spent here, on the number that justifies
everything that follows. **Move: quantify the pain, then introduce the cure.**

### Intuition stated in one plain sentence before formalism

> Diversification, therefore, is the attempt to immunize the active portfolio from
> disastrous errors in the return forecast.

A whole literature compressed into one declarative sentence. No equation needed yet.
**Move: earn the equation with a sentence the reader can hold.**

### Decompression after dense math

> So what just happened? In non-linear-algebra terms, the model focused the underlying
> factor exposures of each stock (contained in B) through the factor covariance matrix F,
> and layered on a matrix of stock-specific risk (Γ) to forecast pairwise covariances
> for every stock.

Immediately follows the key matrix equation. The rhetorical question voices the reader's
own bewilderment, then resolves it in physical language ("focused... through... layered
on"). **Move: after a genuinely dense block — once or twice per document, not after
every equation — translate back to plain English, in fresh words, only if the plain
version is technically true.**

### The rationed playful move

> The villain in this case is a statistical property called *multicollinearity*.

> We then do a statistical procedure that at first might seem a little strange.

These are two of only three playful moves in a 6,256-word paper. They work because
the surrounding prose is disciplined. **Move: budget roughly one wink per 2,000 words,
never two in a paragraph, and aim them at math and models — never at people.**

### Payoff sentence closing a hard section

> Although a significant amount of mathematical maneuvering is required, equation (34)
> gives us an elegant solution for our factor returns that can be easily programmed.

The section ends by naming the reward — elegance and practicality — not by trailing off
on a detail. **Move: end sections on the payoff.**

### Concrete anchoring

> When the New York Stock Exchange opens at 9:30 a.m., it could be mid-day at the
> London Stock Exchange and between trading hours in Tokyo.

> For example, Lithuania, Latvia, Romania, Serbia, Slovakia, and several other countries
> are grouped together to form the "Small Eastern European Markets" factor.

Abstract claims (asynchronous prices, thin markets) are grounded in named places.
**Move: an abstract claim gets a concrete instance within two sentences.**

### The section handoff

> While previous sections outlined factor exposures, this section is concerned with the
> computation of factor returns (i.e., the return streams associated with each factor
> exposure).

> Though the effects of a universal basic income on employment are important, the costs
> associated with a UBI are equally crucial to understand.

Every major section in both documents opens by referencing what the previous one
settled before stating its own business. The technical paper uses *While / Recall /
Once*; the essay uses *Though / Despite*. **Move: never start a section cold — concede
the last one's finding, then add yours.**

### Signposting and callbacks

> Recall that stock exposures to industry and region factors are dummy variables
> (either a one or zero) rather than the style exposure scores described in the
> previous section.

> Where f_int and ε are intercept and error terms, respectively (more on the intercept
> later, as it has unique economic significance).

The reader is never lost, and curiosity is planted ahead of the payoff. **Move: promise
interesting things before delivering them.**

### Rhetorical question at the pivot

> But if B_t is the matrix of factor exposures, what does f_t, the vector of factor
> return parameters we are estimating, represent?

Placed exactly where a careful reader would be asking it. **Move: ask the reader's
question for them, then answer it.**

### Define-then-formalize (the factor-definition template)

> Momentum is defined as the sum of daily log returns over the last 260 business days,
> excluding the most recent 22 business days. Momentum exposures are standardized
> globally.

One plain sentence carries the full definition; the equation that follows merely
confirms it, and a "Where..." line unpacks every symbol. This template repeats for all
eleven factors with near-identical rhythm — repetition as a feature, because it makes a
long reference section skimmable. **Move: in reference material, use a strict repeated
template and let the prose sentence do the defining.**

## Part 2: The UBI essay (persuasive writing for a general audience)

### The hook: one striking fact, then the stakes

> According to a recent poll by the Pew Research Center, 45% of U.S. adults are in
> favor of a guaranteed, unconditional cash transfer of $1,000 per month for all
> adult citizens.

The piece opens on a number, not a thesis. The controversy is established as real
before any argument begins. **Move: open with the fact that proves the topic matters.**

### The enumerated roadmap

> To separate fact from fiction, we will explore the following ideas:
> (1) The definition of and arguments for a UBI
> (2) The myth of the lazy welfare recipient
> (3) The fiscal and economic costs of basic income ...

Same signposting instinct as the risk paper, adapted for a general reader. The phrase
"to separate fact from fiction" names the piece's job in six words. **Move: tell the
reader the itinerary, and why the trip is worth taking.**

### Steelmanning the other side

> One common criticism of basic income is this: if you give people a bunch of
> undeserved money, you risk making them lazy or less likely to pursue employment.
> This is arguably false.

Jacob is skeptical of UBI overall, yet he demolishes a popular *anti*-UBI argument
with the Harvard/MIT cash-transfer data. The reader learns they're in the hands of
someone following evidence, not a team. Note also the colloquial phrasing of the
opposing view ("a bunch of undeserved money") — the criticism is voiced the way people
actually say it. **Move: concede what the evidence concedes; voice objections
colloquially.**

### One number carries the argument

> According to the Tax Foundation, Yang's proposal would cost around $2.8 trillion
> with his proposed taxes only bringing in $1.3 trillion.

No adjectives, no outrage. The gap between the two numbers does all the work.
**Move: find the single comparison that settles the point and state it plainly.**

### Calibrated language

> This assessment, however, is highly speculative with a large margin of error.

> Lack of data aside, if existing evidence is any indicator...

Claims are sized to their evidence. Even the piece's own side gets hedged when the
data is thin. **Move: spend certainty only where the numbers back it.**

### The rationed wink, general-audience edition

> ...a bold (or reckless) course of action...

> ...it will become clear whether a UBI is effective or overkill.

The parenthetical "(or reckless)" is the essay's one raised eyebrow, and the final
sentence answers the title's question with its own words. **Move: one wink per piece;
bookend the title's question in the closing line.**

### Verdict after evidence, in plain terms

> Simply put, a UBI merely rearranges the tradeoffs in the existing system without
> necessarily improving the net effect.

The conclusion arrives late, earns its place, and is stated in one sentence a
non-economist could repeat at dinner. **Move: make the thesis quotable and place it
after the weighing, not before.**
