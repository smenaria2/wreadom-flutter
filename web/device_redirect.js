(function () {
  const hostname = window.location.hostname;

  // Skip redirection when running locally on localhost, 127.0.0.1, or local subnet IPs
  const isLocalHost =
    hostname === 'localhost' ||
    hostname === '127.0.0.1' ||
    hostname === '0.0.0.0' ||
    hostname.startsWith('192.168.') ||
    hostname.startsWith('10.') ||
    hostname.endsWith('.local');

  if (isLocalHost) {
    return;
  }

  const userAgent = navigator.userAgent || '';

  // 1. Apple devices (iPhone, iPad, iPod, iPadOS) -> Allow access to mobile web app
  const isIOS = /iPhone|iPad|iPod/.test(userAgent);
  const isIPadOS = navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1;
  const isAppleDevice = isIOS || isIPadOS;

  if (isAppleDevice) {
    return;
  }

  // 2. Android devices -> Redirect to Play Store app page
  const isAndroid = /Android/i.test(userAgent);
  if (isAndroid) {
    window.location.replace('https://play.google.com/store/apps/details?id=in.wreadom.app');
    return;
  }

  // 3. Desktop / non-mobile devices -> Redirect to main site wreadom.in
  const targetUrl = 'https://wreadom.in' + window.location.pathname + window.location.search + window.location.hash;
  window.location.replace(targetUrl);
})();
