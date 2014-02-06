HINT_CHARACTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
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
TIMEOUT_REACTIVATE = 300
DEFAULT_OPTIONS =
  activationChar: ','
  activationShift: false
  activationCtrl: false
  activationAlt: false
  activationMeta: false

w = window
d = document
options = {}
firstActivation = true
active = false
reactivateTimeout = null
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

  if firstActivation
    d.body.appendChild hintsRootEl
    firstActivation = false

  clearTimeout removeHintsTimeout
  removeHints()

  targetEls = d.querySelectorAll TARGET_ELEMENTS

  if targetEls.length
    if !active
      active = true
      d.addEventListener 'scroll', setReactivationTimeout, false
      w.addEventListener 'popstate', setReactivationTimeout, false
  else return

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
  d.removeEventListener 'scroll', setReactivationTimeout, false
  w.removeEventListener 'popstate', setReactivationTimeout, false
  clearTimeout reactivateTimeout
  timeoutDuration = parseFloat(w.getComputedStyle(hintsRootEl).transitionDuration) * 1000
  active = false
  hints = null
  hintsRootEl.classList.remove CLASSNAME_ACTIVE
  removeHintsTimeout = setTimeout removeHints, timeoutDuration
  query = null
  return

selectHints = (event) ->
  char = String.fromCharCode event.keyCode
  prevQuery = query
  if event.keyCode == KEYCODE_BACKSPACE
    query = query.slice 0, -1
    stopKeyboardEvent event
  else if HINT_CHARACTERS.indexOf(char) > -1 and hints[query + char]
    query += char
    stopKeyboardEvent event
  if query != prevQuery
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

isActivationKey = (event) ->
  char = JSON.parse('"' + (event.keyIdentifier).replace('U+', '\\u') + '"').toLowerCase()
  char == options.activationChar &&
    event.shiftKey == options.activationShift &&
    event.ctrlKey == options.activationCtrl &&
    event.altKey == options.activationAlt &&
    event.metaKey == options.activationMeta

handleKeyboardEvent = (event) ->
  hasModifier = event.shiftKey || event.ctrlKey || event.altKey || event.metaKey
  if !canTypeInElement d.activeElement
    if event.keyCode == KEYCODE_RETURN && hintMatch
      triggerHintMatch event
      stopKeyboardEvent event
    else if isActivationKey event
      if active then deactivate() else activate()
      stopKeyboardEvent event
    else if !hasModifier && active
      if event.keyCode == KEYCODE_ESC
        deactivate()
        stopKeyboardEvent event
      else selectHints event
  return

stopKeyboardEvent = (event) ->
  event.preventDefault()
  event.stopPropagation()
  event.stopImmediatePropagation()
  return

setReactivationTimeout = () ->
  clearTimeout reactivateTimeout
  reactivateTimeout = setTimeout activate, TIMEOUT_REACTIVATE
  return

# Init

chrome.storage.sync.get Object.keys(DEFAULT_OPTIONS), (storageOptions) ->
  for own key, value of DEFAULT_OPTIONS
    options[key] = if storageOptions.hasOwnProperty key then storageOptions[key] else value
  d.addEventListener 'keydown', handleKeyboardEvent, true
  return
