# 📦 Vault — Reselling Tracker

> App Flutter per il tracking completo delle attività di reselling: acquisti, vendite, inventario e reportistica.

---

## 1. Panoramica

| | |
|---|---|
| **Nome** | Vault — Reselling Tracker |
| **Versione** | 1.0.0 |
| **Scopo** | Gestione inventario, acquisti, vendite e profitti per reseller su piattaforme come Vinted, eBay, Depop |
| **Frontend** | Flutter (Dart) — Web, iOS, Android |
| **Backend** | Firebase (Firestore + Auth) |
| **Font** | Google Fonts — Inter |
| **Tema** | Dark-only con glassmorphism, gradienti aurora e animazioni staggered |

### Architettura

```
┌──────────────────────────────────────────┐
│              Flutter App (UI)            │
│  ┌─────────┐ ┌──────────┐ ┌───────────┐ │
│  │ Screens │ │ Widgets  │ │  Models   │ │
│  └────┬────┘ └────┬─────┘ └─────┬─────┘ │
│       │           │             │        │
│  ┌────▼───────────▼─────────────▼─────┐  │
│  │           Theme / Design System    │  │
│  └────────────────┬───────────────────┘  │
└───────────────────┼──────────────────────┘
                    │
        ┌───────────▼───────────┐
        │   Firebase Backend    │
        │  ┌─────────────────┐  │
        │  │  Firebase Auth   │  │
        │  │  (email/pass)    │  │
        │  └─────────────────┘  │
        │  ┌─────────────────┐  │
        │  │ Cloud Firestore  │  │
        │  │ (products, sales │  │
        │  │  purchases)      │  │
        │  └─────────────────┘  │
        └───────────────────────┘
```

L'app è attualmente in modalità **demo/mock** con dati statici. L'integrazione Firebase è predisposta nel `pubspec.yaml` (firebase_core, cloud_firestore, firebase_auth) ma i servizi AuthService e FirestoreService sono ancora da implementare.

---

## 2. Struttura Progetto

```
lib/
├── main.dart                          # Entry point, MaterialApp, MainShell (nav + layout)
├── models/
│   └── product.dart                   # Modello Product + enum ProductStatus + sample data
├── screens/
│   ├── dashboard_screen.dart          # Dashboard con stat cards, azioni rapide, stato operativo
│   ├── inventory_screen.dart          # Lista inventario con tabs, ricerca, swipe-to-delete
│   ├── add_item_screen.dart           # Form nuovo acquisto con validazione
│   ├── reports_screen.dart            # Statistiche vendite, export, transazioni recenti
│   └── settings_screen.dart           # Profilo, account, workspace, notifiche, aspetto, info
├── theme/
│   └── app_theme.dart                 # AppColors, gradienti, ThemeData dark
└── widgets/
    └── animated_widgets.dart          # Widget custom animati riutilizzabili
```

### Descrizione file per file

| File | Descrizione |
|------|-------------|
| `main.dart` | Configura `MaterialApp` con tema dark. `MainShell` gestisce la navigazione: sidebar (desktop ≥800px) o bottom nav (mobile) + FAB. Include `AnimatedSwitcher` per transizioni fluide tra schermate. Barra di ricerca globale con shortcut ⌘K sul desktop. |
| `models/product.dart` | Definisce `Product` (name, brand, quantity, price, status, imageUrl), `ProductStatus` enum (shipped, inInventory, listed), helper per formattazione prezzo/quantità, e `sampleProducts` statici per la demo. |
| `screens/dashboard_screen.dart` | Mostra header "Reselling Vinted 2025" con status ONLINE, 4 stat card animate (Capitale Immobilizzato, Ordini in Arrivo, Capitale Spedito, Profitto Consolidato), 2 action button (Nuovo Acquisto, Registra Vendita), sezione Stato Operativo. Usa `AuroraBackground` per l'effetto nebula. |
| `screens/inventory_screen.dart` | Due tab: "Storico Record" (lista prodotti con card swipeable) e "Riepilogo Prodotti" (summary cards aggregate). Barra di ricerca con filtro real-time su nome/brand. Ogni prodotto mostra icona brand, nome, prezzo, quantità e badge status colorato. |
| `screens/add_item_screen.dart` | Form con campi: Nome Oggetto (con scanner QR placeholder), Prezzo Acquisto (€), Quantità, Workspace (dropdown). Validazione inline con `autovalidateMode`. Submit mostra SnackBar di conferma. Ogni campo usa `_GlowTextField` custom con glow blu al focus. |
| `screens/reports_screen.dart` | Due stat card animate (Sales Count, Total Fees Paid con CountUp), sezione Export History (CSV, PDF, Monthly Log con feedback download), sezione Recent Transactions con card income/expense colorate. |
| `screens/settings_screen.dart` | Schermata più complessa: profilo utente editabile, sezione Account (email, password, 2FA), Workspace (selezione, auto-backup, export), Notifiche (in-app, push, email digest), Aspetto (dark mode, font size, accent color), Info (versione, ToS, privacy, bug report), bottone Logout. Usa bottom sheet interattivi per edit, selezione e info. |
| `theme/app_theme.dart` | Definisce `AppColors` (12 colori + 5 gradienti) e `AppTheme.darkTheme` con Google Fonts Inter. Include stili per card, input, bottom nav. |
| `widgets/animated_widgets.dart` | 10 widget animati riutilizzabili (vedi sezione 4). |

