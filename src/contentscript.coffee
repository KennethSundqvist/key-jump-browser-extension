HINT_CHARACTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
KEYCODE_COMMA = 188
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
# Only care about if the input can not be typed in
# as of the latest version of Chrome.
KNOWN_NON_TYPABLE_INPUT_TYPES = [
  'button', 'submit', 'reset', 'image',
  'checkbox', 'radio', 'range', 'color', 'file'
]
CLASSNAME_ROOT = 'KEYJUMP'
CLASSNAME_ACTIVE = 'KEYJUMP_active'
CLASSNAME_HINT = 'KEYJUMP_hint'
CLASSNAME_MATCH = 'KEYJUMP_match'

w = window
d = document
active = false
hintsRootEl = d.createElement 'div'
hintsRootEl.classList.add CLASSNAME_ROOT
hintSourceEl = d.createElement 'div'
hintSourceEl.classList.add CLASSNAME_HINT
hints = null
hintMatch = undefined
removeHintsTimeout = null
query = null
targetEls = null

activate = ->
  hints = {}
  query = ''

  clearTimeout removeHintsTimeout
  removeHints()

  targetEls = d.querySelectorAll TARGET_ELEMENTS

  if targetEls.length then active = true else return

  hintPrefix = ''
  hintPrefixPos = 0
  hintPos = 0
  for target in targetEls
    if isElementVisible target
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
    hintsRootEl.appendChild hint.el
    targetPos = getElementPos(hint.target)
    top = Math.max(
      0,
      Math.min(
        Math.round(targetPos.top),
        (w.innerHeight + d.documentElement.scrollTop) - hint.el.offsetHeight
      )
    )
    left = Math.max(0, Math.round(targetPos.left) - hint.el.offsetWidth - 2)
    hint.el.style.top = top + 'px'
    hint.el.style.left = left + 'px'

  hintsRootEl.classList.add CLASSNAME_ACTIVE

  return

deactivate = ->
  if !active then return
  timeoutDuration = parseFloat(w.getComputedStyle(hintsRootEl).transitionDuration) * 1000
  active = false
  hints = null
  hintsRootEl.classList.remove CLASSNAME_ACTIVE
  removeHintsTimeout = setTimeout removeHints, timeoutDuration
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

removeHints = ->
  hintsRootEl.removeChild hintsRootEl.firstChild while hintsRootEl.firstChild

triggerHintMatch = (event) ->
  if shouldFocusElement hintMatch.target
    hintMatch.target.focus()
  else
    clickEvent = new MouseEvent 'click',
      view: window
      bubbles: true
      cancelable: true
      shiftKey: event.shiftKey
      ctrlKey:  event.ctrlKey
      altKey:   event.altKey
      metaKey:  event.metaKey
    hintMatch.target.dispatchEvent clickEvent
  deactivate()
  return

canTypeInElement = (el) ->
  tag = el.tagName.toLocaleLowerCase()
  inputType = el.getAttribute 'type'
  el.contentEditable == 'true' ||
    tag == 'textarea' ||
    (tag == 'input' && inputType not in KNOWN_NON_TYPABLE_INPUT_TYPES)

shouldFocusElement = (el) ->
  tag = el.tagName.toLocaleLowerCase()
  inputType = el.getAttribute 'type'
  canTypeInElement(el) ||
    tag == 'select' ||
    (tag == 'input' && inputType == 'range')

getElementPos = (el) ->
  rect = el.getBoundingClientRect()
  scrollTop = window.scrollY
  scrollLeft = window.scrollX
  return {
    top: rect.top + scrollTop
    bottom: rect.bottom + scrollTop
    right: rect.right + scrollLeft
    left: rect.left + scrollLeft
  }

isElementVisible = (el) ->
  rect = el.getBoundingClientRect()
  if rect.width <= 0 ||
    rect.height <= 0 ||
    rect.top >= w.innerHeight ||
    rect.left >= w.innerWidth ||
    rect.bottom <= 0 ||
    rect.right <= 0
      return false
  while el
    styles = w.getComputedStyle el
    if styles.display == 'none' ||
      styles.visibility == 'hidden' ||
      styles.opacity == '0'
        return false
    el = el.parentElement
  true

handleKeyboardEvent = (event) ->
  hasModifier = event.shiftKey || event.ctrlKey || event.altKey || event.metaKey
  if !canTypeInElement d.activeElement
    if event.keyCode == KEYCODE_RETURN && hintMatch
      triggerHintMatch event
      event.preventDefault()
    else if !hasModifier
      if event.keyCode == KEYCODE_COMMA
        if active then deactivate() else activate()
        event.preventDefault()
      else if active
        if event.keyCode == KEYCODE_ESC
          deactivate()
          event.preventDefault()
        else selectHints event
  return

# Init

d.body.appendChild hintsRootEl
d.addEventListener 'keydown', handleKeyboardEvent, true
