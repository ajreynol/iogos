# Discussions: requests to `ethos-eoc`

A working document for changes we would like from the Eunoia compiler's
`isabelle-meta` backend, which lives in the Ethos repository at
`tools/eoc/` and is documented in
[`tools/eoc/README.md`](https://github.com/cvc5/ethos/blob/main/tools/eoc/README.md).

Nothing here is a bug report against a finished tool. The Isabelle backend is
at its initial stage and says so; what follows is what the first consumer of
its output ran into, written down so that the ordering can be argued about
rather than guessed at.

**How to use this file.** One section per request, newest at the bottom.
Each carries a status, and a **Response** heading once the backend has one, so
that a decision taken in conversation does not have to be reconstructed later.
Requests that are settled stay here with their outcome rather than being
deleted.

| Status | Meaning |
| --- | --- |
| `open` | raised here, no response yet |
| `accepted` | the backend intends to change |
| `declined` | not going to change, with the reason recorded |
| `done` | landed in the compiler; note the Ethos revision |

## What this is about

Everything below refers to the CPC session installed by
`tools/eoc/cpc/install_iogos`, as of the first install into this tree. Its
shape, so that the requests have a scale attached:

| | |
| --- | --- |
| `Cpc_Checker.thy` | 2.1 MB, 9,343 lines, one theory |
| datatypes | 46 |
| generated programs | 1,038 `primrec` |
| proof rules | 591 |
| lemmas in the checker | 1 |
| `Cpc_Spec.thy` | 591 obligations, 1 lemma |
| `sorry` / `oops` / `axiomatization` | none |

Two things are worth saying before the complaints, because they are load
bearing and neither is obvious.

The **fuel design is right**. Eunoia programs are Turing-complete, and
compiling them to `primrec` over a `nat` budget makes every one of them total
by construction: no `function` package, no termination obligations, no
well-founded relations to invent, and no `sorry`. Returning `option` so that
exhaustion propagates as `None`, kept distinct from `Some Term_Stuck`, means
budget exhaustion cannot be mistaken for acceptance, and that is enforced by
the types rather than by a proof anyone has to maintain.

The **datatype chunking is right**. `CRule` is 25 constructors each wrapping a
24-constructor `CRule_chunkN`. A flat 591-constructor datatype would put
roughly 174,000 distinctness lemmas through the datatype package; chunked, it
is about 7,000.

## 1. Split the generated output into many theories

**Status:** `open`

Everything is emitted into a single 2.1 MB theory. Isabelle's parallelism comes
from forking proofs, and this theory contains exactly one; the other 9,342
lines are definitional commands, which run strictly sequentially. So the build
is effectively single-threaded whatever is passed to `isabelle build`, and
memory rather than cores is the binding constraint.

Interactively it is worse. Isabelle/jEdit re-elaborates from the edit point
downwards, so opening the file to look at anything near the bottom means
waiting for the whole of it.

**Request.** Emit **one theory per rule**, as the Lean backend already emits one
module per rule. `logos/Cpc/Proofs/Rules/` holds 591 files — `And_elim.lean`,
`Xor_elim1.lean`, and so on — which is exactly the 591 rules the Isabelle
backend compiles into one file. The two backends consume the same desugared EO
programs and the same rule set; the granularity of what they write out should
not differ.

Concretely, three layers:

- a **base** theory with the term datatypes, the native helpers and the shared
  programs the rules call (`p_typeof`, `p_run_evaluate`, and the rest);
- **one theory per rule**, importing the base;
- a **dispatch** theory importing all of them, holding `p_cmd_step_proven` and
  `check_refutation`.

Why this shape rather than batches:

- **It parallelizes.** Isabelle elaborates theories concurrently according to
  the import graph, so 591 siblings over a common base is close to the best
  case available. This is the direct answer to the build being single-threaded
  today.
- **It is incremental.** Editing or regenerating one rule re-elaborates that
  rule and the dispatch, not all 591. Today any change re-elaborates 2.1 MB.
- **It makes regeneration reviewable.** A calculus that changed three rules
  produces a three-file diff instead of a diff against one 2.1 MB file. This is
  the other thing Logos gets from per-rule modules, and it matters here because
  the generated session is committed.
- **It makes per-rule work possible at all.** Logos has
  `scripts/build-cpc-rule.sh` for building a single rule; there is no Isabelle
  equivalent because there is nothing to point it at.

Two things to settle in the design:

- **Mutually recursive rules must share a theory.** Isabelle has no cycles in
  its import graph, so the unit is really a strongly connected component of the
  program call graph, which collapses to one rule in the common case. The
  compiler already computes that call graph.
- **The dispatch still imports everything.** That is fine — importing an
  already-elaborated theory is cheap next to elaborating it — but it does mean
  the dispatch is the one file that always rebuilds, which is what request 2 is
  about.

This is the highest-leverage change on the list, and requests 2 and 4 both get
easier once it lands.

## 2. Split the top-level rule dispatch

**Status:** `open`

`Cpc/Cpc_Checker.thy:9231` is a single `primrec` equation of 226,351
characters: the `p_cmd_step_proven` dispatch, casing over all 591 rules inline.
It is the largest of several, the next being `p_run_evaluate` at 109,800 and
`p_str_re_consume` at 104,634.

Two consequences. `primrec` derives each equation from a recursion combinator
and proves it, so a quarter-megabyte term becomes a single enormous proof,
which is exactly where pathological blowup lives. And the central dispatch is
undebuggable: every error in it reports at one line number.

Request 1 does not fix this on its own: a rule's *own* program moves out to its
own theory, but the dispatch that selects between 591 of them stays behind, and
it is the largest single equation in the file.

**Request.** Apply to the dispatch the chunking already applied to the rule
enum that it consumes — a `p_apply_rule` split per `CRule_chunkN`, each in the
theory for its chunk, or simply one equation per rule. The information needed
to do it is the same information that produced the chunks.

`p_run_evaluate` and `p_str_re_consume` are not rule dispatches and so are not
covered by either request; they are large for their own reasons and may want
looking at separately.

## 3. State the connection between the obligations and soundness

**Status:** `open`

This is the one we care about most.

`Cpc_Spec.thy` defines 591 `obligation_*` predicates and, at
`Cpc/Cpc_Spec.thy:1789`, `checker_sound_for`. There is **no theorem relating
them**. The only lemma, `checked_refutation`, is `checker_sound_for` unfolded
against its own hypothesis.

As generated, then, all 591 obligations can be discharged by taking
`valid = (\<lambda>_. True)`, and nothing whatever has been proven about the
checker. Each obligation also constrains only the result --- the shape is
`p_X fuel args = Some r \<longrightarrow> r \<noteq> Term_Stuck \<longrightarrow> valid r` ---
and says nothing relating that result to the premise proofs in `args`, so the
generated half carries almost no information on its own.

We are not asking the backend to prove soundness; that is the substance of the
work here and nobody expects it from a compiler. We are asking it to **state**
the theorem, because without the statement there is no way to tell whether the
obligation shape is even strong enough to imply soundness, and every consumer
has to invent the same locale independently.

**Request.** Emit a locale fixing `valid` and `unsatisfiable`, assuming the
591 obligations, and stating `checker_sound_for unsatisfiable` as its goal:

```isabelle
locale cpc_sound =
  fixes valid :: "Term \<Rightarrow> bool"
    and unsatisfiable :: "CArgList \<Rightarrow> bool"
  assumes obl_xor_elim2: "obligation_xor_elim2 valid fuel arg0"
    and ...
begin

theorem checker_sound: "checker_sound_for unsatisfiable"
  \<comment> \<open>the development's goal; not proven by the compiler\<close>

end
```

If the honest answer is that the obligations as generated are *not* sufficient
--- which is our suspicion, given that they do not mention the premises --- then
that is the most useful thing this request could establish, and it would
redirect the obligation shape before anyone builds on it.

## 4. Emit fuel monotonicity lemmas

**Status:** `open`

Any fuel-indexed development needs

```isabelle
p_X fuel args = Some r \<Longrightarrow> p_X (fuel + n) args = Some r
```

before it can do anything at all, since without it two results computed at
different budgets cannot be composed. That is 1,038 lemmas, one per generated
program.

Each is an induction on fuel against the program's defining equation, which for
`p_cmd_step_proven` means inducting over the 226 KB equation of request 2. So
as things stand **the first lemma the development needs is the hardest one in
the file to prove**, which is the wrong way round.

**Request.** Generate these alongside the programs. They are mechanical, the
compiler knows the recursion structure, and request 2 makes them cheap.

## 5. Generate well-formedness predicates for the term datatype

**Status:** `open`

The term datatype admits values that no Eunoia term denotes.
`Term_Binary "int" "int"` carries a width and a value with no constraint that
the value is in range or the width non-negative; `Term_String "nat list"`
admits non-scalar code points.

HOL cannot rule these out in the type, so the cost is paid forever afterwards:
every program handles them defensively, and every proof about terms carries
junk cases that correspond to nothing.

**Request.** Emit a `wf_Term` predicate (and its companions for the other
datatypes) capturing the invariants the compiler already knows. It does not
have to be used by the checker to be worth having --- it lets the development
state its theorems about the terms that mean something.

## 6. Consider breaking the `Term` / `Datatype` mutual block

**Status:** `open`

`Cpc_Checker.thy:269`--`301` declares `Datatype`, `DatatypeCons`,
`DatatypeDecl` and `Term` as one mutually recursive block, because datatype
declarations are inlined into terms (`Term_DatatypeType`, `Term_DtCons`,
`Term_DtSel`). Every induction over terms is therefore a four-way mutual
induction, permanently, including the ones in requests 4 and 3.

**Request.** If declarations could be a separate structure that terms reference
by name rather than carry inline, the mutual block disappears and every
induction over `Term` gets simpler. Filed as a question rather than a demand:
we do not know what the reference-by-name form would cost elsewhere in the
compiler, and this may not be worth it.

## Not requests: what iogos does itself

Recorded so that nobody files them upstream by mistake.

- **Executable smoke tests.** Nothing in the installed session evaluates the
  checker on a single proof, so a generator bug producing a well-typed but
  wrong checker builds green. Ethos has `tools/eoc/test/isabelle_smoke.thy` for
  its own test signature; the CPC equivalent belongs here, in a handwritten
  session under `Cpc/`, separate from its generated top-level files.
- **The soundness development.** `Cpc/Soundness/`, once request 3 settles what it
  is developing against.
- **Build resources.** Timeouts, job and thread counts, and whether CI can host
  the build at all are ours to measure and set.

## Open questions

- **What is the trust story for `by eval`?** It compiles to ML and trusts the
  code generator and the ML compiler; `normalization` trusts less; `simp`
  trusts least and will not scale here. Logos faces the analogous question with
  Lean's kernel against `native_decide`, so there may be a house answer already
  that we should just adopt.
- **What does the build actually cost?** Time and peak memory for the installed
  session are unmeasured at the time of writing. Several requests above are
  argued from the shape of the source rather than from a build, and that number
  should be attached here once someone has it.
- **Is the obligation set complete?** 591 obligations against 591 rules is a
  clean correspondence, but we have not checked that the excluded rules of
  CPC's configuration are accounted for, or what the spec should say about
  them.
