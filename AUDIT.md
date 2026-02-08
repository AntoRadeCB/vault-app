# 🔍 Vault App — Code Audit
*2026-02-08*

## 🗑️ File da eliminare (codice morto)

| File | Motivo |
|------|--------|
| `lib/services/catalog_cache_service.dart` | Mai importato da nessun file. Classe morta. |
| `lib/services/local_ocr_service.dart` | Mai importato da nessun file. Classe morta. |
| `lib/widgets/cached_card_image.dart` | Mai importato da nessun file. Widget morto. |
| `lib/widgets/tutorial_overlay.dart` | Mai importato da nessun file. Widget morto. |
| `generate_logo.py` | Script one-shot per generare il logo, non serve più. |
| `generate_logo.html` | Idem, file temporaneo per logo. |

## ⚠️ Dipendenza da rimuovere

| Pacchetto | Motivo |
|-----------|--------|
| `shared_preferences` | Usato SOLO in `catalog_cache_service.dart` (file morto). Se cancelli il file, puoi rimuovere anche il pacchetto da pubspec.yaml. |
| `camera` | Usato solo in `ocr_scanner_dialog_stub.dart` (fallback non-web). Se l'app è solo web, potenzialmente rimovibile. Ma è un conditional import, lascio a te. |

## 📏 File troppo grandi (>1000 righe)

| File | Righe | Suggerimento |
|------|-------|-------------|
| `settings_screen.dart` | 2111 | Splittare in widget separati (account settings, profile settings, ecc.) |
| `collection_screen.dart` | 1954 | Estrarre `_CardDetailOverlay` e `_CardDetailPage` in file separato |
| `open_product_screen.dart` | 1686 | Estrarre logica di apertura buste in servizio dedicato |
| `ocr_scanner_dialog_web.dart` | 1554 | Estrarre banner, strip results in widget separati |
| `inventory_screen.dart` | 1208 | Ok ma al limite |
| `dashboard_screen.dart` | 1105 | Ok ma al limite |
| `ocr_scanner_dialog_stub.dart` | 1081 | Mirror di _web, inevitabile |

## 🔗 `image_cache_service.dart` — Da valutare

Usato **solo** da `cached_card_image.dart` (che è morto). Se cancelli `cached_card_image.dart`, questo diventa morto anche lui → cancellare entrambi.

## ✅ Tutto il resto è usato

- `card_pull.dart` → usato in `open_product_screen.dart` e `firestore_service.dart`
- `cardvault_logo.dart` → usato in `auth_screen.dart`
- `card_browser_sheet.dart` → usato in `add_item_screen.dart`
- `coach_mark_overlay.dart` → usato in `main_shell.dart`
- Tutti gli screen sono referenziati da `main_shell.dart`
- Functions: `scanCard` e `scanCardOcr` sono attivi e usati

## 🧹 Azione consigliata

### Cancellare subito (6 file):
```
lib/services/catalog_cache_service.dart
lib/services/local_ocr_service.dart
lib/services/image_cache_service.dart
lib/widgets/cached_card_image.dart
lib/widgets/tutorial_overlay.dart
generate_logo.py
generate_logo.html
```

### Da pubspec.yaml rimuovere:
```
shared_preferences: ^2.5.4
```

### Nessun TODO/FIXME nel codice 👍

### Nessun import inutile trovato nei file attivi 👍
