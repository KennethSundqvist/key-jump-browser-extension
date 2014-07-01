"use strict"

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

getOptionFromView = (e) ->
  data = {}
  type = e.target.getAttribute 'type'
  key = e.target.getAttribute 'name'
  if type == 'checkbox' then value = e.target.checked
  else value = e.target.value.toLowerCase()
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
