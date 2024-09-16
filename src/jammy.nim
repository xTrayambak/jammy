import std/[tables, unicode, sets]
import ./[tokenizer, parser, layout]
import ferusgfx, glfw, opengl, pixie
import pretty

proc getColor(box: Box): Color =
  if box.kind == bxText:
    if box.isAnchor: return color(0, 0, 1, 1)
    else: return color(0, 0, 0, 1)

proc renderDocument(scene: var Scene, document: Document, viewport: Vec2) =
  let boxes = constructBoxes(document, scene.fontManager.get("Default"), viewport)
  print boxes
  var displayList = newDisplayList(addr scene)

  for box in boxes:
    if box.dims.x < 0 or box.dims.y < 0: continue
    case box.kind
    of bxText:
      displayList &=
        newTextNode(box.text, box.position, box.dims, scene.fontManager.getTypeface("Default"), box.sizePx.float32, getColor(box))

  displayList.commit()

proc main =
  let tokenizer = newTokenizer(readFile "test.html")
  let tokens = tokenizer.tokenize()
  print tokens

  let parser = newParser(tokens)
  let document = parser.parse()
  print document
  
  # start renderer
  glfw.initialize()
  var c = DefaultOpenglWindowConfig
  c.title = "Jammy"
  let window = newWindow(c)
  window.makeContextCurrent()
  loadExtensions()

  var scene = newScene(1280, 720)
  scene.fontManager.load("Default", "IBMPlexSans-Regular.ttf")
  scene.fontManager.loadTypeface("Default", "IBMPlexSans-Regular.ttf")
  renderDocument(scene, document, vec2(1280, 720))

  window.windowSizeCb = proc(w: Window, size: tuple[w, h: int32]) =
    scene.onResize((w: size.w.int, h: size.h.int))
    scene.renderDocument(document, vec2(size.w.float, size.h.float))
  
  window.scrollCb = proc(w: Window, offset: tuple[x, y: float64]) =
    scene.onScroll(vec2(offset.x, offset.y))

  while not window.shouldClose:
    scene.draw()
    glfw.swapBuffers(window)
    glfw.pollEvents()

  window.destroy()
  glfw.terminate()

when isMainModule:
  main()
