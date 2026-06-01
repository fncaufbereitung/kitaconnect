importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAgYAij56R0oerq1Yyny8oDtNMebCKN4X4',
  authDomain: 'kitaconnectapp.firebaseapp.com',
  projectId: 'kitaconnectapp',
  storageBucket: 'kitaconnectapp.firebasestorage.app',
  messagingSenderId: '562865729062',
  appId: '1:562865729062:web:359c066138bcecee44c0e7',
  measurementId: 'G-8XY17YE5RN',
});

firebase.messaging();
