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

d = document
optionEls = d.querySelectorAll 'input'

setOptionInStorage = (data) ->
  chrome.storage.sync.set data

getOptionFromStorage = (keys, callback) ->
  chrome.storage.sync.get keys, callback

setOptionInView = (option) ->
  for key, value of option
    el = d.querySelector "[name=#{key}]"
    type = el.getAttribute 'type'
    if type == 'checkbox' then el.checked = value
    else el.value = value

getOptionFromView = (event) ->
  data = {}
  type = event.target.getAttribute 'type'
  key = event.target.getAttribute 'name'
  if type == 'checkbox' then value = event.target.checked
  else value = event.target.value.toLowerCase()
  data[key] = value
  setOptionInStorage data

# Init

setOptionInView DEFAULT_OPTIONS

for el in optionEls
  type = el.getAttribute 'type'
  key = el.getAttribute 'name'
  getOptionFromStorage key, setOptionInView
  el.addEventListener 'change', getOptionFromView, false
  if type == 'text'
    el.addEventListener 'keypress', getOptionFromView, false
    el.addEventListener 'blur', getOptionFromView, false
