# Tandbørste QR-Scanner ved Notification Implementation

## Oversigt
Implementeret funktionalitet til at vise QR-scanner når brugeren trykker på tandbørste-reminderen notifikation.

## Ændringer

### 1. BostedApp.swift
- **Tilføjet NotificationDelegate klasse**:
  - Håndterer notification taps via `UNUserNotificationCenterDelegate`
  - Detekterer tandbørste-notifikationer ved at tjekke `userInfo["type"] == "toothbrush"`
  - Sætter `shouldShowToothbrushScanner` til `true` når notifikationen trykkes
  - Logger alle notification events med FileLogger

- **Opdateret app struktur**:
  - Oprettet `@StateObject` for `NotificationDelegate`
  - Sendt notificationDelegate til ContentView og MainView


### 2. MainView.swift
- **Tilføjet parameter**: `@ObservedObject var notificationDelegate: NotificationDelegate`
- **Tilføjet state**: `@State private var shouldShowQRScanner = false`
- **Tilføjet onChange handler**:
  ```swift
  .onChange(of: notificationDelegate.shouldShowToothbrushScanner) { _, newValue in
      if newValue {
          // Naviger til tandbørste view og vis QR scanner
          selectedTab = .toothbrush
          shouldShowQRScanner = true
          
          // Nulstil notification flag
          notificationDelegate.shouldShowToothbrushScanner = false
      }
  }
  ```
- **Opdateret ToothbrushView call**: Sender `shouldShowQRScanner` binding

### 3. ToothbrushView.swift
- **Tilføjet parameter**: `@Binding var shouldShowQRScanner: Bool`
- **Opdateret initializer**: Modtager shouldShowQRScanner binding
- **Tilføjet onChange handler**:
  ```swift
  .onChange(of: shouldShowQRScanner) { _, newValue in
      if newValue {
          // Vis QR scanner
          showQRScanner = true
          // Nulstil binding
          shouldShowQRScanner = false
      }
  }
  ```

### 4. Info.plist
- ✅ Kamera tilladelser allerede konfigureret:
  - `NSCameraUsageDescription`: "BostedApp har brug for adgang til kameraet for at scanne QR-koder til tandbørstningspåmindelser."

### 5. NotificationManager.swift
- ✅ Notifikationer allerede konfigureret med:
  - `categoryIdentifier = "TOOTHBRUSH_REMINDER"`
  - `userInfo = ["type": "toothbrush", "reminderId": id]`

## Funktionsflow

1. **Tandbørste reminder notifikation vises** på det planlagte tidspunkt
2. **Bruger trykker på notifikationen**
3. **NotificationDelegate.didReceive** kaldes
4. **Detekterer toothbrush type** i userInfo
5. **Sætter shouldShowToothbrushScanner = true**
6. **MainView.onChange** detekterer ændringen
7. **Navigerer til .toothbrush tab**
8. **Sætter shouldShowQRScanner = true**
9. **ToothbrushView.onChange** detekterer ændringen
10. **Viser QR scanner fullscreen**
11. **Bruger scanner QR-kode** på badeværelsesspejlet
12. **QR kode valideres** i handleQRCode()

## Test Guide

### Forudsætninger
1. Åbn projektet i Xcode på macOS
2. Build og kør på en iOS enhed eller simulator (iOS 17+)
3. Giv tilladelse til notifikationer og kamera

### Test Scenario 1: Notification Tap fra Låst Skærm
1. Tilføj en tandbørste reminder (f.eks. om 1 minut)
2. Lås enheden
3. Vent på notifikationen
4. Tryk på notifikationen
5. **Forventet**: App åbner direkte med QR scanner vist

### Test Scenario 2: Notification Tap fra App i Forgrund
1. Tilføj en tandbørste reminder (f.eks. om 1 minut)
2. Hold app åben på en anden tab (f.eks. Hjem)
3. Vent på notifikationen
4. Tryk på notifikationsbanneret
5. **Forventet**: Navigerer til tandbørste tab og viser QR scanner

### Test Scenario 3: Notification Tap fra Notification Center
1. Tilføj en tandbørste reminder
2. Swipe ned for at åbne Notification Center
3. Tryk på tandbørste notifikationen
4. **Forventet**: App åbner med QR scanner

### Test QR Kode Scanning
1. Opret en QR-kode med tekst som indeholder:
   - "bathroom_mirror", ELLER
   - "tandbørstning_spejl", ELLER
   - "tandbørstning", ELLER
   - "toothbrush"
2. Scan QR-koden når scanneren vises
3. **Forventet**: Console viser "✅ Valid toothbrush QR code scanned"

### Debug Log
Følg notification flow i Xcode console eller LogViewerView:
- `🔔 Notification tapped: [userInfo]`
- `🪥 Toothbrush notification tapped - showing QR scanner`

## Kendte Begrænsninger
- QR kode validering er basic (tjekker kun for nøgleord)
- Ingen visuel feedback når QR kode er scannet korrekt
- Reminder markeres ikke automatisk som "completed"

## Fremtidige Forbedringer
1. Tilføj success/error alert efter QR scan
2. Marker reminder som completed i database
3. Vis scanning historik
4. Tilføj support for forskellige QR kode formater
5. Implementer streak tracking for tandbørstning

## Tekniske Detaljer

### SwiftUI Bindings
Bruger `@Binding` til at kommunikere mellem views:
- MainView → ToothbrushView: `shouldShowQRScanner`
- Unidirektional data flow sikrer clean state management

### Notification Delegate Pattern
- NotificationDelegate er `@MainActor` for UI opdateringer
- Bruger `@Published` for reactive state changes
- Automatically registrerer sig som delegate i `init()`

### Camera Permissions
- Automatisk request ved første QR scanner brug
- Bruger AVFoundation framework
- Real-time QR code detection med AVCaptureMetadataOutput

## Support
Ved problemer, tjek:
1. Notification tilladelser i iOS Settings
2. Kamera tilladelser i iOS Settings
3. FileLogger output for debug information
4. Xcode console for fejlmeddelelser