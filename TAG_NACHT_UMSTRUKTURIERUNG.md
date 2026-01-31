# Tag/Nacht-Zyklus Code-Umstrukturierung

## Überblick
Dieses Dokument beschreibt die Umstrukturierung des Tag/Nacht-Zyklus-Systems, um den Code klarer, wartbarer und einfacher verständlich zu machen.

## Problemstellung
Die ursprüngliche `day_night_cycle.gd` Datei (1000+ Zeilen) hatte verstreute Logik für:
- Helligkeitsberechnungen
- Sonnenaufgang und Sonnenuntergang Timing
- Sonnenposition/Winkelberechnungen
- Tag/Nacht-Übergänge
- Verwaltung von Himmelskörpern

Dies machte es schwierig zu verstehen:
- Wann der Tag beginnt (Sonnenaufgang um 7:00 Uhr)
- Wann der Tag endet (Sonnenuntergang um 17:00 Uhr)
- Wie sich die Helligkeit im Laufe des Tages ändert
- Der gesamte Ablauf des Tag/Nacht-Zyklus

## Lösung: Code-Organisation mit Regionen

### Erstellte Regionen
Der Code wurde in 16 logische Regionen umstrukturiert:

1. **TAG/NACHT-ZYKLUS ÜBERSICHT** (Zeilen 4-24, 21 Zeilen)
   - Umfassende Dokumentation des gesamten Systems
   - Tag-Zyklus-Timing (7:00 - 17:00 Uhr)
   - Erklärung der Helligkeitsentwicklung
   - Übersicht über das Sonnenpositionssystem

2. **ZEIT-KONFIGURATION** (Zeilen 26-43)
   - Tag-Dauer-Konstanten (90 Minuten = 10 Spielstunden)
   - Sonnenaufgang/Sonnenuntergang-Timing (je 60 Sekunden)
   - Sperrzeit und Warnzeiten
   
3. **HELLIGKEIT & BELEUCHTUNGS-KONFIGURATION** (Zeilen 45-55)
   - MIN_LIGHT_ENERGY = 1.2 (Sonnenaufgang/Sonnenuntergang)
   - MAX_LIGHT_ENERGY = 3.0 (Mittag)
   - Sonnenuntergangs-Farbwärme-Konstanten

4. **HIMMELSKÖRPER-KONFIGURATION** (Zeilen 57-62)
   - Entfernungskonstanten für Sonne, Mond, Sterne
   
5. **DEBUG & ENTWICKLUNG** (Zeilen 64-68)
   - Debug-Modus-Flags für Tests
   
6. **ZUSTANDS-VARIABLEN** (Zeilen 70-105)
   - Alle Laufzeit-Zustandsvariablen zusammengefasst
   
7. **LEBENSZYKLUS & INITIALISIERUNG** (Zeilen 107-325)
   - _ready(), _process() Funktionen
   - Spiel-Initialisierung und Hauptschleife
   
8. **HELLIGKEIT & BELEUCHTUNGSSYSTEM** (Zeilen 327-425)
   - Kern-Beleuchtungsberechnungen
   - Quadratische Helligkeitskurve: Intensität = 1.0 - (Abstand_von_Mittag)²
   - Umgebungslicht-Farbverwaltung
   
9. **SONNENAUFGANG & SONNENUNTERGANG ÜBERGÄNGE** (Zeilen 427-562)
   - Sonnenaufgangs-Animation (7:00 Uhr, 60 Sekunden)
   - Sonnenuntergangs-Animation (17:00 Uhr, 60 Sekunden)
   - Lichtrotation, Intensitätsausblendung, Farbwärme
   
10. **UI & BENUTZERBENACHRICHTIGUNGEN** (Zeilen 564-593)
    - Warnmeldungen
    - Nachtbildschirm-Verwaltung
    - Spielereingabe-Steuerung
    
11. **ZUSTANDS-VERWALTUNG & SPEICHERN/LADEN** (Zeilen 595-673)
    - Spielstand speichern/laden
    - Persistierung von Tag/Nacht-Daten
    
12. **SONNENPOSITIONS-BERECHNUNG** (Zeilen 675-726)
    - Kern-Sonnenpositions-Algorithmus
    - 0° (Sonnenaufgang) → 90° (Mittag) → 180° (Sonnenuntergang)
    - Anzeigewinkel-Berechnung
    
13. **HIMMELSKÖRPER** (Zeilen 728-914)
    - Erstellung von Sonne, Mond und Sternen
    - Positions-Updates basierend auf Zeit
    - Sichtbarkeits-Verwaltung
    
14. **DEBUGGING & PROTOKOLLIERUNG** (Zeilen 916-989)
    - Umfassende Protokollierungsfunktionen
    - App-Lebenszyklus-Ereignisbehandlung
    
