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
1. **Hand auffüllen:** Nur die gelegten Karten werden ersetzt, die Hand wird wieder auf 3
   aufgefüllt. Nicht gelegte Karten bleiben liegen.
2. **3 Aktionen**, alles kostet eine:
   - Karte legen
   - Mine antippen
   - Zug auf eine Schiene setzen
3. **Rundenende:** Züge fahren ihre Strecke ab, laden an Minen entlang der Strecke und liefern
   an der Fabrik. Automaten arbeiten, Auftragsfristen laufen ab.

Es gibt **keine Items** (Holz, Stein …) mehr, und damit auch keine Werkstatt und keinen Markt.
Knapp sind Aktionen, Platz und die Karten auf der Hand.

## Die Welt
- **Fabriken** tauchen auf, wenn die Insel wächst. Jede Fabrik hat **eine eigene Strecke** und
  **immer einen Auftrag** mit Frist (Startwert 5 Runden). Ist die Frist abgelaufen, kommt eine
  Fluchkarte ins Deck, und die Fabrik stellt einen neuen Auftrag.
- **Minen müssen an der Strecke liegen:** Züge laden unterwegs an Minen, deren Bereich die
  Schiene berührt. Deshalb zählt, wo man eine Mine baut und wie die Schiene verläuft (das Legepuzzle).
- **Lange Strecken lohnen sich:** Ein Zug lädt 1 Erz pro Schiene, die im Bereich einer Mine
  liegt (solange die Mine Erz hat). Ein voller Zug braucht also eine lange Strecke durch
  Minenbereiche. Eine Abkürzung direkt vor der Fabrik bringt fast nichts.
- **Kein Bahnhof:** Einen Zug kann man jederzeit auf jede Schiene setzen (1 Aktion pro Zug).
- **Strecken beginnen frei** irgendwo auf der Insel und führen zu einer Fabrik. Statt von Hand
  kann man einen **Haltepunkt direkt auf eine Schiene** legen: Genau dort fährt jede Runde
  automatisch ein Zug los, ohne Aktion.
- **Wachstum:** Die Insel wächst über Flaggen und Brücken. Ist kein Platz mehr, schafft man
  welchen durch Abriss und Neubau mit der Bombe.

## Deck
- **Echter Stapel** mit **fester Größe**. Ist er leer, wird der Ablagestapel neu gemischt.
- Man entscheidet selbst, welche Karten im Deck sind: Eine neue Karte rein heißt, eine andere
  muss raus (wie ein Sammelkarten-Deck). Tauschen geht **jederzeit** im Deck-Fenster und
  **kostet Münzen**.
- **Fluchkarten** (z. B. Wasser, Schutt) aus verpassten Aufträgen belegen einen Platz im Deck,
  bis man sie loswird. Auf der Hand verstopfen sie einen Platz, bis man sie legt (1 Aktion)
  oder für Münzen wegwirft.

## Fortschritt und Währungen
| Was | Woher | Wofür |
|---|---|---|
| Erz | Minen | Aufträge erfüllen |
| Münzen | erfüllte Aufträge (3 pro Auftrag) | Bombe, Brücke, Karte wegwerfen, Deck umbauen |
| Forschungspunkte | **Meilensteine** (z. B. 10 Aufträge, 50 Felder Insel) | neue Kartenarten freischalten, darunter alle Automaten; selten +1 Aktion |

**Automatisierung** gibt es nur als Karte: Erforschen legt sie einmal direkt ins Deck (sie
ersetzt die häufigste Karte), weitere Kopien kosten Münzen. Dann ziehen und auf ein Gebäude spielen.

| Handarbeit (1 Aktion) | Automat-Karte (Idee) |
|---|---|
| Mine antippen | Förderband: Mine liefert selbst |
| Zug auf Schiene setzen | Haltepunkt: schickt jede Runde selbst einen Zug |

## Was aus dem jetzigen Prototyp bleibt / wegfällt
- **Bleibt:** Karten als Formen, starre Schienen-Blöcke, Bauregeln, Minen-Bereiche, Flaggen,
  Brücke und Bombe, Regeln als Daten (`GameRules`), Gebäude-Hooks, Test-Bot.
