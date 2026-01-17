importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-messaging.js");

firebase.initializeApp({
  apiKey: "AIzaSyDpQKAt_j3fQnN1o_yhFzaTGV7hsmWea1w",
  authDomain: "cadet-hub-7ac2d.firebaseapp.com",
  projectId: "cadet-hub-7ac2d",
  storageBucket: "cadet-hub-7ac2d.firebasestorage.app",
  messagingSenderId: "435777837540",
  appId: "1:435777837540:web:e79edf0666b64e2acfcff1",
  measurementId: "G-EWYXKK9JD6"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  // Customize notification here
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle,
    notificationOptions);
});
