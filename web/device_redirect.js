(function () {
  const hostname = window.location.hostname;
  const stayOnWebKey = 'wreadom_stay_on_web';

  // Allow Android users to opt into the web app with ?stay=1. Remember the
  // choice so internal navigation and later visits do not redirect them.
  const stayParam = new URLSearchParams(window.location.search).get('stay');
  if (stayParam === '1') {
    try {
      window.localStorage.setItem(stayOnWebKey, '1');
    } catch (_) {
      // The current page still stays open if storage is unavailable.
    }
    return;
  }

  try {
    if (window.localStorage.getItem(stayOnWebKey) === '1') {
      return;
    }
  } catch (_) {
    // Continue with the normal device redirect when storage is unavailable.
  }

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
