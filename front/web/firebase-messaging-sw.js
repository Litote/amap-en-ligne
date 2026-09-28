importScripts("https://www.gstatic.com/firebasejs/12.13.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/12.13.0/firebase-messaging-compat.js");

// Keep in sync with lib/firebase_options.dart (web config).
firebase.initializeApp({
  apiKey: "AIzaSyPLACEHOLDER-WEB-00000000000000000000",
  authDomain: "amap-en-ligne-placeholder.firebaseapp.com",
  projectId: "amap-en-ligne-placeholder",
  storageBucket: "amap-en-ligne-placeholder.appspot.com",
  messagingSenderId: "000000000000",
  appId: "1:000000000000:web:0000000000000000000000",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  if (!payload.notification) return;
  self.registration.showNotification(payload.notification.title ?? "", {
    body: payload.notification.body,
    icon: "/icons/Icon-192.png",
  });
});
