// Uygulama eskiden kök dizinde çalışıyordu ve Flutter bu adreste bir service
// worker kaydediyordu. Uygulama /hesapla/ altına taşındığı için eski kayıt,
// ana sayfanın önbellekten eski uygulama olarak açılmasına yol açabilir.
// Bu dosya eski kaydı temizleyip kendini kaldırır.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.map((key) => caches.delete(key)));
    await self.registration.unregister();
    const clients = await self.clients.matchAll({ type: 'window' });
    clients.forEach((client) => client.navigate(client.url));
  })());
});
