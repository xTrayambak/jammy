import std/[tables, strutils]
import pixie, pretty
import ./[parser]

type
  BoxKind* = enum
    bxText

  Box* = ref object
    position*: Vec2
    dims*: Vec2

    case kind*: BoxKind # I love ADTs :)
    of bxText:
      text*: string
      sizePx*: int
      isAnchor*: bool = false

var
  WordLengths: Table[string, int]
  WordHeights: Table[string, int]

proc getWordLength*(font: Font, word: string): int =
  var length: int

  if not WordLengths.contains(word):
    length = font.layoutBounds(word).x.int
    WordLengths[word] = length
  else:
    length = WordLengths[word]

  length

proc getWordHeight*(font: Font, word: string): int =
  var height: int

  if not WordHeights.contains(word):
    height = font.layoutBounds(word).y.int
    WordHeights[word] = height
  else:
    height = WordLengths[word]

  height

proc constructBoxes*(document: Document, font: Font, viewport: Vec2): seq[Box] =
  var cursor = vec2(0, 0)
  var boxes: seq[Box]

  for child in document.children:
    # since we parse everything into a top-down document, this should be a bit simpler.

    case child.tag
    of tH:
      for word in child.text.split(' '):
        let dims = vec2(getWordHeight(font, word).float, getWordLength(font, word).float)
        boxes &= Box(kind: bxText, text: word, position: cursor, sizePx: 32, dims: dims)

        cursor = vec2(cursor.x + dims.x, cursor.y)
        if cursor.x >= viewport.x:
          cursor = vec2(0f, cursor.y + viewport.y)
    of tA: 
      for word in child.text.split(' '):
        let dims = vec2(getWordHeight(font, child.text).float, getWordLength(font, child.text).float)
        boxes &= Box(kind: bxText, text: word, position: cursor, sizePx: 12, isAnchor: true, dims: dims)

        cursor = vec2(cursor.x + dims.x, cursor.y)
        if cursor.x >= viewport.x:
          cursor = vec2(0f, cursor.y + viewport.y)
    of tP:
      for word in child.text.split(' '):
        let dims = vec2(getWordHeight(font, child.text).float, getWordLength(font, child.text).float)
        boxes &= Box(kind: bxText, text: word, position: cursor, sizePx: 12, isAnchor: false, dims: dims)

        cursor = vec2(cursor.x + dims.x, cursor.y)
        if cursor.x >= viewport.x:
          cursor = vec2(0f, cursor.y + viewport.y)
    else: discard

  boxes
