import std/[strutils]
import pretty

type
  TokenKind* = enum
    tkBlockOpen
    tkIdent
    tkEquals
    tkBlockClose
    tkText
    tkString

  Attribute* = ref object
    name*: string
    value*: string

  Token* = ref object
    case kind*: TokenKind
    of tkBlockOpen, tkBlockClose, tkEquals: discard
    of tkIdent:
      ident*: string
    of tkString:
      str*: string
    of tkText: 
      content*: string

  Tokenizer* = ref object
    source: string
    pos: int = -1

proc next*(tokenizer: Tokenizer): char =
  inc tokenizer.pos
  tokenizer.source[tokenizer.pos]

proc eof*(tokenizer: Tokenizer): bool {.inline.} =
  tokenizer.pos >= tokenizer.source.len - 1

proc consumeUntilFound*(tokenizer: Tokenizer, terminators: seq[char]): string =
  var buffer: string

  while not tokenizer.eof:
    var terminate = false
    let c = tokenizer.next()
    
    for t in terminators:
      if t == c: terminate = true; break
    
    if terminate: break
    buffer &= c
  
  buffer

proc consumeUntilAvailable*(tokenizer: Tokenizer, needed: set[char]): string =
  var buff: string

  while not tokenizer.eof:
    let c = tokenizer.next()

    if c notin needed:
      dec tokenizer.pos
      break

    buff &= c

  buff

proc nextToken*(tokenizer: Tokenizer): Token =
  let c = tokenizer.next()

  case c
  of '<':
    if not tokenizer.eof() and tokenizer.deepcopy().next() == '/':
      tokenizer.pos += 1 # />
      return Token(kind: tkBlockClose)

    return Token(kind: tkBlockOpen)
  of {'a' .. 'z'}, {'A' .. 'Z'}:
    var buff: string
    buff &= c

    while not tokenizer.eof:
      let v = tokenizer.next()
      if v notin {'a'..'z'} and v notin {'A'..'Z'} and v notin ['-', '\'', '"']: dec tokenizer.pos; break

      buff &= v

    return Token(kind: tkIdent, ident: buff)
  of '=':
    return Token(kind: tkEquals)
  of '"':
    var txt: string
    while not tokenizer.eof:
      let c = tokenizer.next()
      if c == '"': break

      txt &= c

    return Token(kind: tkString, str: txt)
  else: discard

proc tokenize*(tokenizer: Tokenizer): seq[Token] =
  var tokens: seq[Token]

  while not tokenizer.eof:
    let tok = tokenizer.nextToken()
    if tok != nil:
      tokens &= tok

  tokens

proc newTokenizer*(source: string): Tokenizer =
  Tokenizer(source: source, pos: -1)