---

## 3. Schermate

### 🏠 Dashboard (`DashboardScreen`)

La homepage dell'app. Mostra una panoramica finanziaria in tempo reale.

| Componente | Dettaglio |
|---|---|
| **Header** | GlassCard con titolo workspace, PulsingDot "ONLINE", PulsingBadge notifiche (3) |
| **Stat Cards** | GridView 2×2: Capitale Immobilizzato (€130, blu), Ordini in Arrivo (€120, teal), Capitale Spedito (€45, arancione), Profitto Consolidato (€1470, verde). Ogni card usa CountUpText animato + HoverLiftCard |
| **Action Buttons** | 2 ShimmerButton: "Nuovo Acquisto" (gradiente blu→viola), "Registra Vendita" (gradiente verde) |
| **Stato Operativo** | GlassCard con notifiche: "2 Spedizioni in transito" (blu), "Stock basso: Nike Air Max" (arancione) |
| **Background** | AuroraBackground con blob nebulosi animati (blu, viola, teal) |

### 📦 Inventory (`InventoryScreen`)

Gestione prodotti con due viste.

| Componente | Dettaglio |
|---|---|
| **Header** | Titolo "Inventario" + badge "{n} RECORDS" |
| **Tab Bar** | "Storico Record" / "Riepilogo Prodotti" — indicatore con gradiente blu→viola |
| **Ricerca** | TextField con glow blu al focus, filtra per nome e brand in real-time |
| **Lista Prodotti** | Card dismissible (swipe dx→sx per eliminare), icona brand colorata, nome, brand badge, quantità, prezzo, status badge |
| **Riepilogo** | 4 summary card: Valore Totale, Prodotti Spediti, In Inventario, In Vendita |

**Status Badge colori:**
- 🔴 SHIPPED — `#FF6B6B`
- 🔵 IN INVENTORY — `#667eea`
- 🟢 LISTED — `#4CAF50`

### ➕ Add Item (`AddItemScreen`)

Form per registrare un nuovo acquisto.

| Campo | Tipo | Validazione |
|---|---|---|
| Nome Oggetto | Text + QR scanner button | Campo obbligatorio |
| Prezzo Acquisto | Number, prefisso "€" | Obbligatorio, deve essere un numero valido |
| Quantità | Number, default "1" | Obbligatorio, deve essere un intero |
| Workspace | Dropdown | Pre-selezionato "Reselling Vinted 2025" |

Submit: validazione form → SnackBar verde "Acquisto registrato con successo!" → torna indietro.

### 📊 Reports (`ReportsScreen`)

Statistiche e export.

| Componente | Dettaglio |
|---|---|
| **Stat Cards** | Sales Count (2, blu), Total Fees Paid (€51.15, rosso) — entrambe con CountUpText |
| **Export** | 3 card: CSV Full History (verde), PDF Tax Summary (rosso), Monthly Sales Log (blu). Tap su download → icona check con feedback animato |
| **Transazioni** | Card con nome prodotto, income (+€), expense (-€). Verde = vendita completata, neutro = in attesa |

