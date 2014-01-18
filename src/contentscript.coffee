HINT_CHARACTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
KEYCODE_PERIOD = 190
KEYCODE_ESC = 27
KEYCODE_RETURN = 13
KEYCODE_BACKSPACE = 8
TARGET_ELEMENTS = """
a[href],
input:not([disabled]):not([hidden]),
textarea:not([disabled]),
select:not([disabled]),
button:not([disabled])
"""
CLASSNAME_HINT = 'KEYJUMP_hint'
CLASSNAME_MATCH = 'KEYJUMP_match'

d = document
active = false
hintsParentEl = d.createElement 'div'
hintSourceEl = d.createElement 'div'
hintSourceEl.classList.add CLASSNAME_HINT
hints = null
hintMatch = undefined
query = null
targetEls = null

activate = ->
  hints = {}
  query = ''
  targetEls = d.querySelectorAll TARGET_ELEMENTS

  if targetEls.length then active = true else return

  hintPrefix = ''
  hintPrefixPos = 0
  hintPos = 0
  for target in targetEls
    hintId = hintPrefix + HINT_CHARACTERS[hintPos++]
    hints[hintId] =
      id: hintId
      el: hintSourceEl.cloneNode true
      target: target
    if hintPos == HINT_CHARACTERS.length
      hintPos = 0
      hintPrefix = HINT_CHARACTERS[hintPrefixPos++]

  for hintKey, hint of hints
    hint.el.innerHTML = hintKey
    hintsParentEl.appendChild hint.el
    top = Math.max(0, hint.target.offsetTop)
    left = Math.max(0, hint.target.offsetLeft - hint.el.offsetWidth - 2)
    hint.el.style.top = top + 'px'
    hint.el.style.left = left + 'px'
    if top == 0 and left == 0
      console.log 'Hint at 0x0 pos', hint

  null

deactivate = ->
  active = false
  hints = null
  hintsParentEl.removeChild hintsParentEl.firstChild while hintsParentEl.firstChild
  null
  query = null

selectHints = (e) ->
  char = String.fromCharCode e.keyCode
  if e.keyCode == KEYCODE_BACKSPACE
    e.preventDefault()
    query = query.slice 0, -1
  else if HINT_CHARACTERS.indexOf(char) > -1
    e.preventDefault()
    query += char

  if hintMatch
    hintMatch.el.classList.remove CLASSNAME_MATCH
  hintMatch = hints[query]
  if hintMatch
    hintMatch.el.classList.add CLASSNAME_MATCH

trigger = ->
  if hintMatch
    console.log 'Should trigger hint "' + hintMatch.id + '"'

isEditableElement = (el) ->
  tag = el.tagName.toLocaleLowerCase()
  if tag is 'textarea'
    return true
  false

handleKeyboardEvent = (e) ->
  activeElement = d.activeElement

  if active
    if e.keyCode == KEYCODE_PERIOD or e.keyCode == KEYCODE_ESC
      deactivate()
    else if e.keyCode == KEYCODE_RETURN
      trigger()
    else
      selectHints e
  else
    if e.keyCode == KEYCODE_PERIOD
      if !isEditableElement activeElement
        activate()
        e.preventDefault()

  null

# Init

d.body.appendChild hintsParentEl
d.addEventListener 'keydown', handleKeyboardEvent, true
