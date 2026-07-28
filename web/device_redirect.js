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

  // Detect Apple mobile & tablet devices (iPhone, iPad, iPod, iPadOS)
  const userAgent = navigator.userAgent || '';
  const isIOS = /iPhone|iPad|iPod/.test(userAgent);
  const isIPadOS = navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1;
  const isAppleDevice = isIOS || isIPadOS;

  // Redirect non-Apple devices to main site wreadom.in
  if (!isAppleDevice) {
    const targetUrl = 'https://wreadom.in' + window.location.pathname + window.location.search + window.location.hash;
    window.location.replace(targetUrl);
  }
})();
