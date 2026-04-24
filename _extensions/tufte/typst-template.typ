#let tufte(
  title: none,
  subtitle: none,
  shorttitle: none,
  document-number: none,
  authors: none,
  date: datetime.today(),
  abstract: none,
  publisher: none,
  abstract-title: none,
  margin: (left: 1in, right: 3.5in, y: 1.5in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: (),
  mainfont: "serif",
  CJKmainfont: none,
  fontsize: 11pt,
  codefont: "DejaVu Sans Mono",
  sansfont: "Gill Sans MT",
  CJKsansfont: none,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  draft: false,
  footer-content: none,
  distribution: none,
  doc,
) = {

  // Document metadata
  if authors != none {
    set document(
      title: title,
      author: authors.map(author => to-string(author.name)),
    )
  } else {
    set document(title: title)
  }

  // Define body fonts with CJK fallbacks
  let body-font = if CJKmainfont != none {
    (mainfont, CJKmainfont)
  } else {
    mainfont
  }

  let body-sansfont = if CJKsansfont != none {
    (sansfont, CJKsansfont)
  } else {
    sansfont
  }

  // Just a suttle lightness to decrease the harsh contrast
  set text(fill: luma(30))

  // Tables and figures
  show figure: set figure.caption(separator: [.#h(0.5em)])
  show figure.caption: set align(left)
  show figure.caption: set text(font: body-sansfont)

  // Breathing room around all floats.
  // Plain figures: v() is placed in the document flow by this show rule.
  // Wideblock figures: the wideblock wrapper provides external v(); its inner
  //   show rule overrides this one to identity to avoid double-spacing.
  show figure: it => {
    v(2em, weak: true)
    it
    v(1.5em, weak: true)
  }

  show figure.where(kind: table): set figure.caption(position: top)
  show figure.where(kind: table): set figure(numbering: "I")
  show figure.where(kind: "quarto-float-tbl"): set figure.caption(position: top)
  show figure.where(kind: "quarto-float-tbl"): set figure(numbering: "I")

  show figure.where(kind: image): set figure(
    supplement: [Figure],
    numbering: "1",
  )
  show figure.where(kind: "quarto-float-fig"): set figure(
    supplement: [Figure],
    numbering: "1",
  )

  show figure.where(kind: raw): set figure.caption(position: top)
  show figure.where(kind: raw): set figure(supplement: [Code], numbering: "1")
  show raw: set text(font: codefont, size: 10pt)

  // Equations
  set math.equation(numbering: "(1)")
  show math.equation: set block(spacing: 1.2em)

  show link: underline

  // Lists
  set enum(
    indent: 1em,
    body-indent: 1em,
  )
  show enum: set par(justify: false)
  set list(
    indent: 1em,
    body-indent: 1em,
  )
  show list: set par(justify: false)

  // Headings
  set heading(numbering: none)
  show heading.where(level: 1): it => {
    v(2em, weak: true)
    text(size: 14pt, weight: "bold", font: body-sansfont, it)
    v(1em, weak: true)
  }

  show heading.where(level: 2): it => {
    v(1.3em, weak: true)
    text(size: 13pt, weight: "regular", style: "italic", font: body-sansfont, it)
    v(1em, weak: true)
  }

  show heading.where(level: 3): it => {
    v(1em, weak: true)
    text(size: fontsize, style: "italic", weight: "light", font: body-sansfont, it)
    v(0.65em, weak: true)
  }

  // show heading: it => {
  //   if it.level <= 3 {
  //     it
  //   } else { }
  // }

  // Page setup
  // Suppress footnote separator — footnotes are rendered as margin notes,
  // but the Typst engine still draws the separator rule before hidden entries.
  set footnote.entry(separator: [])

  set page(
    paper: "us-letter",
    header: context {
      let r = marginalia.get-right()
      set text(font: body-sansfont)
      block(
        width: 100% + r.sep + r.width,
        {
          if counter(page).get().first() > 1 {
            if document-number != none {
              document-number
            }
            h(1fr)
            if shorttitle != none {
              shorttitle
            } else {
              title
            }
            if publisher != none {
              linebreak()
              h(1fr)
              publisher
            }
          }
        },
      )
    },
    footer: context {
      let r = marginalia.get-right()
      set text(font: body-sansfont, size: 8pt)
      block(
        width: 100% + r.sep + r.width,
        {
          if counter(page).get().first() == 1 {
            if type(footer-content) == array {
              footer-content.at(0)
              linebreak()
            } else {
              footer-content
              linebreak()
            }
            if draft [
              Draft document, #date.
            ]
            if distribution != none [
              Distribution limited to #distribution.
            ]
            linebreak()
            [#h(1fr)#counter(page).display()]
          } else {
            if type(footer-content) == array {
              footer-content.at(1)
              linebreak()
            } else {
              footer-content
              linebreak()
            }
            if draft [
              Draft document, #date.
            ]
            if distribution != none [
              Distribution limited to #distribution.
            ]
            linebreak()
            [#h(1fr)#counter(page).display()]
          }
        },
      )
    },
    background: if draft {
      rotate(
        45deg,
        text(font: body-sansfont, size: 200pt, fill: rgb("FFEEEE"))[DRAFT],
      )
    },
  )

  set par(
    // justify: true,
    leading: 0.65em,
    first-line-indent: 1em,
    spacing: 0.65em
  )


  // frontmatter
  if title != none {
    wideblock(_template: true, {
      set text(
        hyphenate: false,
        size: 20pt,
        font: body-sansfont,
      )
      set par(
        justify: false,
        leading: 0.2em,
        first-line-indent: 0pt,
      )
      title
      set text(size: fontsize)
      v(-0.2em)
      text(style: "italic", subtitle)
    })
  }

  if authors != none {
    wideblock(_template: true, {
      set text(font: body-sansfont, size: fontsize)
      v(1em)
      for i in range(calc.ceil(authors.len() / 3)) {
        let end = calc.min((i + 1) * 3, authors.len())
        let is-last = authors.len() == end
        let slice = authors.slice(i * 3, end)
        grid(
          columns: slice.len() * (1fr,),
          gutter: fontsize,
          ..slice.map(author => align(
            left,
            {
              upper(author.name)
              if "university" in author [
                \ #author.university
              ]
              if "email" in author [
                \ #to-string(author.email)
              ]
            },
          ))
        )

        if not is-last {
          v(16pt, weak: true)
        }
      }
    })
    v(1em)
  }

  if date != none {
    set text(font: body-sansfont)
    date
    linebreak()
    if document-number != none {
      document-number
    }
    v(1em)
  }

  if abstract != none {
    wideblock(_template: true, {
      set text(font: body-sansfont)
      // Each paragraph gets a 3em left indent. Uses first-line-indent so that
      // every paragraph (not just the first) is uniformly indented, matching
      // the pull-quote style across multi-paragraph abstracts.
      set par(first-line-indent: 0pt, hanging-indent: 0pt)
      pad(left: 3em, abstract)
    })
  }

  if toc {
    wideblock(_template: true, {
      v(1em)
      set text(font: body-sansfont)
      outline(indent: 1em, title: none, depth: 2)
    })
  }

  // Body text - fonts already defined above
  set text(
    lang: lang,
    region: region,
    font: body-font,
    style: "normal",
    weight: "regular",
    hyphenate: true,
    size: fontsize,
  )

  doc

}

#set table(
  inset: 6pt,
  stroke: none,
)
