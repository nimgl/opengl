# Written by Leonardo Mariscal <leo@ldmd.mx>, 2019

import ./utils, httpClient, strutils, xmlparser, xmltree, os, streams, strformat, sets

type
  GLEnum = object
    name: string
    value: string
    eType: string
    comment: string
  GLArg = object
    name: string
    argType: string
  GLProc = object
    name: string
    args: seq[GLArg]
    rVal: string

var glEnums: seq[GLEnum]
var glProcs: seq[GLProc]

var gl1_0: seq[GLProc]
var gl1_1: seq[GLProc]
var gl1_2: seq[GLProc]
var gl1_3: seq[GLProc]
var gl1_4: seq[GLProc]
var gl1_5: seq[GLProc]
var gl2_0: seq[GLProc]
var gl2_1: seq[GLProc]
var gl3_0: seq[GLProc]
var gl3_1: seq[GLProc]

var gl3_2: seq[GLProc]
var gl3_3: seq[GLProc]
var gl4_0: seq[GLProc]
var gl4_1: seq[GLProc]
var gl4_2: seq[GLProc]
var gl4_3: seq[GLProc]
var gl4_4: seq[GLProc]
var gl4_5: seq[GLProc]
var gl4_6: seq[GLProc]

proc translateType(cmd: string): string =
  result = cmd
  result = result.replace("const ", "")
  result = result.replace("const", "")
  result = result.replace(" *", "*")
  result = result.replace("void*", "pointer")
  result = result.replace("GLchar*", "cstring")
  result = result.replace("GLeglClientBufferEXT", "pointer")
  result = result.replace("GLuintbas", "GLuint")

  if result.contains('*'):
    let levels = result.count('*')
    result = result.replace("*", "")
    for i in 0..<levels:
      result = "ptr " & result

  result = result.replace("ptr struct _cl_context", "ClContext")
  result = result.replace("ptr struct _cl_event", "ClEvent")

proc genEnums(node: XmlNode) =
  echo "Generating Enums..."
  for enums in node.findAll("enums"):
    for e in enums.findAll("enum"):
      var name = e.attr("name")
      if renameConstants.contains(name):
        name = "E" & name
      let value = e.attr("value")

      var eType = ".GLenum"
      if enums.attr("type") != "":
        eType = ".GLbitfield"
      if not value.contains('x') and value.parseFloat() < 0:
        eType = ""
      if e.attr("comment").contains("uint64"):
        eType = "'u64"
      elif e.attr("comment").contains("uint"):
        eType = "'u32"

      if name == "GL_ACTIVE_PROGRAM_EXT": # Conflict of redifinition
        continue

      var newEnum: GLEnum
      newEnum.name = name
      newEnum.value = value
      newEnum.eType = eType
      if e.attr("comment") != "":
        newEnum.comment = e.attr("comment")
      glEnums.add(newEnum)

proc genProcs(node: XmlNode) =
  echo "Generating Procedures..."
  for commands in node.findAll("commands"):
    for command in commands.findAll("command"):
      var glProc: GLProc
      glProc.name = command.child("proto").child("name").innerText
      glProc.rVal = command.child("proto").innerText
      glProc.rVal = glProc.rVal[0 ..< glProc.rval.len - glProc.name.len]
      while glProc.rVal.endsWith(" "):
        glProc.rVal = glProc.rVal[0 ..< glProc.rVal.len - 1]
      glProc.rVal = glProc.rVal.translateType()

      if glProc.name == "glGetTransformFeedbacki_v":
        continue

      for param in command.findAll("param"):
        var glArg: GLArg
        glArg.name = param.child("name").innerText
        glArg.argType = param.innerText
        glArg.argType = glArg.argType[0 ..< glArg.argType.len - glArg.name.len]
        while glArg.argType.endsWith(" "):
          glArg.argType = glArg.argType[0 ..< glArg.argType.len - 1]

        for part in glArg.name.split(" "):
          if keywords.contains(part):
            glArg.name = "`{glArg.name}`".fmt

        glArg.argType = glArg.argType.translateType()
        glProc.args.add(glArg)

      glProcs.add(glProc)

