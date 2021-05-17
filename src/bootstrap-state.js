// Workaround until dynamic imports are supported in browser extensions in all
// browsers.
const KJ = (window.__KEYJUMP__ = window.__KEYJUMP__ || {})
KJ.bootstrapState = function bootstrapState(state = {}, callback) {
  let gotInfo = false
  let gotOptions = false

  // Not available in content script.
  if (chrome.runtime.getPlatformInfo) {
    chrome.runtime.getPlatformInfo(getInfoCallback)
  } else {
    getInfoCallback({
      // Only need to know if Mac in the content script.
      os: navigator.platform.toLowerCase().includes('mac') ? 'mac' : 'unknown',
    })
  }

  function getInfoCallback(info) {
    state.os = info.os
    gotInfo = true
    runCallbackIfDone()
  }

  chrome.storage.sync.get(null, (options) => {
    state.options = processOptions(options)
    gotOptions = true
    runCallbackIfDone()
  })

  function runCallbackIfDone() {
    if (gotInfo && gotOptions) {
      callback(state)
    }
  }
}

function processOptions(options) {
  const defaultOptions = {
    optionsVersion: 2,
    activationShortcut: {
      key: ',',
      shiftKey: false,
      ctrlKey: false,
      altKey: false,
      metaKey: false,
    },
    newTabActivationShortcut: {
      key: '.',
      shiftKey: false,
      ctrlKey: false,
      altKey: false,
      metaKey: false,
    },
    autoTrigger: true,
    activateNewTab: true,
  }

  let saveOptions = false

  if (!options) {
    saveOptions = true
    options = defaultOptions
  }
  if (options.optionsVersion === 1) {
    saveOptions = true
    options.optionsVersion = 2
    options.activateNewTab = true
  }
  if (options.optionsVersion !== defaultOptions.optionsVersion) {
    saveOptions = true
    options = defaultOptions
  }

  // Save options even if they have not been changed so if we change the
  // defaults in the future we don't necessarily have to change them for
  // existing users who might have become used to the old default behaviour.
  if (saveOptions) {
    chrome.storage.sync.set(options)
  }

  return options
}
