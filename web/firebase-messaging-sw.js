// Service worker Firebase Cloud Messaging : gère les notifications push
// reçues côté web quand l'onglet/l'app n'a pas le focus.
// Doit rester à la racine servie (web/) pour être trouvé automatiquement
// par le plugin firebase_messaging.

importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDNl-igGB6Tg6GQearMtx7C7wLS2wdJ3q4',
  authDomain: 'epuici-app.firebaseapp.com',
  projectId: 'epuici-app',
  storageBucket: 'epuici-app.firebasestorage.app',
  messagingSenderId: '557547997095',
  appId: '1:557547997095:web:a6b7ab73844f96a88dd882',
});

firebase.messaging();
