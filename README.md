# BostedApp iOS - Xcode Projekt

Dette er det komplette iOS Xcode projekt for BostedApp, klar til at åbne i Xcode.

## Sådan åbner du projektet

1. **Åbn projektet i Xcode:**
   - Dobbeltklik på `BostedApp.xcodeproj` ELLER
   - Åbn Xcode og vælg File → Open → Vælg `BostedApp.xcodeproj`

2. **Kopier Swift kildekodefiler:**
   - Swift-filerne skal kopieres fra `../Swift/Sources/` til `BostedApp/` mappen
   - Se instruktioner nedenfor

## Kopiering af kildekodefiler

Kør disse kommandoer fra `BostedAppIOS` mappen:

```bash
# Opret mapper
mkdir -p BostedApp/Views/Components
mkdir -p BostedApp/ViewModels
mkdir -p BostedApp/Models
mkdir -p BostedApp/API

# Kopier filer (Windows PowerShell)
Copy-Item ..\Swift\Sources\App\BostedApp.swift BostedApp\BostedAppApp.swift
Copy-Item ..\Swift\Sources\Views\*.swift BostedApp\Views\
Copy-Item ..\Swift\Sources\Views\Components\*.swift BostedApp\Views\Components\
Copy-Item ..\Swift\Sources\ViewModels\*.swift BostedApp\ViewModels\
Copy-Item ..\Swift\Sources\Models\*.swift BostedApp\Models\
Copy-Item ..\Swift\Sources\API\*.swift BostedApp\API\
```

**VIGTIGT:** Filerne skal muligvis rettes efter kopiering - se "Nødvendige rettelser" nedenfor.

## Nødvendige rettelser til iOS

Efter kopiering skal følgende rettes i filerne:

### 1. Activity.swift
Tilføj manglende properties:
```swift
struct Activity: Codable, Identifiable {
    let id: String
    let title: String
    let content: String?
    let startDateTime: String
    let endDateTime: String
    let requiresRegistration: Bool
    let registrationDeadline: String?
    let subLocationName: String?  // TILFØJ DENNE
    let registeredEmails: [String] = []  // TILFØJ DENNE
    
    // ... resten af koden
}
```

### 2. LoginView.swift
Ret iOS-specifikke modifiers:
```swift
TextField("Email", text: $email)
    .textFieldStyle(RoundedBorderTextFieldStyle())
    .textInputAutocapitalization(.never)  // Ret fra .autocapitalization
    .keyboardType(.emailAddress)
    .padding(.horizontal)
```

### 3. ActivityViewModel.swift
Ret ID type fra Int til String:
```swift
func toggleRegistration(activityId: String, register: Bool) async {
    // ... implementation
}
```

## Byg og kør

1. **Vælg destination:**
   - Vælg "iPhone 15" (eller anden simulator) fra device dropdown
   - Eller tilslut en fysisk iPhone

2. **Byg projektet:**
   - Tryk Cmd+B eller vælg Product → Build

3. **Kør på simulator/device:**
   - Tryk Cmd+R eller vælg Product → Run

## Projekt struktur

```
BostedApp.xcodeproj/     # Xcode projekt
BostedApp/               # Kildekodefiler
├── BostedAppApp.swift   # App entry point
├── Views/
│   ├── LoginView.swift
│   ├── MainView.swift
│   ├── ShiftPlanView.swift
│   ├── ActivityView.swift
│   └── Components/
│       └── TopBarView.swift
├── ViewModels/
│   ├── LoginViewModel.swift
│   ├── ShiftPlanViewModel.swift
│   └── ActivityViewModel.swift
├── Models/
│   ├── User.swift
│   ├── Shift.swift
│   └── Activity.swift
├── API/
│   ├── DirectusAPIClient.swift
│   └── AuthRepository.swift
├── Assets.xcassets/     # App ikoner og billeder
└── Info.plist          # App konfiguration
```

## Fejlfinding

### "File not found" fejl
- Sørg for at alle Swift-filer er kopieret korrekt
- Tjek at filnavnene matcher nøjagtigt (case-sensitive)

### Build fejl om manglende properties
- Tilføj de manglende properties som beskrevet i "Nødvendige rettelser"

### SwiftUI fejl
- Sørg for at bygge til iOS 17.0 eller nyere
- Tjek at alle imports er korrekte (import SwiftUI)

## Login credentials

Test login med:
- **Email:** admin@team-op.dk
- **Password:** Teamop21

## Features

✅ Login skærm med authentication
✅ Hovedskærm med navigation
✅ Vagtplan visning
✅ Aktivitets liste med tilmelding
✅ Gradient baggrund design
✅ Dansk lokalisering

## Support

Hvis du støder på problemer:
1. Tjek at alle filer er kopieret
2. Prøv at "clean build folder" (Shift+Cmd+K)
3. Genstart Xcode
4. Tjek console output for specifikke fejlmeddelelser

## Næste skridt

- Tilføj app icon i Assets.xcassets
- Test på fysisk iPhone device
- Implementer pull-to-refresh
- Tilføj flere skærme (meal plan, laundry, settings)
