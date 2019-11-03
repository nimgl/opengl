# Written by Leonardo Mariscal <leo@ldmd.mx>, 2019

const srcHeader* = """
# Written by Leonardo Mariscal <leo@ldmd.mx>, 2019

## Modern OpenGL Bindings
## ====
## WARNING: This is a generated file. Do not edit
## Any edits will be overwritten by the generator.
##
## NimGL is completely unaffiliated with OpenGL and
## Khronos, each Doc is under individual copyright
## You can find it in their appropiate file in the
## official `repo<https://github.com/KhronosGroup/OpenGL-Refpages>`_
##
## NOTE: This bindings only support modern OpenGL (3.2 >=)
## so fixed pipelines are not supported.

import strutils

var glGetProc: proc(procName: cstring): pointer {.cdecl.}

when not defined(glCustomLoader):
  import dynlib

  # Thanks to ephja for this loading system
  when defined(windows):
    const glDLL = "opengl32.dll"
  elif defined(macosx):
    const glDLL = "/System/Library/Frameworks/OpenGL.framework/Versions/Current/Libraries/libGL.dylib"
  else:
    const glDLL = "libGL.so.1"

  let glHandle = loadLib(glDLL)
  if isNil(glHandle):
    quit("could not load: " & gldll)

  when defined(windows):
    var wglGetProcAddress = cast[proc (s: cstring): pointer {.stdcall.}](
      symAddr(glHandle, "wglGetProcAddress"))
  elif defined(linux):
    var glxGetProcAddress = cast[proc (s: cstring): pointer {.cdecl.}](
      symAddr(glHandle, "glXGetProcAddress"))
    var glxGetProcAddressArb = cast[proc (s: cstring): pointer {.cdecl.}](
      symAddr(glHandle, "glXGetProcAddressARB"))

  glGetProc = proc(procName: cstring): pointer {.cdecl.} =
    when defined(windows):
      result = symAddr(glHandle, procName)
      if result != nil:
        return
      if not isNil(wglGetProcAddress):
        result = wglGetProcAddress(procName)
    elif defined(linux):
      result = symAddr(glHandle, procname)
      if result != nil:
        return
      if not isNil(glxGetProcAddressArb):
        result = glxGetProcAddressArb(procName)
        if result != nil:
          return
      if not isNil(glxGetProcAddress):
        result = glxGetProcAddress(procName)
    else:
      result = symAddr(glHandle, procName)
    if result == nil: raiseInvalidLibrary(procName)

proc setGLGetProc*(getProc: proc(procName: cstring): pointer {.cdecl.}) =
  glGetProc = getProc
"""

const srcTypes* = """
type
  GLenum* = distinct uint32
  GLboolean* = bool
  GLbitfield* = distinct uint32
  GLvoid* = pointer
  GLbyte* = int8
  GLshort* = int16
  GLint* = int32
  GLclampx* = int32
  GLubyte* = uint8
  GLushort* = uint16
  GLuint* = uint32
  GLhandle* = GLuint
  GLsizei* = int32
  GLfloat* = float32
  GLclampf* = float32
  GLdouble* = float64
  GLclampd* = float64
  GLeglImageOES* = distinct pointer
  GLchar* = char
  GLcharArb* = char
  GLfixed* = int32
  GLhalfNv* = uint16
  GLvdpauSurfaceNv* = uint
  GLintptr* = int
  GLintptrArb* = int
  GLint64EXT* = int64
  GLuint64EXT* = uint64
  GLint64* = int64
  GLsizeiptrArb* = int
  GLsizeiptr* = int
  GLsync* = distinct pointer
  GLuint64* = uint64
  ClContext* = distinct pointer
  ClEvent* = distinct pointer
  GLdebugProc* = proc (
    source: GLenum,
    typ: GLenum,
    id: GLuint,
    severity: GLenum,
    length: GLsizei,
    message: ptr GLchar,
    userParam: pointer) {.stdcall.}
  GLdebugProcArb* = proc (
    source: GLenum,
    typ: GLenum,
    id: GLuint,
    severity: GLenum,
    len: GLsizei,
    message: ptr GLchar,
    userParam: pointer) {.stdcall.}
  GLdebugProcAmd* = proc (
    id: GLuint,
    category: GLenum,
    severity: GLenum,
    len: GLsizei,
    message: ptr GLchar,
    userParam: pointer) {.stdcall.}
  GLdebugProcKhr* = proc (
    source, typ: GLenum,
    id: GLuint,
    severity: GLenum,
    length: GLsizei,
    message: ptr GLchar,
    userParam: pointer) {.stdcall.}
  GLVULKANPROCNV* = proc(): void {.stdcall.}

when defined(macosx):
  type
    GLhandleArb = pointer
else:
  type
    GLhandleArb = uint32

var
  glVersionMajor*: int
  glVersionMinor*: int

proc `==`*(a, b: GLenum): bool {.borrow.}
proc `==`*(a, b: GLbitfield): bool {.borrow.}
proc `or`*(a, b: GLbitfield): GLbitfield {.borrow.}
proc hash*(x: GLenum): int = x.int
"""

