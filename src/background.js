browser.runtime.onMessage.addListener((request) => {
  const url = request?.openUrlInNewTab
  if (typeof url === 'string' && url) {
    browser.tabs.create({
      url,
      // TODO: Maybe turn into an extension option?
      active: true,
    })
  }
})
