HINT_CHARACTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
KEYCODE_PERIOD = 190
KEYCODE_ESC = 27
KEYCODE_RETURN = 13
TARGET_ELEMENTS = """
a[href],
input:not([disabled]):not([hidden]),
textarea:not([disabled]),
select:not([disabled]),
button:not([disabled])
"""

d = document
active = false
hintsParentEl = d.createElement 'div'
hintSourceEl = d.createElement 'div'
hintSourceEl.classList.add 'KEYJUMP_hint'
hints = null
targetEls = null

activate = ->
  hints = {}
  targetEls = d.querySelectorAll TARGET_ELEMENTS

  if targetEls.length then active = true else return

  hintPrefix = ''
  hintPrefixPos = 0
  hintPos = 0
  for target in targetEls
    hints[hintPrefix + HINT_CHARACTERS[hintPos++]] =
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

selectHints = (keyCode) ->
  console.log 'Figure out if the keyCode is in the A-Z range...', keyCode

trigger = ->
  console.log 'Should trigger a hint...'

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
      selectHints e.keyCode
  else
    if e.keyCode == KEYCODE_PERIOD
      if !isEditableElement activeElement
        activate()
        e.preventDefault()

  null

# Init

d.body.appendChild hintsParentEl
d.addEventListener 'keydown', handleKeyboardEvent, true