### ⚙️ Settings (`SettingsScreen`)

Impostazioni complete dell'app organizzate in sezioni.

| Sezione | Elementi |
|---|---|
| **Profilo** | Avatar con iniziale, nome, email, badge "PRO PLAN", bottone edit |
| **Account** | Email (edit), Password (edit), 2FA (info sheet, badge "ON") |
| **Workspace** | Workspace attivo (select fra Vinted/eBay/Depop/Crypto), Auto Backup (switch), Esporta Dati (bottom sheet CSV/PDF/JSON) |
| **Notifiche** | In-App (switch), Push (switch), Email Digest (switch) |
| **Aspetto** | Dark Mode (switch), Font Size (select Small/Medium/Large/XL), Accent Color (select con dot colorati) |
| **Info** | Versione (v1.0.0), Termini di Servizio (info sheet), Privacy Policy (info sheet), Segnala Bug (edit sheet) |
| **Logout** | Bottone rosso con dialog di conferma |

**Interazioni bottom sheet:**
- **Edit Sheet** — TextField per modificare valori (nome, email, password con conferma)
- **Select Sheet** — Lista opzioni con check su selezione corrente
- **Info Sheet** — Testo lungo con bottone "Chiudi"
- **Export Sheet** — 3 opzioni (CSV, PDF, JSON) con icona e descrizione

### 🔐 Auth (in arrivo)

Firebase Auth è nel `pubspec.yaml` ma non ancora implementato. La struttura prevede:
- Login con email/password
- Registrazione nuovo utente
- Integrazione con `firebase_auth: ^5.5.2`

---

## 4. Temi e Design System

### Palette Colori

| Nome | Hex | Uso |
|---|---|---|
| `background` | `#0F0F1A` | Sfondo principale |
| `surface` | `#1A1A2E` | Card, input, superfici secondarie |
| `surfaceLight` | `#252542` | Superfici elevate |
| `cardDark` | `#16162A` | Card scure |
| `navBar` | `#0D0D1A` | Barra navigazione |
| `textPrimary` | `#FFFFFF` | Testo principale |
| `textSecondary` | `#C4C4D4` | Testo secondario |
| `textMuted` | `#6E6E88` | Testo muted/placeholder |
| `accentBlue` | `#667EEA` | Colore primario, selezione, link |
| `accentPurple` | `#764BA2` | Secondario, gradienti |
| `accentGreen` | `#4CAF50` | Successo, profitto, online |
| `accentRed` | `#E53935` | Errore, spese, logout |
| `accentOrange` | `#FF9800` | Warning, spedizioni |
| `accentTeal` | `#26C6DA` | Info, ordini in arrivo |
| `glowBorder` | `#667EEA` | Glow borders |

### Gradienti

| Nome | Colori | Uso |
|---|---|---|
| `headerGradient` | `#667EEA` → `#764BA2` | Header, logo, avatar profilo |
| `blueButtonGradient` | `#667EEA` → `#764BA2` | CTA button, FAB, tab indicator |
| `statCardGradient1` | `#1A1A35` → `#152040` | Stat card background |
| `statCardGradient2` | `#1A1A35` → `#153035` | Stat card background alternativo |
| `auroraGradient` | `#667EEA` (0%→33%→22%→0%) | Background aurora |

### Widget Custom

| Widget | Descrizione |
|---|---|
| `GlassCard` | Container glassmorphism con `BackdropFilter`, blur 12px, bordo glow configurabile, ombra colorata |
| `ShimmerButton` | Bottone con gradiente + effetto shimmer orizzontale continuo (2.5s loop) + ScaleOnPress |
| `AuroraBackground` | Sfondo con 3 blob nebulosi (blu, viola, teal) animati in loop 8s + arco di luce superiore |
| `HoverLiftCard` | Wrapper che solleva la card di N pixel al mouse hover (desktop) con ombra glow blu |
| `ScaleOnPress` | Wrapper che scala al 96% durante il tap (120ms, easeInOut) |
| `AnimatedFab` | FAB circolare con gradiente blu→viola, rotazione 45° al tap, glow shadow |

