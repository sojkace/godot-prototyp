# Mitmachen

Resource Express ist ein Prototyp: Wir probieren viele Spielideen aus und behalten die besten.

## Grundregel: main = beste spielbare Version
- Niemand pusht direkt auf `main`. Änderungen kommen nur per Pull Request.
- Ein PR braucht 1 Freigabe, alle Kommentare müssen geklärt sein und der Check
  **„check“** (Godot startet headless, der Bot spielt ein Spiel) muss grün sein.
- Gemergt wird per **Squash**; der Branch wird danach automatisch gelöscht.

## Branches
| Präfix | Wofür | Muss gemergt werden? |
|---|---|---|
| `proto/<idee>` | eine Spielidee ausprobieren, z. B. `proto/handkarten` | nein |
| `feat/<name>` | etwas, das sicher nach main soll | ja |
| `fix/<name>` | einen Fehler beheben | ja |

```bash
git switch main && git pull
git switch -c proto/meine-idee
```

## Ablauf für eine Idee
1. Branch `proto/<idee>` anlegen, früh einen **Draft-PR** öffnen und die Idee beschreiben.
2. Die anderen spielen an (Editor, F5) und kommentieren im PR.
3. Gute Idee → PR fertig machen, Freigabe holen, mergen.
4. Verworfene Idee → aufheben und Branch löschen:
   ```bash
   git tag archiv/<idee> proto/<idee> && git push origin archiv/<idee>
   git push origin --delete proto/<idee>
   ```

## Weniger Konflikte
- **Nur Zahlen ändern?** Eine eigene Regel-Datei in `data/rules/` anlegen
  (z. B. `data/rules/viele-muenzen.tres`) statt `default.tres` zu ändern. Sie erscheint im Menü.
- Balance vergleichen: `flatpak run org.godotengine.Godot --headless --path "$PWD" -- --simulate=20 --rules=<name>`
- Die `.blend`-Datei (`art_src/blender/3DObj.blend`) lässt sich nicht mergen:
  immer nur eine Person gleichzeitig, vorher Bescheid sagen.
- Neue fremde Assets nur mit klarer Lizenz und Eintrag in `CREDITS.md`.

## Commit-Mail
Bitte die GitHub-noreply-Adresse verwenden (GitHub → Settings → Emails), damit die private
Adresse nicht öffentlich im Repo steht:
```bash
git config user.email "<id>+<name>@users.noreply.github.com"
```
