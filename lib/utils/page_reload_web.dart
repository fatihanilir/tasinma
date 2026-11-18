import 'package:web/web.dart' as web;

bool reloadPage() {
  web.window.location.reload();
  return true;
}

bool goToUrl(String url) {
  web.window.location.href = url;
  return true;
}