proc removeCompatibility(node: XmlNode) =
  echo "Removing Compatibility Mode..."
  for feature in node.findAll("feature"):
    let number = feature.attr("number").parseFloat()
    if number != 3.2f:
      continue

    for remove in feature.findAll("remove"):
      for command in remove.findAll("command"):
        for i in 0 ..< glProcs.len - 1:
          if glProcs[i].name == command.attr("name"):
            glProcs.del(i)
      for e in remove.findAll("enum"):
        for i in 0 ..< glEnums.len - 1:
          if glEnums[i].name == e.attr("name"):
            glEnums.del(i)

proc genFeatures(node: XmlNode) =
  echo "Generating Features..."
  for feature in node.findAll("feature"):
    if feature.attr("api") != "gl":
      continue
    let number = feature.attr("number").parseFloat()
    var current: ptr seq[GLProc]
    case number:
      of 1.0: current = gl1_0.addr
      of 1.1: current = gl1_1.addr
      of 1.2: current = gl1_2.addr
      of 1.3: current = gl1_3.addr
      of 1.4: current = gl1_4.addr
      of 1.5: current = gl1_5.addr
      of 2.0: current = gl2_0.addr
      of 2.1: current = gl2_1.addr
      of 3.0: current = gl3_0.addr
      of 3.1: current = gl3_1.addr

      of 3.2: current = gl3_2.addr
      of 3.3: current = gl3_3.addr
      of 4.0: current = gl4_0.addr
      of 4.1: current = gl4_1.addr
      of 4.2: current = gl4_2.addr
      of 4.3: current = gl4_3.addr
      of 4.4: current = gl4_4.addr
      of 4.5: current = gl4_5.addr
      of 4.6: current = gl4_6.addr

    for require in feature.findAll("require"):
      if require.attr("profile") == "compatibility":
        continue
      for command in require.findAll("command"):
        for glProc in glProcs:
          if glProc.name == command.attr("name"):
            current[].add(glProc)
            break

proc addStaticProcs(output: var string, number: string, features: seq[GLProc], duplicates: var HashSet[string]) =
  echo "Adding Static Procedures for {number}...".fmt
  output.add("\n# OpenGL {number} static procs\n".fmt)
  for glProc in features:
    if duplicates.contains(glProc.name):
      continue
    duplicates.incl(glProc.name)
    output.add("proc {glProc.name}*(".fmt)
    for arg in glProc.args:
      if not output.endsWith("("):
        output.add(", ")
      output.add("{arg.name}: {arg.argType}".fmt)
    output.add("): {glProc.rVal} {{.stdcall, importc.}}\n".fmt)

proc addDynamicProcs(output: var string) =
  echo "Adding Dynamic Procedures..."
  output.add("\n# Dynamic procs\n")
  output.add("var\n")
  for glProc in glProcs:
    output.add("  {glProc.name}*: proc(".fmt)
    for arg in glProc.args:
      if not output.endsWith("("):
        output.add(", ")
      output.add("{arg.name}: {arg.argType}".fmt)
    output.add("): {glProc.rVal} {{.stdcall.}}\n".fmt)

proc addEnums(output: var string) =
  echo "Adding Enums..."
  output.add("\n# Enums\n")
  output.add("const\n")

  for e in glEnums:
    output.add("  {e.name}* = {e.value}{e.eType}".fmt)
    if e.comment != "":
      output.add(" ## {e.comment}\n".fmt)
    else:
      output.add("\n")

proc addLoader(output: var string, number: string, features: seq[GLProc]) =
  echo "Adding Loader for {number}...".fmt
  output.add("\n# OpenGL {number} loader\n".fmt)
  output.add("proc glLoad{number}*() =\n".fmt)
  for glProc in features:
    output.add("  {glProc.name} = cast[proc(".fmt)
    for arg in glProc.args:
      if not output.endsWith("("):
        output.add(", ")
      output.add("{arg.name}: {arg.argType}".fmt)
    output.add("): {glProc.rVal} {{.stdcall.}}](glGetProc(\"{glProc.name}\"))\n".fmt)

