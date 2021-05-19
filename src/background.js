// `browser` is the standardised interface for Web Extensions, but Chrome
// doesn't support that yet.
const _browser = typeof browser !== 'undefined' ? browser : chrome

_browser.runtime.onMessage.addListener(async (request) => {
  const url = request?.openUrlInNewTab
  if (typeof url === 'string' && url) {
    _browser.tabs.query({active: true, currentWindow: true}, ([currentTab]) => {
      _browser.storage.sync.get('activateNewTab', (options) => {
        _browser.tabs.create({
          url,
          index: currentTab.index + 1,
          active: options.activateNewTab,
        })
      })
    })
  }
})
