theory Soundness
  imports "Cpc.Cpc_Spec"
begin

text \<open>
  The soundness development over the generated CPC checker. This session is
  written by hand in \<^verbatim>\<open>Cpc/Soundness/\<close>, alongside the generated
  checker but in a separate session whose parent is \<^verbatim>\<open>Cpc\<close>.
  The installer replaces the generated session's ROOT and top-level theory
  files; it preserves this handwritten subdirectory.

  Nothing is proven here yet. What \<^verbatim>\<open>Cpc_Spec\<close> supplies is the
  starting point rather than the result: an obligation per rule, stated against
  a \<^verbatim>\<open>valid\<close> predicate it leaves as a parameter, and
  \<^verbatim>\<open>checker_sound_for\<close>, which says what discharging them all would
  amount to. Neither asserts that the checker is sound.

  Two things are needed before an obligation can be stated, let alone proven,
  and the first is not a proof at all:

    \<^item> an interpretation of the term datatype --- a definition in HOL of
      what an SMT-LIB term means, independent of the checker, which is what
      supplies \<^verbatim>\<open>valid\<close> and what \<^verbatim>\<open>unsatisfiable\<close> in
      \<^verbatim>\<open>checker_sound_for\<close> ranges over. The Lean checker Logos has
      one, \<^verbatim>\<open>Cpc/SmtModel.lean\<close>, compiled from the same
      Eunoia semantics by the \<^verbatim>\<open>model-smt\<close> stage. The
      Isabelle backend does not consume that stage yet, so there is as yet
      nothing here for an obligation to be about.

    \<^item> the premises each rule holds under. An obligation as generated is
      unconditional in its arguments; a rule that is sound only for
      well-sorted, well-scoped arguments needs those stated, and where they are
      stated is here.

  Until the first of those lands, this theory is a placeholder that keeps the
  session buildable and marks where the development goes.
\<close>

end
