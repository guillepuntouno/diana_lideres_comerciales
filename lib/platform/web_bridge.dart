import 'dart:html' as html;

String getCurrentUrl() {
  return html.window.location.href;
}

String getCurrentOrigin() {
  return html.window.location.origin;
}

String? getCurrentPathname() {
  return html.window.location.pathname;
}

String getCurrentHash() {
  return html.window.location.hash;
}

void redirectTo(String url) {
  html.window.location.href = url;
}

void replaceState(String url) {
  html.window.history.replaceState(null, '', url);
}

String? getLocalStorage(String key) {
  return html.window.localStorage[key];
}

Future<void> setLocalStorage(String key, String value) async {
  html.window.localStorage[key] = value;
}

Future<void> removeLocalStorage(String key) async {
  html.window.localStorage.remove(key);
}

Map<String, String> getUrlParameters() {
  final hash = html.window.location.hash;
  if (hash.isEmpty) return {};
  
  final fragment = hash.substring(1); // remove #
  return Uri.splitQueryString(fragment);
}

void clearUrlFragment() {
  final pathname = html.window.location.pathname ?? '';
  html.window.history.replaceState(null, '', pathname);
}