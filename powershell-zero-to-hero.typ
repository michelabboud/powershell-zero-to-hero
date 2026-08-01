#import "book/template.typ": book, blockquote, horizontalrule

#let edition = sys.inputs.at("edition")
#let title = sys.inputs.at("title")
#let author = sys.inputs.at("author")
#let version = sys.inputs.at("version")
#let credit = sys.inputs.at("credit")
#let front-cover = image(sys.inputs.at("front-cover"), width: 100%, height: 100%, fit: "cover")
#let back-cover = image(sys.inputs.at("back-cover"), width: 100%, height: 100%, fit: "cover")

#show: book.with(
  title: title,
  author: author,
  version: version,
  credit: credit,
  front-cover: front-cover,
  back-cover: back-cover,
)

#if edition == "main" {
  include "build/main-body.typ"
} else if edition == "answers" {
  include "build/answers-body.typ"
} else {
  panic("edition must be main or answers")
}
