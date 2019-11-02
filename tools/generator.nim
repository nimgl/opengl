# Written by Leonardo Mariscal <leo@ldmd.mx>, 2019

import ./utils

proc main() =
  var output = srcHeader & "\n"
  output.add(srcTypes)

  writeFile("src/opengl.nim", output)

if isMainModule:
  main()