const glInit* = """
proc glInit*(): bool =
  glGetString = cast[proc(name: GLenum): ptr GLubyte {.stdcall.}](glGetProc("glGetString"))
  if glGetString == nil:
    return false

  let glVersion = cast[cstring](glGetString(GL_VERSION))
  if glVersion.isNil:
    return false

  let prefixes = ["OpenGL ES-CM ", "OpenGL ES-CL ", "OpenGL ES "]
  var version: string = $glVersion
  for prefix in prefixes:
    if version.startsWith(prefix):
      version = version.replace(prefix)
      break

  let major = ord(glVersion[0]) - ord('0')
  let minor = ord(glVersion[2]) - ord('0')

  glVersionMajor = major
  glVersionMinor = minor

  if (major == 1 and minor >= 0) or major > 1: glLoad1_0()
  if (major == 1 and minor >= 1) or major > 1: glLoad1_1()
  if (major == 1 and minor >= 2) or major > 1: glLoad1_2()
  if (major == 1 and minor >= 3) or major > 1: glLoad1_3()
  if (major == 1 and minor >= 4) or major > 1: glLoad1_4()
  if (major == 1 and minor >= 5) or major > 1: glLoad1_5()
  if (major == 2 and minor >= 0) or major > 2: glLoad2_0()
  if (major == 2 and minor >= 1) or major > 2: glLoad2_1()
  if (major == 3 and minor >= 0) or major > 3: glLoad3_0()
  if (major == 3 and minor >= 1) or major > 3: glLoad3_1()
  if (major == 3 and minor >= 2) or major > 3: glLoad3_2()
  if (major == 3 and minor >= 3) or major > 3: glLoad3_3()
  if (major == 4 and minor >= 0) or major > 4: glLoad4_0()
  if (major == 4 and minor >= 1) or major > 4: glLoad4_1()
  if (major == 4 and minor >= 2) or major > 4: glLoad4_2()
  if (major == 4 and minor >= 3) or major > 4: glLoad4_3()
  if (major == 4 and minor >= 4) or major > 4: glLoad4_4()
  if (major == 4 and minor >= 5) or major > 4: glLoad4_5()
  if (major == 4 and minor >= 6) or major > 4: glLoad4_6()
  return true
"""

let keywords* = ["addr", "and", "as", "asm", "bind", "block", "break", "case", "cast", "concept",
                 "const", "continue", "converter", "defer", "discard", "distinct", "div", "do",
                 "elif", "else", "end", "enum", "except", "export", "finally", "for", "from", "func",
                 "if", "import", "in", "include", "interface", "is", "isnot", "iterator", "let",
                 "macro", "method", "mixin", "mod", "nil", "not", "notin", "object", "of", "or",
                 "out", "proc", "ptr", "raise", "ref", "return", "shl", "shr", "static", "template",
                 "try", "tuple", "type", "using", "var", "when", "while", "xor", "yield"]

let renameConstants* = ["GL_BYTE", "GL_SHORT", "GL_INT", "GL_FLOAT", "GL_DOUBLE", "GL_FIXED"]
