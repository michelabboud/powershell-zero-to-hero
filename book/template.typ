// Reusable book layout. All publication metadata arrives from book.json via
// the build script and Typst inputs; this file intentionally owns no metadata.

#let blockquote(body) = {
  v(2pt)
  block(
    width: 100%,
    fill: rgb("#F8FAFC"),
    stroke: (left: 3pt + rgb("#94A3B8")),
    radius: 2pt,
    inset: (x: 12pt, y: 8pt),
    text(style: "italic", fill: rgb("#475569"), body),
  )
  v(2pt)
}

#let horizontalrule = {
  v(4pt)
  line(length: 100%, stroke: 0.5pt + rgb("#CBD5E1"))
  v(4pt)
}

#let book(
  title: none,
  author: none,
  version: none,
  credit: none,
  front-cover: none,
  back-cover: none,
  body,
) = {
  set document(title: title, author: (author,))
  set page(paper: "us-letter", margin: (x: 0.8in, y: 0.75in), numbering: "1")
  set par(justify: true, leading: 0.65em)
  set text(font: "Libertinus Serif", size: 10pt)
  show heading.where(level: 1): set text(size: 20pt, weight: "bold", fill: rgb("#172554"))
  show heading.where(level: 2): set text(size: 15pt, weight: "bold", fill: rgb("#1E3A8A"))

  page(margin: 0pt, numbering: none)[
    #align(center + horizon)[#front-cover]
  ]

  page(numbering: none)[
    #align(center + horizon)[
      #text(size: 27pt, weight: "bold", fill: rgb("#172554"))[#title]
      #v(18pt)
      #text(size: 16pt)[#author]
      #v(10pt)
      #text(size: 11pt)[Version #version]
      #v(8pt)
      #text(size: 11pt, fill: rgb("#475569"))[#credit]
    ]
  ]

  body

  page(margin: 0pt, numbering: none)[
    #align(center + horizon)[#back-cover]
  ]
}
