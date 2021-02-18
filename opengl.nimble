# Package

version     = "1.0.1"
author      = "Leonardo Mariscal"
description = "OpenGL bindings for Nim"
license     = "MIT"
srcDir      = "src"
skipDirs    = @["tests"]

# Dependencies

requires "nim >= 1.0.0"

task gen, "Generate bindings":
  exec("nim c -d:ssl -r tools/generator.nim")

task test, "Build and test bindings":
  requires "nimgl@#1.0" # Please https://github.com/nim-lang/nimble/issues/482
  exec("nim c -r tests/test.nim")

task testWeb, "Build and test bindings with emscripten":
  # for this to work, you need emsdk on your PATH.
  # first, clone https://github.com/emscripten-core/emsdk
  # then run:
  # ./emsdk install latest
  # ./emsdk activate latest
  # and then add the directories it prints out to your PATH
  exec("nim c -d:emscripten tests/test.nim")
  let port = "8000"
  echo "Open http://localhost:" & port & "/tests/web/index.html"
  let ret = gorgeEx("python3 -m http.server " & port)
  echo ret.output
