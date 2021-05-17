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

  activationShortcutInput.placeholder = getShortcutText(
    state.options.activationShortcut,
  )
  newTabActivationShortcutInput.placeholder = getShortcutText(
    state.options.newTabActivationShortcut,
  )
  autoTriggerCheckbox.checked = state.options.autoTrigger

  bindShortcutInput('activationShortcut', activationShortcutInput)
  bindShortcutInput('newTabActivationShortcut', newTabActivationShortcutInput)
  autoTriggerCheckbox.addEventListener('change', setAutoTrigger)
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

function saveOptions(options) {
  chrome.storage.sync.set(options)
}
