fs = require 'fs'
path = require 'path'

selector = null

module.exports =
  activate: ->
    atom.commands.add('atom-workspace', 'path:open', openPath)

openPath = ->
  editor = atom.workspace.getActiveTextEditor()
  return unless editor?

  filePath = pathUnderCursor(editor)
  return unless filePath?

  currentPath = editor?.buffer.file.path

  filePath = path.resolve(path.dirname(currentPath), filePath)

  if fs.existsSync filePath
    if fs.statSync(filePath).isFile()
      atom.workspace.open filePath
    else
      console.log 'This path is a directory'
      atom.beep()
  else
    files = fs.readdirSync(path.dirname(filePath))
    opened = false
    for filename in files
      if filename.indexOf(path.basename(filePath)) isnt -1
        atom.workspace.open path.dirname(filePath) + path.sep + filename
        opened = true
    if !opened
      console.log 'This path does not exist'
      atom.beep()

# Get the path under the cursor in the editor
#
# Returns a {String} path or undefined if no path found.
pathUnderCursor = (editor) ->
  cursorPosition = editor.getCursorBufferPosition()
  filePath = pathAtPosition(editor, cursorPosition)
  return filePath if filePath?

  # Look for a path to the left of the cursor
  if cursorPosition.column > 0
    pathAtPosition(editor, cursorPosition.translate([0, -1]))

# Get the path at the buffer position in the editor.
#
# Returns a {String} path or undefined if no path found.
pathAtPosition = (editor, bufferPosition) ->
  unless selector?
    {ScopeSelector} = require 'first-mate'
    selector = new ScopeSelector('string.quoted')

  if token = editor.tokenForBufferPosition(bufferPosition)
    token.value if token.value and selector.matches(token.scopes)
