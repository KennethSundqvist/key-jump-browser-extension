HINT_CHARACTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
KEYCODE_PERIOD = 190
KEYCODE_ESC = 27
KEYCODE_RETURN = 13
KEYCODE_BACKSPACE = 8
TARGET_ELEMENTS = """
a[href],
input:not([disabled]):not([type=hidden]),
textarea:not([disabled]),
select:not([disabled]),
button:not([disabled]),
[contenteditable='true'],
[contenteditable]:not([contenteditable='false'])
"""
# Unknown input types are treated as text inputs by Chrome
# so we whitelist the ones we know can't be typed in.
#
# Only care about if the input can by typed in
# as of the latest version of Chrome.
KNOWN_NON_TYPABLE_INPUT_TYPES = [
  'button', 'submit', 'reset', 'image',
  'checkbox', 'radio', 'range', 'color', 'file',
  'datetime-local', 'date', 'time', 'month', 'week'
]
CLASSNAME_PARENT = 'KEYJUMP'
CLASSNAME_HINT = 'KEYJUMP_hint'
CLASSNAME_MATCH = 'KEYJUMP_match'

d = document
active = false
hintsParentEl = d.createElement 'div'
hintsParentEl.classList.add CLASSNAME_PARENT
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

  return

deactivate = ->
  active = false
  hints = null
  hintsParentEl.removeChild hintsParentEl.firstChild while hintsParentEl.firstChild
  query = null
  return

selectHints = (event) ->
  char = String.fromCharCode event.keyCode
  if event.keyCode == KEYCODE_BACKSPACE
    event.preventDefault()
    query = query.slice 0, -1
  else if HINT_CHARACTERS.indexOf(char) > -1
    event.preventDefault()
    query += char

  if hintMatch then hintMatch.el.classList.remove CLASSNAME_MATCH
  hintMatch = hints[query]
  if hintMatch then hintMatch.el.classList.add CLASSNAME_MATCH

  return

trigger = ->
  if hintMatch
    console.log 'Should trigger hint "' + hintMatch.id + '"'
    deactivate()
  return

canTypeInElement = (el) ->
  tag = el.tagName.toLocaleLowerCase()
  inputType = el.getAttribute 'type'
  el.contentEditable == 'true' ||
    tag == 'textarea' ||
    (tag == 'input' && inputType not in KNOWN_NON_TYPABLE_INPUT_TYPES)

handleKeyboardEvent = (event) ->
  hasModifier = event.shiftKey || event.ctrlKey || event.altKey || event.metaKey
  if !hasModifier && !canTypeInElement d.activeElement
    if event.keyCode == KEYCODE_PERIOD
      if active then deactivate() else activate()
      event.preventDefault()
    else if active
      if event.keyCode == KEYCODE_RETURN then trigger() && event.preventDefault()
      else if event.keyCode == KEYCODE_ESC then deactivate() && event.preventDefault()
      else selectHints event
  return

# Init

d.body.appendChild hintsParentEl
d.addEventListener 'keydown', handleKeyboardEvent, true
