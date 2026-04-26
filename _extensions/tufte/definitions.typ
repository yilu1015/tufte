#let to-string(content) = {
  if content.has("text") {
    content.text
  } else if content.has("children") {
    content.children.map(to-string).join("")
  } else if content.has("body") {
    to-string(content.body)
  } else if content == [ ] {
    " "
  }
}

#let to-label(string) = {
  label("<" + string + ">")
}

// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): block.with(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#show raw.where(block: true): set align(left)

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block,
    block_with_new_content(
      old_title_block.body,
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    new_title_block +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false,
    fill: background_color,
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"),
    width: 100%,
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%,
      below: 0pt,
      block(
        fill: background_color,
        width: 100%,
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt,
          width: 100%,
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}


// pandoc handling
$if(sansfont)$
  #let sansfont = ($for(sansfont)$"$sansfont$",$endfor$)
$else$
  #let sansfont = "Gill Sans MT"
$endif$

$if(margin-geometry)$
// Margin layout support using marginalia package.
// wideblock and note are intentionally NOT in the named imports — our custom
// wrappers below take precedence for all calls in the document.
// notefigure IS imported directly; we handle its spacing via show rules below.
#import "@preview/marginalia:0.3.1" as marginalia: notefigure

// Shadow marginalia.note: override the default par-style to force ragged-right
// text inside all margin notes (narrow column width makes justification look poor).
#let note(
  par-style: (spacing: 1.2em, leading: 0.5em, hanging-indent: 0pt, justify: false),
  ..args
) = {
  marginalia.note(par-style: par-style, ..args)
}

// Prevent notefigure's two internal [#metadata(...)] block anchors from creating
// extra par.spacing in the body column when notefigure is called between
// blank-line-separated paragraphs (which puts it in block context).
// Converting them to zero-size blocks with explicit above/below: 0pt removes
// their layout contribution while keeping them visible to marginalia's queries.
#show <_marginalia_notefigure>: it => block(
  width: 0pt, height: 0pt, above: 0pt, below: 0pt, it
)
#show <_marginalia_notefigure_meta>: it => block(
  width: 0pt, height: 0pt, above: 0pt, below: 0pt, it
)

// Shadow marginalia.wideblock.
// - Document-level calls (Quarto-generated .column-page-right divs): adds external
//   v(2em)/v(1.5em) around the wideblock.  Inside the wideblock, the figure show
//   rule is overridden to an identity transform so external spacing isn't doubled.
// - Template-internal calls (title, abstract, …): pass _template: true to omit
//   the extra spacing (those blocks manage their own vertical rhythm manually).
#let wideblock(side: auto, _template: false, body) = {
  if _template {
    marginalia.wideblock(side: side, body)
  } else {
    v(2em, weak: true)
    marginalia.wideblock(side: side, {
      // Suppress the outer figure show rule inside the wideblock; the external
      // v() above/below is sufficient and avoids double-spacing.
      show figure: it => it
      body
    })
    v(1.5em, weak: true)
  }
}

// Render footnote as margin note using standard footnote counter
#let column-sidenote(body) = {
  context {
    let num = counter(footnote).display("1")
    super(num)
    note(
      alignment: "baseline",
      shift: auto,
      counter: none,
    )[
      #super(num) #body
    ]
  }
}
$endif$