15. **ZEITSKALENSTEUERUNG** (Zeilen 991-1006)
    - Zeit beschleunigen/verlangsamen
    
16. **SPIELSTATUS-INTEGRATION** (Zeilen 1008-1055)
    - Integration mit SaveGameManager

## Wichtige Verbesserungen

### 1. Klare Dokumentation
Der Übersichtsbereich am Anfang erklärt jetzt klar:
- **Tag beginnt**: 7:00 Uhr mit 60-Sekunden Sonnenaufgangs-Animation
- **Tag endet**: 17:00 Uhr mit 60-Sekunden Sonnenuntergangs-Animation  
- **Hellster Zeitpunkt**: Mittag (12:00 Uhr) mit MAX_LIGHT_ENERGY (3.0)
- **Dunkelste Zeiten**: Sonnenaufgang und Sonnenuntergang mit MIN_LIGHT_ENERGY (1.2)
- **Helligkeitsformel**: Quadratische Kurve basierend auf Abstand vom Mittag

### 2. Logische Gruppierung
Verwandte Funktionalität ist jetzt zusammengefasst:
- Alle Zeitkonstanten an einem Ort
- Alle Helligkeitskonstanten zusammen
- Sonnenaufgang/Sonnenuntergang-Animationen in einer Region
- Himmelskörper (Sonne/Mond/Sterne) zusammen

### 3. Veralteter Code entfernt
Die folgenden veralteten Elemente wurden entfernt:
- Alte Sonnenwinkel-Konstanten (SUNRISE_START_ANGLE, SUNRISE_END_ANGLE, etc.)
- Ungenutzte _calculate_current_sun_angle() Funktion
- Diese stammten aus einem alten Positionierungssystem (−20° bis +20° Bogen)
- Neues System verwendet klarere 0-180° Anzeigewinkel

### 4. Bessere Navigation
Entwickler können jetzt schnell Code nach Region finden:
- Sonnenaufgangs-Timing ändern? → ZEIT-KONFIGURATION Region
- Helligkeit anpassen? → HELLIGKEIT & BELEUCHTUNGS-KONFIGURATION Region
- Sonnenposition debuggen? → SONNENPOSITIONS-BERECHNUNG Region

## Tag/Nacht-Zyklus Ablauf

### Zeitplan
```
7:00 Uhr (0°)   - Sonnenaufgang beginnt (60s Animation)
8:00 Uhr (~18°)  - Volle Tageshelligkeit beginnt
12:00 Uhr (90°)  - Mittag - hellster Punkt
16:00 Uhr (~162°) - Sonnenuntergangs-Warnung (2 Min)
16:59 Uhr (~179°) - Sonnenuntergangs-Warnung (1 Min)
17:00 Uhr (180°) - Sonnenuntergang beginnt (60s Animation)
18:00 Uhr       - Nacht-Sperrzeit (4 Stunden)
```

### Helligkeitskurve
```
Zeit:         7:00  8:00  9:00  10:00  11:00  12:00  13:00  14:00  15:00  16:00  17:00
Sonnenwinkel: 0°    18°   36°   54°    72°    90°    108°   126°   144°   162°   180°
Lichtstärke:  1.2   1.6   2.1   2.5    2.8    3.0    2.8    2.5    2.1    1.6    1.2
```

Die Helligkeit folgt einer quadratischen Kurve: `Intensität = lerp(MIN, MAX, 1.0 - (Abstand_von_Mittag)²)`
Dies erzeugt eine realistische atmosphärische Aufhellung, die morgens schneller ist und mittags langsamer wird.

## Vorteile der Umstrukturierung

### Klarheit
- **Vorher**: Logik für Sonnenaufgang, Helligkeit und Position über 1000 Zeilen verteilt
- **Nachher**: Klar definierte Regionen mit beschreibenden Namen

### Wartbarkeit  
- **Vorher**: Schwierig, zusammenhängende Funktionalität zu finden
- **Nachher**: Alle verwandten Funktionen in einer Region

### Verständlichkeit
- **Vorher**: Unklar, wann der Tag beginnt/endet und wie hell es sein soll
- **Nachher**: Übersichtsdokumentation erklärt den kompletten Ablauf

### Erweiterbarkeit
- Neue Features können einfach zur entsprechenden Region hinzugefügt werden
- Code-Duplikation ist sichtbar und kann leichter behoben werden

## Tests
Alle bestehenden Tests sollten ohne Änderung bestehen, da dies eine reine Code-Organisation ohne Verhaltensänderungen ist.

## Zukünftige Verbesserungen
Mögliche Bereiche für weitere Optimierung:
1. Gemeinsame Logik aus _animate_sunrise() und _animate_sunset() in einen gemeinsamen Helper extrahieren
2. Datengesteuerte Konfiguration für Tag/Nacht-Parameter erstellen
3. Übergangskurven als konfigurierbare Ressourcen hinzufügen