- **Fällt weg:** Herzen, Level mit festen Zugfolgen, die eine Strecke ab dem Kraftwerk, Hochformat,
  Items, Werkstatt, Markt, Bahnhof.

## Aufträge
- **Jede Fabrik hat einen Typ** (Gold-Fabrik, Silber-Fabrik, später Waren aus der Werkstatt).
  Man muss also die passende Mine an die Strecke der passenden Fabrik bauen.
- **Es wird immer schwerer:** Jeder erfüllte Auftrag macht den nächsten derselben Fabrik um 1
  größer (5 → 6 → 7 …). Jede neue Fabrik startet 3 höher als die vorige.
- **Neue Fabriken** kommen, wenn die Insel um 12 Felder wächst, spätestens aber alle 8 Runden.

## Zahlen zum Ausprobieren (Startwerte in `GameRules`)
| Wert | Start |
|---|---|
| Karten pro Hand | 3 (aufgefüllt) |
| Aktionen pro Runde | 3 |
| Deck-Größe | 20 |
| Erz pro Schiene im Minenbereich | 1 (Zug fasst 4) |
| Auftragsfrist | 5 Runden |
| Karte im Deck tauschen | 2 Münzen, Fluchkarte entfernen teurer |

## Erster spielbarer Schritt (Vorschlag)
Querformat, eine Fabrik mit Auftrag, Züge auf jede Schiene, Hand mit 3 Karten,
3 Aktionen, Minen laden an der Strecke, keine Herzen. Dazu 2–3 Forschungen per Meilenstein,
darunter eine Automaten-Karte. Ziel: prüfen, ob sich der Kreislauf von „von Hand“ zu
„automatisch“ gut anfühlt.

## Stand der Umsetzung (erster spielbarer Schritt)
Auf diesem Branch spielbar (Menü → „Neues Spiel“, Querformat):
- Runden mit **3 Aktionen** (Karte legen, Mine antippen, Zug schicken). Die Hand wird nur auf
  **3 Karten aufgefüllt**; „Neu“ tauscht eine Handkarte für 1 Münze. Keine Items.
  Deck mit fester Größe (20), Deck-Fenster zum Tauschen.
- **Freie Strecken:** Schienen-Blöcke dürfen überall beginnen, beide Enden müssen weiterführen
  (freie Erde, Fabrik oder passendes Gleisende).
- **Züge:** Schiene antippen = Zug losschicken (1 Aktion), überall, kein Bahnhof. Die Strecke muss
  an einer passenden Mine vorbeiführen.
- **Minen** füllen sich per Antippen (+3, max. 6); Züge laden unterwegs nur Erz ihrer Fabrik,
  1 pro Schiene im Minenbereich (`loads_per_mine_step`).
- **Fabriken** (Gold/Silber) mit Auftrag und Frist; verpasst = Fluchkarte „Überflutung“ ersetzt
  eine Deck-Karte. Neue Fabrik alle 12 neuen Landfelder, spätestens alle 8 Runden
  (`rounds_per_factory`); jede startet 3 höher, jeder erfüllte Auftrag macht den nächsten
  um 1 größer (`order_growth_per_order`). 3 Münzen pro Auftrag.
- **Forschung** über Meilensteine: Förderband (Mine automatisch), Haltepunkt (auf eine Schiene
  gelegt, Zug startet dort automatisch),
  neue Minen/Flaggen, +1 Aktion.
- Noch **nicht** drin: Speichern, echte Modelle für Fabrik/Haltepunkt (Platzhalter).

Bot-Werte Standard (40 Runden, 6 Spiele; wachsende Aufträge, Fabrik spätestens alle 8 Runden,
3 Münzen pro Auftrag, erforschte Karten kommen einmal direkt ins Deck): Ø 11 Aufträge erfüllt,
16 verpasst, 6 Fabriken, erste Automatisierung in allen Spielen ab Runde ≈ 16.
Der Bot kommt mit den vielen Fabriken nicht hinterher – beim Anspielen prüfen, ob es Menschen
auch so geht (dann z. B. `rounds_per_factory` auf 10 oder `order_deadline` auf 6).