### Animazioni

| Widget | Effetto | Durata |
|---|---|---|
| `StaggeredFadeSlide` | Fade-in + slide-up dal basso, delay basato su index (80ms × index) | 500ms |
| `PulsingDot` | Cerchio pulsante con glow shadow oscillante | 1500ms (loop) |
| `PulsingBadge` | Badge notifica con scala pulsante (1.0 → 1.15) | 2000ms (loop) |
| `CountUpText` | Contatore numerico da 0 al valore target con curva easeOutCubic | 1200ms |
| `AnimatedFab` | Rotazione 45° al tap + gradiente glow | 300ms |
| `ShimmerButton` | Riga luminosa che scorre orizzontalmente | 2500ms (loop) |

---

## 5. Modelli Dati

### Product

```dart
enum ProductStatus { shipped, inInventory, listed }

class Product {
  final String name;          // "Nike Air Max 90"
  final String brand;         // "NIKE"
  final double quantity;      // 1, 2, 0.25
  final double price;         // 45.00
  final ProductStatus status; // shipped | inInventory | listed
  final String? imageUrl;     // URL immagine (opzionale)
}
```

**Helper methods:**
- `statusLabel` → "SHIPPED" / "IN INVENTORY" / "LISTED"
- `formattedPrice` → "€45" / "€45000" / "€12.50"
- `formattedQuantity` → "1" / "0.25"
- `sampleProducts` → 4 prodotti demo (Nike, Adidas, Stone Island, Bitcoin)

### Purchase (da implementare)

```dart
class Purchase {
  final String id;
  final String productName;
  final double price;
  final int quantity;
  final DateTime date;
  final String workspace;
}
```

### Sale (da implementare)

```dart
class Sale {
  final String id;
  final String productName;
  final double salePrice;
  final double purchasePrice;
  final double fees;
  final DateTime date;
}
```

### Struttura Firestore

```
firestore/
├── users/
│   └── {uid}/
│       ├── email: string
│       ├── name: string
│       ├── plan: string ("free" | "pro")
│       └── createdAt: timestamp
│
├── products/
│   └── {productId}/
│       ├── name: string
│       ├── brand: string
│       ├── quantity: number
│       ├── price: number
│       ├── status: string ("shipped" | "inInventory" | "listed")
│       ├── workspace: string
│       ├── imageUrl: string?
│       ├── userId: string (ref → users)
│       └── createdAt: timestamp
│
├── purchases/
│   └── {purchaseId}/
│       ├── productName: string
│       ├── price: number
│       ├── quantity: number
│       ├── date: timestamp
│       ├── workspace: string
│       └── userId: string
│
└── sales/
    └── {saleId}/
        ├── productName: string
        ├── salePrice: number
        ├── purchasePrice: number
        ├── fees: number
        ├── date: timestamp
        └── userId: string
```

---

## 6. Servizi

### AuthService (da implementare)

```dart
class AuthService {
  // Login con email e password
  Future<User> login(String email, String password);
  
  // Registrazione nuovo utente
  Future<User> register(String email, String password, String name);
  
  // Logout
  Future<void> logout();
  
  // Utente corrente
  User? get currentUser;
  
  // Stream stato autenticazione
  Stream<User?> get authStateChanges;
}
```

### FirestoreService (da implementare)

```dart
class FirestoreService {
  // ── Products ──
  Future<List<Product>> getProducts({String? workspace, String? status});
  Future<Product> getProduct(String id);
  Future<void> addProduct(Product product);
  Future<void> updateProduct(String id, Product product);
  Future<void> deleteProduct(String id);
  Stream<List<Product>> productsStream({String? workspace});
  
  // ── Purchases ──
  Future<List<Purchase>> getPurchases({DateTime? from, DateTime? to});
  Future<void> addPurchase(Purchase purchase);
  
  // ── Sales ──
  Future<List<Sale>> getSales({DateTime? from, DateTime? to});
  Future<void> addSale(Sale sale);
  
  // ── Stats ──
  Future<DashboardStats> getDashboardStats();
  Future<ReportStats> getReportStats();
  
  // ── Export ──
  Future<String> exportCSV();
  Future<Uint8List> exportPDF();
  
  // ── User Profile ──
  Future<UserProfile> getProfile();
  Future<void> updateProfile(UserProfile profile);
}
```

