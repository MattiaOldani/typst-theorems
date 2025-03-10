// Setup

#let thmcounters = state(
  "thm",
  (
    "counters": ("heading": ()),
    "latest": (),
  ),
)


#let thmenv(identifier, base, base_level, fmt) = {
  let global_numbering = numbering

  return (
    ..args,
    body,
    number: auto,
    numbering: "1.1",
    refnumbering: auto,
    supplement: identifier,
    base: base,
    base_level: base_level,
  ) => {
    let name = none

    if args != none and args.pos().len() > 0 {
      name = args.pos().first()
    }

    if refnumbering == auto {
      refnumbering = numbering
    }

    let result = none

    if number == auto and numbering == none {
      number = none
    }

    if number == auto and numbering != none {
      result = context {
        let heading-counter = counter(heading).get()
        return thmcounters.update(thmpair => {
          let counters = thmpair.at("counters")

          counters.at("heading") = heading-counter

          if not identifier in counters.keys() {
            counters.insert(identifier, (0,))
          }

          let tc = counters.at(identifier)

          if base != none {
            let bc = counters.at(base)

            if base_level != none {
              if bc.len() < base_level {
                bc = bc + (0,) * (base_level - bc.len())
              } else if bc.len() > base_level {
                bc = bc.slice(0, base_level)
              }
            }

            if tc.slice(0, -1) == bc {
              counters.at(identifier) = (..bc, tc.last() + 1)
            } else {
              counters.at(identifier) = (..bc, 1)
            }
          } else {
            counters.at(identifier) = (tc.last() + 1,)

            let latest = counters.at(identifier)
          }

          let latest = counters.at(identifier)

          return (
            "counters": counters,
            "latest": latest,
          )
        })
      }

      number = context {
        global_numbering(numbering, ..thmcounters.get().at("latest"))
      }
    }

    return figure(
      result
        + // hacky!
        fmt(name, number, body, ..args.named())
        + [#metadata(identifier) <meta:thmenvcounter>],
      kind: "thmenv",
      outlined: false,
      caption: name,
      supplement: supplement,
      numbering: refnumbering,
    )
  }
}


#let thmbox(
  identifier,
  head,
  ..blockargs,
  supplement: auto,
  padding: (top: 0.5em, bottom: 0.5em),
  namefmt: x => [(#emph(x))],
  titlefmt: strong,
  bodyfmt: x => x,
  separator: [#h(0.1em):#h(0.2em)],
  base: "heading",
  base_level: none,
) = {
  if supplement == auto {
    supplement = head
  }

  let boxfmt(name, number, body, title: auto, ..blockargs_individual) = {
    if not name == none {
      name = [ #namefmt(name)]
    } else {
      name = []
    }

    if title == auto {
      title = head
    }

    if not number == none {
      title += " " + number
    }

    title = titlefmt(title)
    body = bodyfmt(body)

    pad(
      ..padding,
      block(
        width: 100%,
        inset: 1.2em,
        radius: 0.3em,
        breakable: true,
        ..blockargs.named(),
        ..blockargs_individual.named(),
        [#title#name#separator#body],
      ),
    )
  }

  return thmenv(
    identifier,
    base,
    base_level,
    boxfmt,
  ).with(supplement: supplement)
}


#let thm-qed-done = state("thm-qed-done", false)

#let thm-qed-symbol = state("thm-qed-symbol", $qed$)

#let thm-qed-show = {
  thm-qed-done.update(true)
  context [#thm-qed-symbol.get()]
}

#let qedhere = metadata("thm-qedhere")

#let thm-has-qedhere(x) = {
  if x == "thm-qedhere" {
    return true
  }

  if type(x) == content {
    for (f, c) in x.fields() {
      if thm-has-qedhere(c) {
        return true
      }
    }
  }

  if type(x) == array {
    for c in x {
      if thm-has-qedhere(c) {
        return true
      }
    }
  }

  return false
}


#let proof-bodyfmt(body) = {
  thm-qed-done.update(false)
  body
  context {
    if thm-qed-done.at(here()) == false {
      h(1fr)
      thm-qed-show
    }
  }
}


#let thmproof(..args) = thmbox(
  ..args,
  namefmt: emph,
  bodyfmt: proof-bodyfmt,
  ..args.named(),
)


#let thmrules(qed-symbol: $qed$, doc) = {
  show figure.where(kind: "thmenv"): set block(breakable: true)
  show figure.where(kind: "thmenv"): set align(start)
  show figure.where(kind: "thmenv"): it => it.body

  show ref: it => {
    if it.element == none {
      return it
    }

    if it.element.func() != figure {
      return it
    }

    if it.element.kind != "thmenv" {
      return it
    }

    let supplement = it.element.supplement

    if it.citation.supplement != none {
      supplement = it.citation.supplement
    }

    let loc = it.element.location()
    let thms = query(selector(<meta:thmenvcounter>).after(loc))
    let number = thmcounters.at(thms.first().location()).at("latest")

    return link(
      it.target,
      [#supplement~#numbering(it.element.numbering, ..number)],
    )
  }

  show math.equation.where(block: true): eq => {
    if thm-has-qedhere(eq) and thm-qed-done.at(eq.location()) == false {
      grid(
        columns: (1fr, auto, 1fr),
        [], eq, align(right + horizon)[#thm-qed-show],
      )
    } else {
      eq
    }
  }

  show enum.item: it => {
    show metadata.where(value: "thm-qedhere"): {
      h(1fr)
      thm-qed-show
    }
    it
  }

  show list.item: it => {
    show metadata.where(value: "thm-qedhere"): {
      h(1fr)
      thm-qed-show
    }
    it
  }

  thm-qed-symbol.update(qed-symbol)

  doc
}


// Elementi

#let theorem = thmbox(
  "teorema",
  "Teorema",
  fill: rgb("#F9C8D5"),
)

#let theorem-proof = thmproof(
  "dimostrazione",
  "Dimostrazione",
  base: "teorema",
  fill: rgb("#CDE5F7"),
)

#let corollary = thmbox(
  "corollario",
  "Corollario",
  base: "teorema",
  fill: rgb("#F9C8D5"),
)

#let corollary-proof = thmproof(
  "dimostrazione",
  "Dimostrazione",
  base: "corollario",
  fill: rgb("#CDE5F7"),
)

#let lemma = thmbox(
  "lemma",
  "Lemma",
  fill: rgb("#F9C8D5"),
)

#let lemma-proof = thmproof(
  "dimostrazione",
  "Dimostrazione",
  base: "lemma",
  fill: rgb("#CDE5F7"),
)

#let definition = thmbox(
  "definizione",
  "Definizione",
  fill: rgb("#FFF8D1"),
)

#let example = thmbox(
  "esempio",
  "Esempio",
  fill: rgb("#C4ECD1"),
)

#let exercise = thmbox(
  "esercizio",
  "Esercizio",
  fill: rgb("#53EC53"),
)

#let request = thmbox(
  "richiesta",
  "Richiesta",
  base: "esercizio",
  fill: rgb("#C4ECD1"),
)

#let solution = thmbox(
  "soluzione",
  "Soluzione",
  base: "esercizio",
  fill: rgb("#DFFFE0"),
)
