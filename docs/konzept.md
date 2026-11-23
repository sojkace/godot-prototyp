# Resource Express – Konzept (Entwurf)

> Stand: 2026-11-23. Ergebnis einer Frage-Runde zur Spielidee. Kommentare bitte im Pull Request.

## In einem Satz
Du baust auf einer wachsenden Insel Bahnstrecken zu Fabriken, die Aufträge stellen. Jede Runde
bekommst du Karten mit Gebäuden und Schienenstücken, die nie ganz passen, und musst sie geschickt
verbauen. Am Anfang machst du mit 3 Aktionen alles von Hand, später erforschst du Automaten-Karten,
die dir die Arbeit abnehmen. So wächst das System endlos.

## Eckdaten
| | |
|---|---|
| Genre | Rundenbasiertes Aufbauspiel mit Deckbau und Incremental-Fortschritt |
| Plattform | PC zuerst (Querformat, Maus), später Tablet/Handy |
| Sitzung | 30–60 Minuten am Stück |
| Langzeit | Ein Spielstand, endlos weiterspielen |
| Scheitern | Kein Game Over, nur weiche Strafen |

## Eine Runde
1. **Hand ziehen:** neue Karten vom Stapel (Startwert 3), plus 1 reservierte Karte aus der letzten Runde.
2. **Bauen:** Karten ausspielen kostet **Ressourcen** (Erz, Waren), keine Aktionen.
3. **3 Aktionen** für Handarbeit:
   - Mine antippen
   - in der Werkstatt verarbeiten
   - am Markt handeln
   - Zug vom Bahnhof auf eine Schiene setzen
4. **Rundenende:** Züge fahren ihre Strecke ab, laden an Minen entlang der Strecke und liefern
   an der Fabrik. Automaten arbeiten, Auftragsfristen laufen ab. Die Hand wird abgeworfen,
   bis auf 1 Karte, die man reservieren darf.

## Die Welt
- **Fabriken** tauchen auf, wenn die Insel wächst. Jede Fabrik hat **eine eigene Strecke** und
  **immer einen Auftrag** mit Frist (Startwert 5 Runden). Ist die Frist abgelaufen, kommt eine
  Fluchkarte ins Deck, und die Fabrik stellt einen neuen Auftrag.
- **Minen müssen an der Strecke liegen:** Züge laden unterwegs an Minen, deren Bereich die
  Schiene berührt. Deshalb zählt, wo man eine Mine baut und wie die Schiene verläuft (das Legepuzzle).
- **Bahnhöfe** sind nicht an die Schienen angeschlossen. Jeder Bahnhof hat **4 Züge** und eine
  **Reichweite**: In diesem Bereich darf man Züge auf eine Schiene setzen (1 Aktion pro Zug).
  Mehr Bahnhöfe = mehr Züge und mehr Fläche. Das Verteilen kann man per Karte automatisieren.
- **Strecken beginnen frei** irgendwo auf der Insel und führen zu einer Fabrik. Einen Zug setzt man
  von Hand an einen beliebigen Punkt der Strecke (in Reichweite eines Bahnhofs), oder man baut
  dort ein **Startgebäude** (z. B. Haltepunkt), an dem automatisch ein Zug, später mehrere, losfährt.
- **Nach dem Abliefern** fährt der Zug zurück in seinen Bahnhof und ist in der nächsten Runde
  wieder verfügbar.
- **Wachstum:** Die Insel wächst über Flaggen und Brücken. Ist kein Platz mehr, schafft man
  welchen durch Abriss und Neubau mit der Bombe.

## Deck
- **Echter Stapel** mit **fester Größe**. Ist er leer, wird der Ablagestapel neu gemischt.
- Man entscheidet selbst, welche Karten im Deck sind: Eine neue Karte rein heißt, eine andere
  muss raus (wie ein Sammelkarten-Deck). Tauschen geht **jederzeit** im Deck-Fenster und
  **kostet Münzen**.
- **Fluchkarten** (z. B. Wasser, Schutt) aus verpassten Aufträgen belegen einen Platz im Deck,
  bis man sie loswird.

## Fortschritt und Währungen
| Was | Woher | Wofür |
|---|---|---|
| Erz / Waren | Minen, Werkstatt, Markt | Karten ausspielen, Aufträge erfüllen |
| Münzen | erfüllte Aufträge | Bombe, Brücke, Extras (z. B. Karte überspringen, mehr Züge) |
| Forschungspunkte | **Meilensteine** (z. B. 10 Aufträge, 50 Felder Insel) | neue Kartenarten freischalten, darunter alle Automaten; selten +1 Aktion |

