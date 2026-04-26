#let sansfont = ($for(sansfont)$"$sansfont$",$endfor$)

$if(citations)$
$if(citeproc)$
$-- citeproc: pandoc embeds the formatted bibliography in the body; style it here. --$
// The pandoc-generated bibliography is a #block[...] <refs> at the very end.
// Apply hanging indent and ragged-right to all block content from here onward.
#show block: set par(
  hanging-indent: 1em,
  first-line-indent: 0pt,
  justify: false,
)
#show block: set text(font: sansfont)
$else$
$if(csl)$
#set bibliography(style: "$csl$")
$elseif(bibliographystyle)$
#set bibliography(style: "$bibliographystyle$")
$endif$

$if(suppress-bibliography)$
// Citations are rendered inline (e.g. citation-location: margin).
// #bibliography() must still be called so Typst can resolve #cite() keys,
// but we hide its rendered output.
#show bibliography: none
$if(bibliography)$
#bibliography($for(bibliography)$"$bibliography$"$sep$,$endfor$)
$endif$
$else$
// Reset the footnote-to-sidenote conversion so bibliography entries rendered
// as footnotes by note-style CSLs (e.g. Chicago Notes) stay in the body column.
#show footnote: it => it
#show footnote.entry: it => it
#heading(level:1, [References])
#show bibliography: set text(font: sansfont)
#show bibliography: set par(justify: false)
#set bibliography(title: none)
$if(bibliography)$
#bibliography($for(bibliography)$"$bibliography$"$sep$,$endfor$)
$endif$
$endif$
$endif$
$endif$
