w = window
d = document

HINT_CHARACTERS = '1234567890'
KEYCODE_ESC = 27
KEYCODE_RETURN = 13
NEW_TAB_MODIFIER_KEY = if w.navigator.platform.toLowerCase().indexOf('mac') > -1 then 'meta' else 'ctrl'
TARGET_ELEMENTS = """
a[href],
input:not([disabled]):not([type=hidden]),
textarea:not([disabled]),
select:not([disabled]),
button:not([disabled]),
[contenteditable='true'],
[contenteditable]:not([contenteditable='false']),
embed + .fc-panel,
embed ~ .PlaceholderFF
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

options = {}
hintsRootEl = d.createElement 'div'
hintsRootEl.classList.add CLASSNAME_ROOT
hintSourceEl = d.createElement 'div'
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
      d.body.appendChild hintsRootEl
      proto.firstInstance = false

      proto.timeoutDuration = parseFloat(w.getComputedStyle(hintsRootEl).transitionDuration) * 1000

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
    targetEls = d.querySelectorAll TARGET_ELEMENTS
    hintId = 0
    for el in targetEls
      if isElementVisible el
        hintId++
        @hints.length++
        @hints[hintId] =
          id: hintId
          el: hintSourceEl.cloneNode true
          target: el
    Object.defineProperty @hints, 'length', value: hintId, enumerable: false
    return

  refreshHints: ->
    @resetHints()
    @renderHints()
    return

  setRefreshHintsTimeout: ->
    clearTimeout @refreshTimeout
    @refreshTimeout = setTimeout @refreshHints.bind(@), TIMEOUT_REFRESH
    return

  boundSetRefreshHintsTimeout: null

  eventBindings: (addOrRemove) ->
    if !@boundSetRefreshHintsTimeout
      @boundSetRefreshHintsTimeout = @setRefreshHintsTimeout.bind @
    d[addOrRemove + 'EventListener'] 'scroll', @boundSetRefreshHintsTimeout, false
    w[addOrRemove + 'EventListener'] 'popstate', @boundSetRefreshHintsTimeout, false
    w[addOrRemove + 'EventListener'] 'resize', @boundSetRefreshHintsTimeout, false
    return

  renderHints: ->
    return if !@hints.length
    fragment = d.createDocumentFragment()
    for hintKey, hint of @hints
      hintKey = hintKey.toString()
      hint.el.setAttribute 'data-hint-id', hintKey
      hint.el.innerHTML = hintKey
      fragment.appendChild hint.el
      targetPos = getElementPos(hint.target)
      top = Math.max(
        d.body.scrollTop,
        Math.min(
          Math.round(targetPos.top),
          (w.innerHeight + d.body.scrollTop) - @hintHeight
        )
      )
      left = Math.max(0, Math.round(targetPos.left) - @hintWidth - (@hintCharWidth * hintKey.length) - 2)
      hint.el.style.top = top + 'px'
      hint.el.style.left = left + 'px'
    hintsRootEl.appendChild fragment
    hintsRootEl.classList.add CLASSNAME_ACTIVE
    return

  appendToQuery: (event) ->
    char = String.fromCharCode event.keyCode
    if HINT_CHARACTERS.indexOf(char) > -1
      stopKeyboardEvent event
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

  handleEscapeEvent: (event) ->
    if @query
      @query = ''
      @filterHints()
    else @deactivate()
    stopKeyboardEvent event
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
        view: w
        bubbles: true
        cancelable: true
        ctrlKey:  @openLinksInTabs && NEW_TAB_MODIFIER_KEY == 'ctrl'
        metaKey:  @openLinksInTabs && NEW_TAB_MODIFIER_KEY == 'meta'
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
  scrollTop = w.scrollY
  scrollLeft = w.scrollX
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
    rect.top >= w.innerHeight ||
    rect.left >= w.innerWidth ||
    rect.bottom <= 0 ||
    rect.right <= 0
  while el
    styles = w.getComputedStyle el
    return false if styles.display == 'none' ||
      styles.visibility == 'hidden' ||
      styles.opacity == '0'
    el = el.parentElement
  true

getCharacterFromEvent = (event) ->
  JSON.parse('"' + (event.keyIdentifier).replace('U+', '\\u') + '"').toLowerCase()

isActivationKey = (event) ->
  getCharacterFromEvent(event) == options.activationChar &&
    event.shiftKey == options.activationShift &&
    event.ctrlKey == options.activationCtrl &&
    event.altKey == options.activationAlt &&
    event.metaKey == options.activationMeta

isActivationTabKey = (event) ->
  getCharacterFromEvent(event) == options.activationTabChar &&
    event.shiftKey == options.activationTabShift &&
    event.ctrlKey == options.activationTabCtrl &&
    event.altKey == options.activationTabAlt &&
    event.metaKey == options.activationTabMeta

toggleHintMode = (openLinksInTabs) ->
  if hintMode
    if hintMode.openLinksInTabs != openLinksInTabs
      hintMode.openLinksInTabs = openLinksInTabs
    else hintMode.deactivate()
  else hintMode = new HintMode openLinksInTabs

handleKeydownEvent = (event) ->
  hasModifier = event.shiftKey || event.ctrlKey || event.altKey || event.metaKey
  if !canTypeInElement d.activeElement
    if hintMode && hintMode.hintMatch && event.keyCode == KEYCODE_RETURN && !canTypeInElement d.activeElement
      # Use keyup for triggering, only prevent keydown
      stopKeyboardEvent event
    else if isActivationKey event
      toggleHintMode false
      stopKeyboardEvent event
    else if isActivationTabKey event
      toggleHintMode true
      stopKeyboardEvent event
    else if !hasModifier && hintMode
      if event.keyCode == KEYCODE_ESC then hintMode.handleEscapeEvent event
      else hintMode.appendToQuery event
  return

handleKeyupEvent = (event) ->
  # Use keyup for triggering, because if we focus the target element on keydown
  # there will be a keyup event on the target element and that's annoying to deal with..
  if hintMode && hintMode.hintMatch && event.keyCode == KEYCODE_RETURN && !canTypeInElement d.activeElement
    stopKeyboardEvent event
    hintMode.triggerHintMatch()
  return

stopKeyboardEvent = (event) ->
  event.preventDefault()
  event.stopPropagation()
  event.stopImmediatePropagation()
  return

# Init

chrome.storage.sync.get Object.keys(DEFAULT_OPTIONS), (storageOptions) ->
  for own key, value of DEFAULT_OPTIONS
    options[key] = if storageOptions.hasOwnProperty key then storageOptions[key] else value
  return

d.addEventListener 'keydown', handleKeydownEvent, true
d.addEventListener 'keyup', handleKeyupEvent, true
