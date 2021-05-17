browser.runtime.onMessage.addListener((request) => {
  const url = request?.openUrlInNewTab
  if (typeof url === 'string' && url) {
    browser.storage.sync.get('activateNewTab', (options) => {
      browser.tabs.create({
        url,
        active: options.activateNewTab,
      })
    })
  }
})
