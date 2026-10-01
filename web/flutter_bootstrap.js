{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async (engineInitializer) => {
    const appRunner = await engineInitializer.initializeEngine();
    const loading = document.getElementById('loading');
    if (loading) loading.remove();
    await appRunner.runApp();

    const isLocal = ['localhost', '127.0.0.1', '[::1]'].includes(
      window.location.hostname,
    );
    const isPwaTest = new URLSearchParams(window.location.search).has(
      'pwa-test',
    );
    if ('serviceWorker' in navigator && (!isLocal || isPwaTest)) {
      navigator.serviceWorker.register('./sw.js').catch((error) => {
        console.warn('离线缓存启用失败：', error);
      });
    }
  },
});
