browser.runtime.onMessage.addListener(async (request) => {
  const url = request?.openUrlInNewTab
  if (typeof url === 'string' && url) {
    const [currentTab] = await browser.tabs.query({active: true})
    browser.storage.sync.get('activateNewTab', (options) => {
      browser.tabs.create({
        url,
        index: currentTab.index + 1,
        active: options.activateNewTab,
      })
    })
  }
})
