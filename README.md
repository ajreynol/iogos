# iogos

> [!WARNING]
> **THIS IS AN EXPERIMENTAL REPOSITORY, AND IT IS NOT FOR USE.**
>
> It is a research scaffold and one person's working tree. Nothing here is
> released, supported, stable or reviewed. There is **no soundness proof**;
> the checker it holds is **generated and unverified**; names and interfaces
> change without notice, and the generated session is replaced wholesale on
> every install. **Nothing in this tree should be relied on to establish that
> any proof is correct.** See [Status](#status) for what is and is not here.

## An Isabelle/HOL Proof Checker for SMT

iogos is the Isabelle/HOL counterpart of
[Logos](https://github.com/ajreynol/logos), the verified SMT proof checker
written in Lean. It holds an executable proof checker for the Cooperating Proof
Calculus (CPC), together with the soundness scaffolding that a proof
development about that checker starts from.

The checker is not written by hand. It is compiled from the definition of CPC
written in *Eunoia*, the logical framework of the proof checker
[Ethos](https://github.com/cvc5/ethos), in which proof calculi are defined as
*signatures*. CPC is the signature cvc5 emits its proofs in, maintained at
https://github.com/cvc5/cvc5/blob/main/proofs/eo/cpc/Cpc.eo. The compilation is
performed by the Eunoia compiler `ethos-eoc` and its `isabelle-meta` backend,
documented at https://github.com/cvc5/ethos/blob/main/tools/eoc/README.md.

**This repository is currently scaffolding.** The calculus itself has not been
installed yet: `Cpc/` arrives from the first run of the installer described in
[Receiving a generated calculus](#receiving-a-generated-calculus), and is
committed here once it does.

## Status

The Isabelle backend is at its initial stage, and this repository inherits its
boundaries. What arrives is:

- an executable checker for the whole CPC signature, `Cpc_Checker.thy`;
- one proof obligation per rule plus a soundness predicate, `Cpc_Spec.thy`.

What is *not* here, and is future work:

- **no soundness proof.** `Cpc_Spec` states obligations against a supplied
  interpretation; it does not discharge them and does not assert that the
  checker is sound.
- **no SMT-LIB model semantics.** Logos has one (`Cpc/SmtModel.lean`); the
  Isabelle backend does not consume the `model-smt` stage yet, so there is
  nothing here yet for the obligations to be stated against.
- **no proof-file parser.** The Lean checker accepts Ethos s-expression proof
  files; here a proof is applied as a `CCmdList` term inside Isabelle.
- **no executable, no regression suite**, and no cut-down `CpcMini`-style
  session for developing proofs against.

## Requirements

- **Isabelle**, to build what is installed. Tested with **Isabelle2025-2**.
  Nothing here needs Isabelle in order to *generate* or *install* a calculus --
  only to build one.
- An **Ethos checkout** with `ethos-eoc` built, to regenerate the calculus. See
  [Receiving a generated calculus](#receiving-a-generated-calculus).

The scripts find Isabelle through `$ISABELLE`, then `isabelle` on `PATH`, then
`~/isabelle/bin/isabelle`.

## Building

```bash
scripts/build.sh
```

That is `isabelle build -D .` over every session this tree registers in
`ROOTS`, and any extra arguments are passed through to `isabelle build`:

```bash
scripts/build.sh -j 2 -o threads=2
```

Building the full CPC session is substantial; bounding the job and thread
counts is worthwhile on a machine with limited memory.

## Receiving a generated calculus

The calculus is installed by `tools/eoc/cpc/install_iogos` in the Ethos
checkout, which compiles the entire CPC signature and copies the session it
publishes into this tree. Run it through the wrapper:

```bash
scripts/install.sh
```

The wrapper points the installer at this repository and otherwise stays out of
the way; every `EOC_*` setting the installer documents still applies. The ones
that matter most here:

| Variable | Meaning |
| --- | --- |
| `ETHOS_DIR` | the Ethos checkout (default `~/ethos`) |
| `BUILD_DIR` | where `ethos-eoc` is built (default `$ETHOS_DIR/build-eoc`) |
| `EOC_NO_BUILD=1` | do not rebuild `ethos-eoc` first |
| `EOC_CPC_INPUT` | the CPC signature to compile (default: a sibling `cvc5-ajr` checkout, else `~/cvc5/proofs/eo/cpc/Cpc.eo`) |
| `EOC_SEMANTICS` | the signature saying what CPC's symbols mean to the model |

For example, against an already-built compiler:

```bash
EOC_NO_BUILD=1 scripts/install.sh
```

### What the run writes

The installer generates first and copies second, so a failed generation leaves
the previously installed calculus untouched. On success it writes:

- `Cpc/ROOT`, declaring `session Cpc = HOL +` with `Cpc_Spec` as its theory;
- `Cpc/Cpc_Checker.thy` and `Cpc/Cpc_Spec.thy`, each under an installation
  banner naming where it came from;
- a `Cpc` line in `ROOTS`, added once, preserving the entries already there.

Running it again replaces exactly those files. Any other file under `Cpc/` is
left alone, but this tree keeps handwritten theories in sessions of their own
rather than relying on that -- see [Layout](#layout).

The generated theories contain no `sorry` and no termination axioms.

### Committing what arrives

The generated session is committed, exactly as Logos commits its generated
Lean: it is what makes this repository readable and buildable without running
the compiler. So a regeneration is a reviewable diff. Commit `Cpc/` and the
`ROOTS` line together, and say in the message which CPC revision was compiled.

## Layout

| Path | Written by | Contents |
| --- | --- | --- |
| `Cpc/` | `scripts/install.sh` | the generated CPC checker and its obligations |
| `ROOTS` | partly the installer | the sessions this tree offers `isabelle build -D .` |
| `Soundness/` | by hand | the soundness development over the generated session |
| `scripts/` | by hand | the install and build wrappers |
| `docs/` | by hand | notes, and [`docs/discussions.md`](docs/discussions.md) |

What we would like the compiler to generate differently, and why, is collected
in [`docs/discussions.md`](docs/discussions.md). The largest item is that the
Isabelle backend emits one 2.1 MB theory where the Lean backend emits one
module per rule.

Nothing handwritten belongs in `Cpc/`: that directory is regenerated in its
entirety, and a session that is replaced wholesale is a poor place to keep a
proof. Handwritten theories go in a session of their own whose parent is `Cpc`,
as `Soundness` is.

## The generated interface

Generated names preserve underscores and turn hyphens, dots, and colons into
underscores. Programs drop the compiler's `$eo_prog_`, `$eo_`, or leading `$`
wrapper and take a `p_` prefix: `$eo_prog_arith-elim-int-gt` becomes
`p_arith_elim_int_gt`, with `obligation_arith_elim_int_gt` in the specification.
Common symbolic operators get word names, such as `Term_Op_eq` and
`Term_Op_implies`. Other punctuation uses readable markers (`at_`, `dollar_`)
or `_xhh` byte escapes. Numeric suffixes distinguish names that would otherwise
collide; rule programs receive their names before helpers.
Constructors carry their datatype's name (`CRule_contra`, `Term_Apply`), and
signature symbols get `Term_Op_` abbreviations, which is what keeps a user
operator named `Stuck` distinct from `Term_Stuck`.

### Running the checker

```isabelle
check_refutation :: "nat => CArgList => CCmdList => bool"
```

`check_refutation fuel assumptions commands` accepts exactly when the commands
refute the assumptions. `fuel` bounds the *depth of program calls* rather than
total work, and every generated program returns an option, so exhausting the
budget propagates `None` -- it can never be mistaken for acceptance. The public
checker accepts only `Some True`. EO evaluation failure is a separate outcome,
`Some Term_Stuck`.

A proof is a `CCmdList` of `CCmd_assume_push`, `CCmd_check_proven`, `CCmd_step`
and `CCmd_step_pop` (under their encoded names), and closed goals are decided
by `eval`:

```isabelle
lemma "check_refutation 100 assumptions contradiction"
  by eval
```

### The obligations

`Cpc_Spec` defines, for each rule, an `obligation_<rule>` predicate: that
whenever the rule's program returns a result and that result is not
`Term_Stuck`, the result is `valid`. `valid` is a parameter -- the
interpretation of terms, and the premises each obligation holds under, belong
to the importing theory. It also defines

```isabelle
checker_sound_for unsatisfiable =
  (ALL fuel assumptions commands.
    check_refutation fuel assumptions commands --> unsatisfiable assumptions)
```

and `checked_refutation`, which applies it. These are where a soundness
development starts. They assert nothing on their own.

## Related

- [Logos](https://github.com/ajreynol/logos) -- the Lean checker, further along
- [Ethos](https://github.com/cvc5/ethos) -- Eunoia, `ethos-eoc`, and the
  `isabelle-meta` backend
- [cvc5](https://github.com/cvc5/cvc5) -- the solver whose proofs CPC describes
