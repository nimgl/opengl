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

# Thanks to ephja for this loading system
when defined(windows):
  const glDLL = "opengl32.dll"
elif defined(macosx):
  const glDLL = "/System/Library/Frameworks/OpenGL.framework/Versions/Current/Libraries/libGL.dylib"
else:
  const glDLL = "libGL.so.1"

import dynlib

let glHandle = loadLib(glDLL)
if isNil(glHandle): quit("could not load: " & gldll)

when defined(windows):
  var wglGetProcAddress = cast[proc (s: cstring): pointer {.stdcall.}](
    symAddr(glHandle, "wglGetProcAddress"))
elif defined(linux):
  var glxGetProcAddress = cast[proc (s: cstring): pointer {.cdecl.}](
    symAddr(glHandle, "glXGetProcAddress"))
  var glxGetProcAddressArb = cast[proc (s: cstring): pointer {.cdecl.}](
    symAddr(glHandle, "glXGetProcAddressARB"))

proc glGetProc(procName: cstring): pointer =
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
"""

const srcTypes* = """
# Thanks to ephja again for the types
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
  GLvectorub2* = array[0..1, GLubyte]
  GLvectori2* = array[0..1, GLint]
  GLvectorf2* = array[0..1, GLfloat]
  GLvectord2* = array[0..1, GLdouble]
  GLvectorp2* = array[0..1, pointer]
  GLvectorb3* = array[0..2, GLbyte]
  GLvectorub3* = array[0..2, GLubyte]
  GLvectori3* = array[0..2, GLint]
  GLvectorui3* = array[0..2, GLuint]
  GLvectorf3* = array[0..2, GLfloat]
  GLvectord3* = array[0..2, GLdouble]
  GLvectorp3* = array[0..2, pointer]
  GLvectors3* = array[0..2, GLshort]
  GLvectorus3* = array[0..2, GLushort]
  GLvectorb4* = array[0..3, GLbyte]
  GLvectorub4* = array[0..3, GLubyte]
  GLvectori4* = array[0..3, GLint]
  GLvectorui4* = array[0..3, GLuint]
  GLvectorf4* = array[0..3, GLfloat]
  GLvectord4* = array[0..3, GLdouble]
  GLvectorp4* = array[0..3, pointer]
  GLvectors4* = array[0..3, GLshort]
  GLvectorus4* = array[0..3, GLshort]
  GLarray4f* = GLvectorf4
  GLarrayf3* = GLvectorf3
  GLarrayd3* = GLvectord3
  GLarrayi4* = GLvectori4
  GLarrayp4* = GLvectorp4
  GLmatrixub3* = array[0..2, array[0..2, GLubyte]]
  GLmatrixi3* = array[0..2, array[0..2, GLint]]
  GLmatrixf3* = array[0..2, array[0..2, GLfloat]]
  GLmatrixd3* = array[0..2, array[0..2, GLdouble]]
  GLmatrixub4* = array[0..3, array[0..3, GLubyte]]
  GLmatrixi4* = array[0..3, array[0..3, GLint]]
  GLmatrixf4* = array[0..3, array[0..3, GLfloat]]
  GLmatrixd4* = array[0..3, array[0..3, GLdouble]]
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

when defined(macosx):
  type
    GLhandleArb = pointer
else:
  type
    GLhandleArb = uint32

proc `==`*(a, b: GLenum): bool {.borrow.}
proc `==`*(a, b: GLbitfield): bool {.borrow.}
proc `or`*(a, b: GLbitfield): GLbitfield {.borrow.}
proc hash*(x: GLenum): int = x.int
"""

let keywords = ["addr", "and", "as", "asm", "bind", "block", "break", "case", "cast", "concept",
                "const", "continue", "converter", "defer", "discard", "distinct", "div", "do",
                "elif", "else", "end", "enum", "except", "export", "finally", "for", "from", "func",
                "if", "import", "in", "include", "interface", "is", "isnot", "iterator", "let",
                "macro", "method", "mixin", "mod", "nil", "not", "notin", "object", "of", "or",
                "out", "proc", "ptr", "raise", "ref", "return", "shl", "shr", "static", "template",
                "try", "tuple", "type", "using", "var", "when", "while", "xor", "yield"]
