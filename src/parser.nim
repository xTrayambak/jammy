import std/strutils
import ./tokenizer
import pretty

type
  Tag* = enum
    tHeader
    tH1
    tA
    tP
    tDL
    tDT
    tNextid
    tTitle
    tHead
    tMeta
    tDD
    tH
    tBody
    tHTML

  Element* = ref object
    tag*: Tag
    attributes*: seq[Attribute]
    text*: string
    children*: seq[Element]

  Document* = ref object
    children*: seq[Element]

  Parser* = ref object
    curr: int = -1
    tokens*: seq[Token]
    doc*: Document

proc `&=`*(doc: Document, child: Element) =
  doc.children &= child

proc toTag*(tag: string): Tag =
  case tag.toLowerAscii()
  of "header": tHeader
  of "h1": tH1
  of "a": tA
  of "p": tP
  of "dl": tDL
  of "meta": tMeta
  of "nextid": tNextid
  of "h": tH
  of "dt": tDT
  of "dd": tDD
  of "head": tHead
  of "body": tBody
  of "html": tHtml
  of "title": tTitle
  else:
    assert off, tag
    tDL

proc eof*(parser: Parser): bool =
  parser.curr >= parser.tokens.len - 1

proc next*(parser: Parser, steps: int = 1): Token =
  parser.tokens[parser.curr + steps]

proc forward*(parser: Parser) =
  inc parser.curr

proc behind*(parser: Parser) =
  dec parser.curr

proc prev*(parser: Parser, steps: int = 1): Token =
  parser.tokens[parser.curr - steps]

proc parseAttributes*(parser: Parser): seq[Attribute] =
  var attrs: seq[Attribute]

  while not parser.eof:
    let name = parser.next()
    if name.kind != tkIdent: break

    parser.forward()
    if parser.next().kind != tkEquals: parser.behind(); break
    parser.forward()

    let value = parser.next()
    if value.kind != tkString: parser.behind(); break

    attrs.add(Attribute(name: name.ident, value: value.str))
    parser.forward()

  attrs

proc parseText*(parser: Parser): string =
  var buff: string
  while not parser.eof:
    let next = parser.next()
    if next.kind == tkIdent:
      buff &= next.ident & ' '
    else:
      break

    parser.forward()

  buff

proc parseTag*(parser: Parser): Element =
  var elem = Element()
  let name = parser.next()
  assert name.kind == tkIdent
  elem.tag = name.ident.toTag()
  parser.forward()

  # parse attributes
  elem.attributes = parser.parseAttributes()

  # parse text content if not a void element or legacy element
  if elem.tag in [tMeta, tNextid]:
    return elem
  
  elem.text = parser.parseText()

  elem

proc parse*(parser: Parser): Document =
  while not parser.eof:
    print parser.doc
    let token = parser.next()
    parser.forward()

    case token.kind
    of tkBlockOpen:
      parser.doc &= parser.parseTag()
    of tkBlockClose, tkIdent: discard
    else: print token; assert off

  parser.doc

proc newParser*(tokens: seq[Token]): Parser =
  Parser(doc: Document(), tokens: tokens)