**Automatisierung** gibt es nur als Karte: erst erforschen, dann ins Deck nehmen, dann ziehen
und auf ein Gebäude oder einen Bahnhof spielen.

| Handarbeit (1 Aktion) | Automat-Karte (Idee) |
|---|---|
| Mine antippen | Förderband: Mine liefert selbst |
| Werkstatt verarbeiten | Meister: Werkstatt arbeitet selbst |
| Markt handeln | Händler: Markt tauscht selbst |
| Zug auf Schiene setzen | Fahrdienstleiter: Bahnhof verteilt seine Züge selbst |

## Was aus dem jetzigen Prototyp bleibt / wegfällt
- **Bleibt:** Karten als Formen, starre Schienen-Blöcke, Bauregeln, Minen-Bereiche, Flaggen,
  Brücke und Bombe, Werkstatt, Markt, Regeln als Daten (`GameRules`), Gebäude-Hooks, Test-Bot.
- **Fällt weg:** Herzen, Level mit festen Zugfolgen, die eine Strecke ab dem Kraftwerk, Hochformat.

## Aufträge
- **Jede Fabrik hat einen Typ** (Gold-Fabrik, Silber-Fabrik, später Waren aus der Werkstatt).
  Man muss also die passende Mine an die Strecke der passenden Fabrik bauen.
- **Mit jeder neuen Fabrik** wird es schwerer: Sie will mehr oder bessere Waren. Alte Fabriken
  bleiben gleich.

## Zahlen zum Ausprobieren (Startwerte in `GameRules`)
| Wert | Start |
|---|---|
| Karten pro Hand | 3 (+1 Reserve) |
| Aktionen pro Runde | 3 |
| Deck-Größe | 20 |
| Züge pro Bahnhof | 4 |
| Auftragsfrist | 5 Runden |
| Karte im Deck tauschen | 2 Münzen, Fluchkarte entfernen teurer |

## Erster spielbarer Schritt (Vorschlag)
Querformat, eine Fabrik mit Auftrag, ein Bahnhof mit 4 Zügen, Hand mit 3 Karten + Reserve,
3 Aktionen, Minen laden an der Strecke, keine Herzen. Dazu 2–3 Forschungen per Meilenstein,
darunter eine Automaten-Karte. Ziel: prüfen, ob sich der Kreislauf von „von Hand“ zu
„automatisch“ gut anfühlt.

## Stand der Umsetzung (erster spielbarer Schritt)
Auf diesem Branch spielbar (Menü → „Neues Spiel“, Querformat):
- Runden mit **3 Aktionen**, Hand mit **3 Karten + 1 Reserve** („Behalten“), „Neu“ tauscht eine
  Handkarte für 1 Münze. Karten kosten Items. Deck mit fester Größe (20), Deck-Fenster zum Tauschen.
- **Freie Strecken:** Schienen-Blöcke dürfen überall beginnen, beide Enden müssen weiterführen
  (freie Erde, Fabrik oder passendes Gleisende).
- **Bahnhof** (4 Züge, Reichweite 4 Felder, antippen zeigt sie): Schiene antippen = Zug losschicken.
  Ein Zug braucht mindestens 4 Felder Strecke bis zur Fabrik (`min_train_route`).
- **Minen** füllen sich per Antippen (+3, max. 6); Züge laden unterwegs nur Erz ihrer Fabrik.
- **Fabriken** (Gold/Silber) mit Auftrag und Frist; verpasst = Fluchkarte „Überflutung“ ersetzt
  eine Deck-Karte. Neue Fabrik alle 12 neuen Landfelder, jede will 3 mehr als die vorige.
- **Forschung** über Meilensteine: Förderband (Mine automatisch), Haltepunkt (Zug automatisch),
  Meister (Werkstatt automatisch), Bahnhof-Karte, neue Minen/Flaggen, +1 Aktion.
- Noch **nicht** drin: Speichern, Fahrdienstleiter, Händler-Automat, Waren aus der Werkstatt als
  Auftrag, echte Modelle für Fabrik/Bahnhof/Haltepunkt (Platzhalter).

Bot-Werte (40 Runden, je 10 bzw. 6 Spiele): Standard Ø 35 Aufträge, 15 verpasst, 6 Fabriken,
erste Automatisierung ab Runde ≈ 13 (in 7 von 10 Spielen); „Leicht“ Ø 58 Aufträge, 8 Fabriken.
In 3 von 10 Standard-Spielen verbaut sich der Bot früh die Strecke und kommt nie in Fahrt –
wichtig beim Anspielen: passiert das Menschen auch?