---

## 7. Setup & Deploy

### Requisiti

- **Flutter SDK** ≥ 3.8.1
- **Dart SDK** ≥ 3.8.1
- **Firebase CLI** (per configurazione backend)
- **Node.js** (per Firebase CLI)

### Installazione

```bash
# Clona il repository
git clone https://github.com/AntoRadeCB/vault-app.git
cd vault-app

# Installa dipendenze
flutter pub get

# Avvia in modalità debug
flutter run -d chrome        # Web
flutter run -d ios            # iOS Simulator
flutter run -d android        # Android Emulator
```

### Build per produzione

```bash
# Build web
flutter build web --release

# L'output sarà in build/web/
```

### Deploy su GitHub Pages

```bash
# 1. Build
flutter build web --release --base-href "/vault-app/"

# 2. Deploy manuale
cd build/web
git init
git add .
git commit -m "Deploy"
git remote add origin https://github.com/AntoRadeCB/vault-app.git
git push -f origin main:gh-pages

# Oppure usa il pacchetto peanut:
# dart pub global activate peanut
# peanut --directory build/web
```

L'app sarà disponibile su: `https://antoradecb.github.io/vault-app/`

---

## 8. Configurazione Firebase

### Setup iniziale

```bash
# 1. Installa Firebase CLI
npm install -g firebase-tools

# 2. Login
firebase login

# 3. Inizializza nel progetto
cd vault-app
firebase init

# 4. Configura Flutter (usa FlutterFire CLI)
dart pub global activate flutterfire_cli
flutterfire configure
```

### File di configurazione

Il comando `flutterfire configure` genera automaticamente `lib/firebase_options.dart`.

> ⚠️ **IMPORTANTE:** Non committare mai chiavi API o `google-services.json` nel repository pubblico. Aggiungi al `.gitignore`:
> ```
> lib/firebase_options.dart
> android/app/google-services.json
> ios/Runner/GoogleService-Info.plist
> ```

### Struttura Database

Vedi sezione [5. Modelli Dati → Struttura Firestore](#struttura-firestore) per lo schema completo.

### Regole di Sicurezza Consigliate

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Utenti: possono leggere/scrivere solo il proprio profilo
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Prodotti: CRUD solo per il proprio userId
    match /products/{productId} {
      allow read: if request.auth != null 
                  && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null 
                    && request.resource.data.userId == request.auth.uid;
      allow update, delete: if request.auth != null 
                            && resource.data.userId == request.auth.uid;
    }
    
    // Acquisti: stesso pattern
    match /purchases/{purchaseId} {
      allow read: if request.auth != null 
                  && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null 
                    && request.resource.data.userId == request.auth.uid;
      allow update, delete: if request.auth != null 
                            && resource.data.userId == request.auth.uid;
    }
    
    // Vendite: stesso pattern
    match /sales/{saleId} {
      allow read: if request.auth != null 
                  && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null 
                    && request.resource.data.userId == request.auth.uid;
      allow update, delete: if request.auth != null 
                            && resource.data.userId == request.auth.uid;
    }
    
    // Default: nega tutto
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### Indici Firestore Consigliati

```
Collection: products
  Fields: userId (ASC), workspace (ASC), createdAt (DESC)

Collection: purchases
  Fields: userId (ASC), date (DESC)

Collection: sales
  Fields: userId (ASC), date (DESC)
```

---

## Dipendenze

| Pacchetto | Versione | Scopo |
|---|---|---|
| `flutter` | SDK | Framework UI |
| `cupertino_icons` | ^1.0.8 | Icone iOS-style |
| `google_fonts` | ^6.2.1 | Font Inter |
| `firebase_core` | ^3.13.0 | Inizializzazione Firebase |
| `cloud_firestore` | ^5.6.6 | Database NoSQL |
| `firebase_auth` | ^5.5.2 | Autenticazione |

---

## Licenza

Progetto privato — tutti i diritti riservati.

---

*Documentazione generata automaticamente dall'analisi del codice sorgente.*
