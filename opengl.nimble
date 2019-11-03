# Package

version     = "1.0.0"
author      = "Leonardo Mariscal"
description = "OpenGL bindings for Nim"
license     = "MIT"
srcDir      = "src"
skipDirs    = @["tests"]

# Dependencies

requires "nim >= 1.0.0"

task gen, "Generate bindings":
  exec("nim c -d:ssl -r tools/generator.nim")

task test, "Build an test bindings":
  requires "nimgl@#1.0" # Please https://github.com/nim-lang/nimble/issues/482
  exec("nim c -r tests/test.nim")