proc addExtensions(output: var string, node: XmlNode) =
  echo "Adding Extensions..."
  output.add("\n# Extensions\n")
  for extensions in node.findAll("extensions"):
    for extension in extensions.findAll("extension"):
      let supported = extension.attr("supported")
      if supported != "gl" and not supported.contains("gl|"):
        continue

      var commands: seq[GLProc]
      for require in extension.findAll("require"):
        for command in require.findAll("command"):
          for glProc in glProcs:
            if glProc.name == command.attr("name"):
              commands.add(glProc)

      if commands.len == 0:
        continue

      let extensionName = extension.attr("name")
      output.add("\n# Load {extensionName}\n".fmt)
      output.add("proc load{extensionName}*() =\n".fmt)

      for glProc in commands:
        output.add("  {glProc.name} = cast[proc(".fmt)
        for arg in glProc.args:
          if not output.endsWith("("):
            output.add(", ")
          output.add("{arg.name}: {arg.argType}".fmt)
        output.add("): {glProc.rVal} {{.stdcall.}}](glGetProc(\"{glProc.name}\"))\n".fmt)

proc main() =
  if not os.fileExists("gl.xml"):
    let client = newHttpClient()
    let glUrl = "https://raw.githubusercontent.com/KhronosGroup/OpenGL-Registry/master/xml/gl.xml"
    client.downloadFile(glUrl, "gl.xml")

  var output = srcHeader & "\n"

  let file = newFileStream("gl.xml", fmRead)
  let xml = file.parseXml()

  output.add(srcTypes)

  xml.genEnums()
  xml.genProcs()
  xml.removeCompatibility()
  xml.genFeatures()

  output.addEnums()

  output.add("\nwhen defined(glStaticProcs) or defined(emscripten):\n")
  var staticOutput = ""
  var duplicates: HashSet[string]
  staticOutput.addStaticProcs("1_0", gl1_0, duplicates)
  staticOutput.addStaticProcs("1_1", gl1_1, duplicates)
  staticOutput.addStaticProcs("1_2", gl1_2, duplicates)
  staticOutput.addStaticProcs("1_3", gl1_3, duplicates)
  staticOutput.addStaticProcs("1_4", gl1_4, duplicates)
  staticOutput.addStaticProcs("1_5", gl1_5, duplicates)
  staticOutput.addStaticProcs("2_0", gl2_0, duplicates)
  staticOutput.addStaticProcs("2_1", gl2_1, duplicates)
  staticOutput.addStaticProcs("3_0", gl3_0, duplicates)
  staticOutput.addStaticProcs("3_1", gl3_1, duplicates)
  staticOutput.addStaticProcs("3_2", gl3_2, duplicates)
  staticOutput.addStaticProcs("3_3", gl3_3, duplicates)
  staticOutput.add("proc glInit*(): bool = true")
  staticOutput = indent(staticOutput, 2)
  output.add(staticOutput)

  output.add("\nelse:\n")
  var dynamicOutput = ""
  dynamicOutput.addDynamicProcs()
  dynamicOutput.addLoader("1_0", gl1_0)
  dynamicOutput.addLoader("1_1", gl1_1)
  dynamicOutput.addLoader("1_2", gl1_2)
  dynamicOutput.addLoader("1_3", gl1_3)
  dynamicOutput.addLoader("1_4", gl1_4)
  dynamicOutput.addLoader("1_5", gl1_5)
  dynamicOutput.addLoader("2_0", gl2_0)
  dynamicOutput.addLoader("2_1", gl2_1)
  dynamicOutput.addLoader("3_0", gl3_0)
  dynamicOutput.addLoader("3_1", gl3_1)
  dynamicOutput.addLoader("3_2", gl3_2)
  dynamicOutput.addLoader("3_3", gl3_3)
  dynamicOutput.addLoader("4_0", gl4_0)
  dynamicOutput.addLoader("4_1", gl4_1)
  dynamicOutput.addLoader("4_2", gl4_2)
  dynamicOutput.addLoader("4_3", gl4_3)
  dynamicOutput.addLoader("4_4", gl4_4)
  dynamicOutput.addLoader("4_5", gl4_5)
  dynamicOutput.addLoader("4_6", gl4_6)
  dynamicOutput.add("\n" & glInit)
  dynamicOutput.addExtensions(xml)
  dynamicOutput = indent(dynamicOutput, 2)
  output.add(dynamicOutput)

  writeFile("src/opengl.nim", output)

if isMainModule:
  main()
