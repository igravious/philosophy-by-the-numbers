# DH2027 CFP Planning

**Status:** Active planning; two submissions selected, with their shared inputs and maturity limits made explicit.
**Scope:** Project-wide planning. This is not specifically an emerging-philosophy submission plan.
**Source:** [DH2027 Call for Proposals](https://dh2027.adho.org/cfp/)

## Conference context

- Conference: DH2027, University of Galway, Ireland, 28 June–3 July 2027.
- Theme: “Creativity”. The CFP also welcomes work across digital humanities that does not address the theme directly.
- Submission deadline: 20 November 2026, 11:59 PM AoE.
- Researcher context: sole independent researcher.
- Submission categories: long papers, short papers, posters, and pre-conference formats. The last category comprises workshops and mini-conferences. Technical and Digital Art(s) are track designations, not additional formats.
- Long papers are 2,500–3,000 words; short papers are 1,000–1,250 words. Both are much shorter than thesis chapters, so each proposal must present a bounded contribution rather than an entire research pillar.

Being a sole independent researcher does not exclude any CFP format. The CFP states no co-author or institutional-affiliation requirement. Multiple submissions are permitted according to the researcher's existing knowledge of the conference rules.

## Strategic objective

Submit both `philosophy-by-the-numbers` and `delta-of-deltas` as complementary parts of one research programme. The pair should demonstrate an existing research platform and a credible methodological next step, including to potential future collaborators or supervisors.

The shared narrative is:

> How should we construct a philosophical corpus, and how can we know when it is sufficient for conceptual analysis?

## Research-programme structure

0. **`emerging-philosophy`** — historical software and literature background. An A0 poster is a plausible later output; its preparation is deferred, including the suggested future use of an agent swarm.
1. **`philosophy-by-the-numbers`** — canonicity, institutional recognition, and corpus inclusion. Implementation plan: [Plan CFP-A: Canonicity Metric Runs](../plans/PLAN-CFP-A-CANONICITY-METRIC-RUNS.md).
2. **`philosophy-in-terms`** — computational and editorial representations of philosophical concepts and their relationships. The standalone paper is on the back burner for another conference, but its data and methods remain inputs to delta-of-deltas.
3. **`delta-of-deltas`** — second-order changes in representations produced from progressively larger philosophical corpora.

**Typed Semiotics is quarantined.** It is too speculative for the current programme and is not a CFP or near-term thesis direction.

## Required dependency between the pillars

Delta-of-deltas is not independent of the other two methodologies:

- `philosophy-by-the-numbers` supplies significance measures and the ordering of works for progressive corpus construction.
- `philosophy-in-terms` supplies the representations extracted from each cumulative corpus, currently Saffron resultsets such as terms, weights, similarities, and document distributions.
- `delta-of-deltas` compares successive representations and then examines changes between those differences.

In schematic form:

> significance-ordered works + per-corpus Saffron representations → first-order deltas → delta-of-deltas

The back-burner decision applies only to a standalone comparative domain-modelling submission. It does not remove Saffron or the `philosophy-in-terms` data pipeline from the delta-of-deltas submission.

Consequently, the delta submission must not claim domain-independent “conceptual convergence”. Its preliminary claims are conditional on the specified works, ordering, Saffron configuration, and difference strategies. “Terminological convergence” is the safer current framing.

## Submission 1: `philosophy-by-the-numbers`

**Target format:** Long paper, conditional on obtaining completed sensitivity findings before submission. Fall back to a short paper rather than present anticipated outcomes as completed research.

**Working title:** *Philosophy-by-the-Numbers: Auditing Canonicity through Reference Works and Linked Data*

**Bounded research question:** How sensitive are computational measures of philosophical canonicity to the reference works and weights used to construct them?

The longitudinal study remains necessary for the larger thesis chapter but is not required for this bounded conference contribution.

### Evidence and analysis required

- Freeze the current dataset and algorithm configuration.
- Establish the baseline ranking.
- Run leave-one-source-out and weight-perturbation comparisons.
- Report rank correlations and the largest movements.
- Examine figures or works that particular configurations include, exclude, promote, or marginalise.
- Discuss editorial authority, missing data, and computational canon formation without presenting the metric as objective philosophical worth.

This is the humanities-facing submission: an existing corpus and research platform, an auditable methodology, and a philosophical problem concerning recognition and canon formation.

## Submission 2: `delta-of-deltas`

**Target format:** Short paper. The Technical Track is optional.

**Working title:** *Delta-of-Deltas: Measuring Terminological Convergence in a Growing Philosophical Corpus*

**Bounded research question:** Can second-order changes in extracted terminology provide a useful signal that adding further philosophical works is no longer materially changing the output of a specified extraction pipeline?

The short-paper format is appropriate for experiments, exploratory research, and newly conceived methods. The proposal must not imply that validation is already complete.

### Inputs and evidence required

- Document how canonicity determines the ordering of works.
- Identify exactly which `philosophy-in-terms`/Saffron outputs and configurations feed the analysis.
- Verify the retained progressive runs and the 65 adjacent-corpus comparisons, including their provenance and completeness.
- Compute and inspect the second-order series rather than treating first-order deltas as the finished analysis.
- Compare first- and second-order signals and avoid treating one small second-order value as sufficient evidence of convergence.
- Include alternative orderings or other validation where feasible; otherwise identify it explicitly as ongoing work.

This is the methodological submission: a novel extension of the existing platform with a clear evaluation programme.

## Workshop and mini-conference decisions

A workshop could be derived from university-module teaching materials, but those materials are not presently available. A viable workshop needs learning outcomes, a coherent agenda, activities, participant materials, and instructor expertise. Preparing one would mean developing a teaching programme as well as writing a proposal.

A mini-conference would require a network of like-minded philosophic-computing researchers, participants, programme development, and coordination of a day-long gathering. It would therefore require substantial community-building rather than consolidation of existing project work.

Neither format is a short-term target. The practical criterion is how much a submission consolidates existing work versus requires building something new.

## Immediate work

1. Audit the current `philosophy-by-the-numbers` data and determine whether the sensitivity study can produce completed findings in time.
2. Trace the exact inputs from `philosophy-by-the-numbers` and `philosophy-in-terms` into the retained delta runs.
3. Verify and extend the delta analysis needed for a preliminary short-paper result.
4. Draft both proposals with one shared programme narrative but distinct research questions and no duplicated substantive content.
5. Check each submission against the CFP review criteria, include references and the required generative-AI disclosure, and prepare separate PDFs for ConfTool.

## Outstanding decisions

- Whether the canonicity sensitivity findings are strong enough for a long paper or require the short-paper fallback.
- Which Saffron outputs and configurations are valid, reproducible inputs for the delta submission.
- How much ordering and stopping-rule validation can be completed before the deadline without overstating preliminary results.
