#let sansfont = ($for(sansfont)$"$sansfont$",$endfor$)

$if(citations)$
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
#heading(level:1, [References])
#show bibliography: set text(font: sansfont)
#show bibliography: set par(justify: false)
#set bibliography(title: none)
$if(bibliography)$
#bibliography($for(bibliography)$"$bibliography$"$sep$,$endfor$)
$endif$
$endif$
$endif$
