# Rebost

Una app per a la gestió del rebost domèstic. Feta amb Flutter.

## Funcionalitats

### Autenticació i perfils
- Creació de comptes locals amb nom, nom d'usuari, correu electrònic opcional i contrasenya
- Contrasenyes encriptades amb SHA-256 (10.000 iteracions + salt aleatori de 32 bytes)
- Pantalla d'inici amb opcions d'iniciar sessió i crear compte
- Suport per a múltiples perfils al mateix dispositiu

### Dashboard
- Salutació personalitzada segons l'hora del dia
- Resum ràpid: total de productes, per caducar aviat, caducats
- Notificacions de caducitat amb cercles de colors (verd, taronja, vermell)
- Accions ràpides: obrir, consumir i descartar productes directament

### El meu rebost
- Gestió completa de productes: afegir, editar i eliminar
- Tipus de producte personalitzables (~20 tipus per defecte: fruita, verdura, lactis, etc.)
- Ubicacions personalitzables (nevera, congelador, rebost, etc.)
- Data de compra i data de caducitat
- Gestió de quantitats amb botons +/- i divisió de productes oberts
- Control d'estat: disponible, obert, consumit, descartat

### Rebost compartit
- Compartir el rebost amb altres usuaris mitjançant invitacions
- Sistema d'invitacions amb acceptar/rebutjar
- Visualització dels productes dels rebosts compartits

### Llista de la compra
- Creació manual de productes a comprar
- Afegir productes automàticament quan es consumeix/descarta l'últim del rebost
- Selecció múltiple per comprar diversos productes alhora
- Opcions: comprar individual, comprar seleccionats o comprar-ho tot

### Notificacions
- Avisos de productes a punt de caducar (5 dies o menys)
- Avisos de productes ja caducats
- Indicadors visuals al dashboard amb cercles de colors

## Tecnologia

- **Framework**: Flutter 3.41 / Dart 3.11
- **Gestió d'estat**: Provider amb ChangeNotifier
- **Emmagatzematge**: SharedPreferences (dades locals)
- **Seguretat**: SHA-256 amb salt per a contrasenyes
- **Dependències**: provider, shared_preferences, path_provider, uuid, crypto

## Començar

### Requisits

- [Flutter SDK](https://flutter.dev/docs/get-started/install) >= 3.41
- Dart SDK (inclòs amb Flutter)

### Instal·lació

```bash
flutter pub get
```

### Executar

```bash
flutter run
```

### Plataformes

L'app funciona a totes les plataformes suportades per Flutter: Android, iOS, web, Windows, macOS i Linux.
