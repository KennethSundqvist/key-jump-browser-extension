/* globals _browser */
// _browser is defined in bootstrap-state.js

// Initialize

const state = {}

window.__KEYJUMP__.bootstrapState(state, setup)

// Stuff

function setup() {
  const activationShortcutInput = document.getElementById(
    'activationShortcutInput',
  )
  const newTabActivationShortcutInput = document.getElementById(
    'newTabActivationShortcutInput',
  )

  const autoTriggerCheckbox = document.getElementById('autoTrigger')
  const activateNewTabCheckbox = document.getElementById('activateNewTab')
  const ignoreWhileInputFocusedCheckbox = document.getElementById(
    'ignoreWhileInputFocused',
  )
  const useLettersForHintsCheckbox =
    document.getElementById('useLettersForHints')

  const hintAlphabetInput = document.getElementById('hintAlphabetInput')

  activationShortcutInput.placeholder = getShortcutText(
    state.options.activationShortcut,
  )
  newTabActivationShortcutInput.placeholder = getShortcutText(
    state.options.newTabActivationShortcut,
  )

  autoTriggerCheckbox.checked = state.options.autoTrigger
  activateNewTabCheckbox.checked = state.options.activateNewTab
  useLettersForHintsCheckbox.checked = state.options.useLettersForHints
  ignoreWhileInputFocusedCheckbox.checked =
    state.options.ignoreWhileInputFocused

  hintAlphabetInput.value = state.options.hintAlphabet

  bindShortcutInput('activationShortcut', activationShortcutInput)
  bindShortcutInput('newTabActivationShortcut', newTabActivationShortcutInput)

  hintAlphabetInput.addEventListener('input', handleHintAlphabetInput)

  autoTriggerCheckbox.addEventListener('change', setAutoTrigger)
  activateNewTabCheckbox.addEventListener('change', setActivateNewTab)
  useLettersForHintsCheckbox.addEventListener('change', setUseLettersForHints)
  ignoreWhileInputFocusedCheckbox.addEventListener(
    'change',
    setIgnoreWhileInputFocused,
  )
}

function bindShortcutInput(optionsKey, inputElement) {
  inputElement.addEventListener('keydown', function setShortcut(event) {
    // Ignore Tab for accessibility reasons.
    if (event.key === 'Tab') {
      return
    }

    event.preventDefault()

    const shortcut = {
      key: event.key,
      shiftKey: event.shiftKey,
      ctrlKey: event.ctrlKey,
      altKey: event.altKey,
      metaKey: event.metaKey,
    }

    inputElement.placeholder = getShortcutText(shortcut)

    saveOptions({[optionsKey]: shortcut})
  })
}

function getShortcutText(shortcut) {
  let {key, metaKey, ctrlKey, altKey, shiftKey} = shortcut
  const parts = []

  if (metaKey) {
    switch (state.os) {
      case 'mac':
        parts.push('Command')
        break
      case 'win':
        parts.push('Win')
        break
      default:
        parts.push('Meta')
    }
  }

  ctrlKey && parts.push('Ctrl')
  altKey && parts.push('Alt')
  shiftKey && parts.push('Shift')

  if (!['Control', 'Alt', 'Shift', 'Meta'].includes(key)) {
    // Normalize all 1 character keys to uppercase because:
    // * The case varies depending on if the Shift key was used
    // * 1 character keys are usually displayed in uppercase on keyboards
    parts.push(key.length > 1 ? key : key.toLocaleUpperCase())
  }

  return parts.join(' + ')
}

function setAutoTrigger(event) {
  saveOptions({autoTrigger: event.target.checked})
}

function setActivateNewTab(event) {
  saveOptions({activateNewTab: event.target.checked})
}

function setIgnoreWhileInputFocused(event) {
  saveOptions({ignoreWhileInputFocused: event.target.checked})
}

function setUseLettersForHints(event) {
  saveOptions({useLettersForHints: event.target.checked})
}

function handleHintAlphabetInput(event) {
  // we want only alphanumeric characters
  const input = event.target.value
  const filteredInput = input.replace(/[^0-9A-Za-zÀ-ÖØ-öø-ÿ]/g, '')

  event.target.value = filteredInput
  saveOptions({
    hintAlphabet: filteredInput,
  })
}

function saveOptions(options) {
  _browser.storage.sync.set(options)
}
