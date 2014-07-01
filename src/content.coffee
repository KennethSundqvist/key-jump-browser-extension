"use strict"

W = window
D = document
O = Object
HINT_CHARACTERS = '1234567890'
KEYCODE_ESC = 27
KEYCODE_RETURN = 13
PLATFORM_MAC = W.navigator.platform.toLowerCase().indexOf('mac') > -1
TARGET_ELEMENTS = """
a[href],
input:not([disabled]):not([type=hidden]),
textarea:not([disabled]),
select:not([disabled]),
button:not([disabled]),
[contenteditable='true'],
[contenteditable]:not([contenteditable='false']),
embed + .fc-panel,
embed ~ .PlaceholderFF,
[ng-click],
[data-ng-click]
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
CLASSNAME_FILTERED = 'KEYJUMP_filtered'
CLASSNAME_HINT = 'KEYJUMP_hint'
CLASSNAME_MATCH = 'KEYJUMP_match'
TIMEOUT_REFRESH = 100
DEFAULT_OPTIONS =
  activationChar: ','
  activationShift: false
  activationCtrl: false
  activationAlt: false
  activationMeta: false
  activationTabChar: '.'
  activationTabShift: false
  activationTabCtrl: false
  activationTabAlt: false
  activationTabMeta: false
  keepHintsAfterTrigger: false
  autoTrigger: true
NUMPAD_KEY_CODES = {
  96: 48 # 0
  97: 49 # 1
  98: 50 # 2
  99: 51 # 3
  100: 52 # 4
  101: 53 # 5
  102: 54 # 6
  103: 55 # 7
  104: 56 # 8
  105: 57 # 9
}

options = {}
hintsRootEl = D.createElement 'div'
hintsRootEl.classList.add CLASSNAME_ROOT
hintSourceEl = D.createElement 'div'
hintSourceEl.classList.add CLASSNAME_HINT

hintMode = null

HintMode = (openLinksInTabs) ->
  @openLinksInTabs = openLinksInTabs
  @resetHints()
  return if !@hints.length
  @firstInstancePreparations()
  @eventBindings 'add'
  @renderHints()
  return

HintMode.prototype =
  constructor: HintMode
  firstInstance: true
  hintWidth: 0
  hintHeight: 0
  hintCharWidth: 0
  timeoutDuration: null

  firstInstancePreparations: ->
    if @firstInstance
      proto = @constructor.prototype

      D.body.appendChild hintsRootEl
      transitionDuration = W.getComputedStyle(hintsRootEl).transitionDuration

      proto.firstInstance = false
      proto.timeoutDuration = parseFloat(transitionDuration) * 1000

      hintDimensionsEl = hintSourceEl.cloneNode true
      hintsRootEl.appendChild hintDimensionsEl
      proto.hintWidth = hintDimensionsEl.offsetWidth
      hintDimensionsEl.innerHTML = 0
      proto.hintHeight = hintDimensionsEl.offsetHeight
      proto.hintCharWidth = hintDimensionsEl.offsetWidth - @hintWidth
      hintsRootEl.removeChild hintDimensionsEl
    return

  deactivate: ->
    hintMode = null
    @eventBindings 'remove'
    clearTimeout @refreshTimeout
    clearTimeout @removeHintsTimeout
    hintsRootEl.classList.remove CLASSNAME_ACTIVE
    @removeHintsTimeout = setTimeout @removeHints, @timeoutDuration
    return

  removeHints: ->
    hintsRootEl.removeChild hintsRootEl.firstChild while hintsRootEl.firstChild
    hintsRootEl.classList.remove CLASSNAME_FILTERED
    return

  resetHints: ->
    @removeHints()
    @hints = {}
    @query = ''
    targetEls = D.querySelectorAll TARGET_ELEMENTS
    hintId = 0
    for el in targetEls
      if isElementVisible el
        hintId++
        @hints.length++
        @hints[hintId] =
          id: hintId
          el: hintSourceEl.cloneNode true
          target: el
    O.defineProperty @hints, 'length', value: hintId, enumerable: false
    return

  refreshHints: ->
    @resetHints()
    @renderHints()
    return

  setRefreshTimeout: ->
    clearTimeout @refreshTimeout
    @refreshTimeout = setTimeout @refreshHints.bind(@), TIMEOUT_REFRESH
    return

  boundSetRefreshTimeout: null

  eventBindings: (addOrRemove) ->
    if !@boundSetRefreshTimeout
      @boundSetRefreshTimeout = @setRefreshTimeout.bind @
    D[addOrRemove + 'EventListener'] 'scroll', @boundSetRefreshTimeout, false
    W[addOrRemove + 'EventListener'] 'popstate', @boundSetRefreshTimeout, false
    W[addOrRemove + 'EventListener'] 'resize', @boundSetRefreshTimeout, false
    return

  renderHints: ->
    return if !@hints.length
    fragment = D.createDocumentFragment()
    winHeight = D.documentElement.clientHeight
    for hintKey, hint of @hints
      hintKey = hintKey.toString()
      hint.el.setAttribute 'data-hint-id', hintKey
      hint.el.innerHTML = hintKey
      fragment.appendChild hint.el
      targetPos = getElementPos(hint.target)
      top = Math.max(
        D.body.scrollTop,
        Math.min(
          Math.round(targetPos.top),
          (winHeight + D.body.scrollTop) - @hintHeight
        )
      )
      hintCharWidth = @hintCharWidth * hintKey.length
      hintLeftPos = Math.round(targetPos.left)
      left = Math.max(0, hintLeftPos - @hintWidth - hintCharWidth - 2)
      hint.el.style.top = top + 'px'
      hint.el.style.left = left + 'px'
    hintsRootEl.appendChild fragment
    hintsRootEl.classList.add CLASSNAME_ACTIVE
    return

  appendToQuery: (e) ->
    keyCode = e.keyCode
    char = String.fromCharCode NUMPAD_KEY_CODES[keyCode] || keyCode
    if HINT_CHARACTERS.indexOf(char) > -1
      stopKeyboardEvent e
      if @hints[@query + char]
        @query += char
        @filterHints()
        if options.autoTrigger then @autoTriggerHintMatch()
    return

  filterHints: ->
    @hintMatch = @hints[@query]
    hintsRootEl.classList[if @query then 'add' else 'remove'] CLASSNAME_FILTERED
    for el in hintsRootEl.querySelectorAll '.' + CLASSNAME_MATCH
      el.classList.remove CLASSNAME_MATCH
    if @query
      for el in hintsRootEl.querySelectorAll '[data-hint-id^="' + @query + '"]'
        el.classList.add CLASSNAME_MATCH
    return

  handleEscapeEvent: (e) ->
    if @query
      @query = ''
      @filterHints()
    else @deactivate()
    stopKeyboardEvent e
    return

  triggerHintMatch: ->
    target = @hintMatch && @hintMatch.target
    return if !target
    tagName = target.tagName.toLowerCase()
    mouseEventType = if tagName == 'select' then 'mousedown' else 'click'
    if !options.keepHintsAfterTrigger then @deactivate()
    if shouldFocusElement target
      target.focus()
    else
      clickEvent = new MouseEvent mouseEventType,
        view: W
        bubbles: true
        cancelable: true
        ctrlKey: @openLinksInTabs && !PLATFORM_MAC
        metaKey: @openLinksInTabs && PLATFORM_MAC
      target.dispatchEvent clickEvent
    if options.keepHintsAfterTrigger then @refreshHints()
    return

  autoTriggerHintMatch: ->
    if @hintMatch && @hints.length < parseInt(@hintMatch.id + '0')
      @triggerHintMatch()
    return

canTypeInElement = (el) ->
  return if !el
  tagName = el.tagName.toLocaleLowerCase()
  inputType = el.getAttribute 'type'
  el.contentEditable == 'true' ||
    tagName == 'textarea' ||
    (tagName == 'input' && inputType not in KNOWN_NON_TYPABLE_INPUT_TYPES)

shouldFocusElement = (el) ->
  return if !el
  tagName = el.tagName.toLocaleLowerCase()
  inputType = el.getAttribute 'type'
  canTypeInElement el || (tagName == 'input' && inputType == 'range')

getElementPos = (el) ->
  rect = el.getClientRects()[0]
  return if !rect
  scrollTop = W.scrollY
  scrollLeft = W.scrollX
  return {
    top: rect.top + scrollTop
    bottom: rect.bottom + scrollTop
    right: rect.right + scrollLeft
    left: rect.left + scrollLeft
  }

isElementVisible = (el) ->
  rect = el.getClientRects()[0]
  return false if !rect ||
    rect.width <= 0 ||
    rect.height <= 0 ||
    rect.top >= D.documentElement.clientHeight ||
    rect.left >= D.documentElement.clientWidth ||
    rect.bottom <= 0 ||
    rect.right <= 0
  while el
    styles = W.getComputedStyle el
    return false if styles.display == 'none' ||
      styles.visibility == 'hidden' ||
      styles.opacity == '0'
    el = el.parentElement
  true

getCharacterFromEvent = (e) ->
  keyIdentifier = (e.keyIdentifier).replace('U+', '\\u')
  JSON.parse('"' + keyIdentifier + '"').toLowerCase()

isActivationKey = (e) ->
  getCharacterFromEvent(e) == options.activationChar &&
    e.shiftKey == options.activationShift &&
    e.ctrlKey == options.activationCtrl &&
    e.altKey == options.activationAlt &&
    e.metaKey == options.activationMeta

isActivationTabKey = (e) ->
  getCharacterFromEvent(e) == options.activationTabChar &&
    e.shiftKey == options.activationTabShift &&
    e.ctrlKey == options.activationTabCtrl &&
    e.altKey == options.activationTabAlt &&
    e.metaKey == options.activationTabMeta

toggleHintMode = (openLinksInTabs) ->
  if hintMode
    if hintMode.openLinksInTabs != openLinksInTabs
      hintMode.openLinksInTabs = openLinksInTabs
    else hintMode.deactivate()
  else hintMode = new HintMode openLinksInTabs

handleKeydownEvent = (e) ->
  notInTypableElement = !canTypeInElement D.activeElement
  if notInTypableElement
    hasModifier = e.shiftKey || e.ctrlKey || e.altKey || e.metaKey
    hasMatch = hintMode && hintMode.hintMatch
    isReturn = e.keyCode == KEYCODE_RETURN
    isEscape = e.keyCode == KEYCODE_ESC
    if hasMatch && isReturn && notInTypableElement
      # Use keyup for triggering, only prevent keydown
      stopKeyboardEvent e
    else if isActivationKey e
      toggleHintMode false
      stopKeyboardEvent e
    else if isActivationTabKey e
      toggleHintMode true
      stopKeyboardEvent e
    else if !hasModifier && hintMode
      if isEscape then hintMode.handleEscapeEvent e
      else hintMode.appendToQuery e
  return

handleKeyupEvent = (e) ->
  # Use keyup for triggering, because if we focus the target
  # element on keydown there will be a keyup event on the
  # target element and that's annoying to deal with..
  hasMatch = hintMode && hintMode.hintMatch
  isReturn = e.keyCode == KEYCODE_RETURN
  notInTypableElement = !canTypeInElement D.activeElement
  if hasMatch && isReturn && notInTypableElement
    stopKeyboardEvent e
    hintMode.triggerHintMatch()
  return

stopKeyboardEvent = (e) ->
  e.preventDefault()
  e.stopPropagation()
  e.stopImmediatePropagation()
  return

# Init

chrome.storage.sync.get O.keys(DEFAULT_OPTIONS), (storageOptions) ->
  for own key, defaultValue of DEFAULT_OPTIONS
    userSet = storageOptions.hasOwnProperty key
    options[key] = if userSet then storageOptions[key] else defaultValue
  return

D.addEventListener 'keydown', handleKeydownEvent, true
D.addEventListener 'keyup', handleKeyupEvent, true
