# Guide: Test Notifikationer uden Xcode Console

Da du bygger via VM og Sideloadly, kan du ikke se Xcode console. Her er hvordan du tester:

## Simpel Test

### Trin 1: Tjek Tilladelser FØRST
**VIGTIGT: Dette skal gøres FØR du opretter medicin**

1. Gå til **Settings** på iPhone
2. Find **BostedApp** i app listen
3. Tjek **Notifications**:
   - Er "Allow Notifications" slået **TIL**? ✅
   - Hvis NEJ, slå det TIL
4. Tjek **Location**:
   - Er det sat til "While Using the App" eller "Always"? ✅
   - Hvis NEJ, vælg "While Using the App"

### Trin 2: Slet og Geninstaller App'en
**Dette er MEGET vigtigt for at sikre permissions virker:**

1. Slet BostedApp fra iPhone (hold på app ikon, tryk X)
2. Byg ny IPA fil i Xcode
3. Installer via Sideloadly

### Trin 3: Test Tidsbaseret Notifikation

1. Åbn app'en
2. Gå til "Medicin_test" tab
3. Tryk **+** for at oprette ny medicin
4. Opret medicin:
   - Navn: "Test"
   - Vælg: "Kun tid" 
   - Sæt antal gange: 1
   - Sæt tidspunkt til **om 2 minutter fra nu**
   - Gem
5. **VIGTIGT**: Når du gemmer, skal du måske se en pop-up:
   - "BostedApp Would Like to Send You Notifications"
   - **TRYK "ALLOW"** ✅✅✅
6. **Luk app'en** (swipe op til home screen)
7. **Vent 2 minutter**
8. **Se om notifikation kommer** 🔔

### Forventet Resultat:
- Efter 2 minutter: iOS notifikation pop-up med tekst "Tid til medicin - Test - 1 tablet(ter)"

## Hvis Notifikation IKKE Kommer

### Mulighed 1: Tilladelse blev nægtet
- Gå til Settings → BostedApp → Notifications
- Er "Allow Notifications" slået FRA? ❌
- **Løsning**: Slå TIL, slet medicin, opret igen

### Mulighed 2: App'en har ikke den nye kode
- Har du bygget en ny IPA fil EFTER mine ændringer?
- Ser du "Medicin_test" som titel (ikke bare "Medicin")?
- **Løsning**: Byg ny IPA, geninstaller

### Mulighed 3: NotificationManager virker ikke
Dette er mere kompliceret at debugge uden console.

**Test**: Prøv at oprette en notifikation manuelt via Settings:
1. Gå til Settings → Notifications
2. Find BostedApp
3. Tjek at alle indstillinger er sat korrekt:
   - Allow Notifications: ON
   - Lock Screen: ON
   - Notification Center: ON
   - Banners: ON
   - Sounds: ON

### Mulighed 4: iOS Do Not Disturb er aktiveret
- Swipe ned fra top højre hjørne
- Tjek om **måne-ikon** er aktivt
- Hvis JA: Slå Do Not Disturb FRA
- Prøv igen

## Debug Tjekliste

Gå gennem denne liste:

- [ ] App viser "Medicin_test" (ikke "Medicin") ← Bekræfter ny kode
- [ ] Settings → BostedApp → Notifications = ON
- [ ] Settings → BostedApp → Location = "While Using" minimum
- [ ] Do Not Disturb er slået FRA
- [ ] iPhone er ikke i Silent mode (tjek switch på siden)
- [ ] Medicin blev oprettet med tid om 2 min
- [ ] App blev lukket (ikke bare baggrund)
- [ ] Ventet fuld tid (2 min +)

## Næste Skridt hvis Det Stadig Ikke Virker

Hvis du har tjekket ALT ovenstående og notifikationer STADIG ikke kommer, er der sandsynligvis et problem i koden.

**Send mig følgende info:**
1. Bekræftelse på at "Medicin_test" vises (ny kode er der)
2. Screenshot af Settings → BostedApp → Notifications
3. Screenshot af Settings → BostedApp → Location  
4. Hvilken tid du satte medicinen til
5. Hvilken tid du testede (var det faktisk 2 min senere?)

Så kan jeg undersøge om NotificationManager koden har en fejl.