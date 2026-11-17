# Resource Express – Unity-Skripte (Referenz)

Quelle: Unity Version Control, Org „Troligt“, Repo „Resource Express“, Branch `/main`,
Stand **cs:21** („finished marcetplace“, 11.02.2025). Am 17.11.2026 über die Weboberfläche
geholt (Copy-Button pro Datei, Inhalt 1:1, Zeilenenden auf LF umgestellt).

- Nur `Assets/Scripts/**/*.cs`. Szenen, Prefabs, Modelle, Animationen und Texturen fehlen.
- `Ui/BuildingUI.cs` ist im Original komplett auskommentiert, hier gekürzt.
- `CameraMovement.cs` ist **fremder Code** (Ditzel / Kudoshi, YouTube-Tutorial). Lizenz unklar, also
  nicht übernehmen, sondern in Godot neu schreiben.
- Die Dateien direkt in `unity_code/` sind inhaltlich identisch mit Dateien hier, tragen aber
  teils falsche Namen (`GameMaster.cs` = `IslandBuilder`, `Observer.cs` = `Ui/Card.cs`,
  `Resources.cs` = `Train.cs`).

## Level-Daten (aus `Settings/*.asset`, ScriptableObjects)

Die `.asset`-Dateien verweisen nur per GUID auf Prefabs, deshalb hier nur die Zahlen:

**Level1** (`LevelSetting`)
- 20 Runden: je 5 Runden mit 1, 2, 3 und 4 Zügen (`RoundSettings.trains`).
- attackDeck: 12 Karten (3 Sorten: 4× / 2× / 6×)
- railDeck: 12 Karten (8 Sorten: 1/1/3/1 und 1/3/1/1, zwei Prefab-Grundtypen)
- specialDeck: 12 Karten (6 Sorten: 1/1/1/4/3/2)
- Welche Karte welches Gebäude ist, steht nur in den Prefabs (nicht geholt).
- Item-Kartenstapel: 5 Ressourcentypen mit 20 / 20 / 30 / 50 / 30 Karten.

**TestLevel**: 9 Runden (1–3 Züge), Decks mit 3/5/1 Karten, Items 10/10/15/25/15.
**Leve2**: 3 Runden (1, 1, 3 Züge), Decks leer (unfertig).
