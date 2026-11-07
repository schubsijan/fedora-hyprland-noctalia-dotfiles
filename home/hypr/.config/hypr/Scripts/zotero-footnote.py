#!/usr/bin/env python3
"""Fuegt eine Zotero-Quelle als Markdown-Fussnote in die offene ZenNotes-Notiz ein.

Oeffnet den Zotero-Schnellsuchdialog (derselbe wie in LibreOffice), setzt den
Verweis [^1] an die Cursorposition und haengt die Definition ans Notizende.

Das Skript meldet sich dafuer ueber Zoteros HTTP-Schnittstelle fuer
Textverarbeitungen (/connector/document/*) als "Dokument" an. Sie ist nicht
oeffentlich dokumentiert und koennte sich mit einem Zotero-Update aendern.

    zotero-footnote.py            normaler Ablauf
    zotero-footnote.py --dry-run  Ergebnis nur ausgeben, nichts einfuegen
"""
import json
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
import uuid
from html import escape, unescape
from html.parser import HTMLParser
from pathlib import Path

# Einstellungen. Der Stil muss in Zotero installiert sein.
STYLE = "http://www.zotero.org/styles/politische-vierteljahresschrift"
LOCALE = "de-DE"
ZOTERO_BIN = Path.home() / ".local/opt/zotero/zotero"
ZENNOTES_CONFIG = Path.home() / ".config/ZenNotes/zennotes.config.json"
ZENNOTES_CLASS = "zennotes"

RELOAD_WAIT = 1.0  # Sekunden, bis ZenNotes die geaenderte Datei geladen hat
SAVE_TIMEOUT = 15.0  # Sekunden, die auf das Speichern des Verweises durch ZenNotes gewartet wird
CHECK_WAIT = 3.0  # Sekunden, nach denen die neue Nummerierung geprueft wird

LINK_TEXT = "~>"
LOCATOR_LABELS = {
    "page": "S.", "chapter": "Kap.", "volume": "Bd.", "section": "Abschn.",
    "paragraph": "Abs.", "line": "Z.", "note": "Anm.",
}
DEFINITION = re.compile(r"^\[\^([^\]]+)\]:")
NUMBERED_REF = re.compile(r"\[\^(\d+)\]")
CODE = re.compile(r"(```.*?```|~~~.*?~~~|`[^`\n]*`)", re.S)

ZOTERO_URL = "http://127.0.0.1:23119/connector"
OPENER = urllib.request.build_opener(urllib.request.ProxyHandler({}))


def notify(message):
    subprocess.run(["notify-send", "-a", "Zotero-Fußnote", "Zotero-Fußnote", message], check=False)
    print(message, file=sys.stderr)


def post(path, payload, timeout=None):
    request = urllib.request.Request(
        f"{ZOTERO_URL}/{path}",
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
    )
    with OPENER.open(request, timeout=timeout) as response:
        return json.loads(response.read() or "null")


def zotero_ready():
    try:
        OPENER.open(f"{ZOTERO_URL}/ping", timeout=2).read()
        return True
    except OSError:
        return False


def ensure_zotero():
    if zotero_ready():
        return
    subprocess.Popen(
        [str(ZOTERO_BIN)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )
    for _ in range(60):
        time.sleep(1)
        if zotero_ready():
            return
    raise RuntimeError("Zotero antwortet nicht.")


def pick_citation():
    """Spielt gegenueber Zotero ein leeres Dokument.

    Liefert (Literaturverzeichnis als HTML, Code der Zitation) oder None bei Abbruch.
    """
    document_id = str(uuid.uuid4())
    state = {}
    state["data"] = (
        f'<data data-version="3"><session id="{uuid.uuid4().hex}"/>'
        f'<style id="{escape(STYLE)}" locale="{escape(LOCALE)}" '
        'hasBibliography="0" bibliographyStyleHasBeenSet="0"/>'
        '<prefs><pref name="fieldType" value="Http"/><pref name="noteType" value="1"/></prefs>'
        "</data>"
    )
    fields = {}
    alerts = []

    def as_json(field):
        return {"id": field["id"], "code": field["code"], "text": field["text"], "noteIndex": 1}

    def handle(command, args):
        if command == "Application.getActiveDocument":
            return {
                "documentID": document_id,
                "outputFormat": "html",
                "supportedNotes": ["footnotes"],
                "supportsImportExport": False,
                "supportsTextInsertion": False,
                "supportsCitationMerging": False,
                "processorName": "ZenNotes",
            }
        if command == "Document.getDocumentData":
            return state["data"]
        if command == "Document.setDocumentData":
            state["data"] = args[1]
            return None
        if command == "Document.canInsertField":
            return True
        if command == "Document.cursorInField":
            return None
        if command == "Document.insertField":
            # Ein leerer Text gilt in Zotero als geloeschtes Literaturverzeichnis.
            field = {"id": str(uuid.uuid4()), "code": "TEMP", "text": "{Zotero}", "html": ""}
            fields[field["id"]] = field
            return as_json(field)
        if command == "Document.getFields":
            return [as_json(field) for field in fields.values()]
        if command == "Document.displayAlert":
            alerts.append(args[1])
            return 0
        if command == "Field.setCode":
            fields[args[1]]["code"] = args[2]
        elif command == "Field.setText":
            fields[args[1]]["html"] = args[2]
            # Zotero vergleicht mit dem reinen Text, um manuelle Aenderungen zu erkennen.
            fields[args[1]]["text"] = unescape(re.sub(r"<[^>]+>", "", args[2]))
        elif command == "Field.delete":
            fields.pop(args[1], None)
        return None

    def run(command):
        try:
            request = post("document/execCommand", {"command": command, "docId": document_id})
        except urllib.error.HTTPError as error:
            if error.code == 503:
                raise RuntimeError("Zotero hat schon einen Zitierdialog offen.") from error
            raise
        while request["command"] != "Document.complete":
            result = handle(request["command"], request.get("arguments", []))
            request = post("document/respond", result)

    def field_with_prefix(prefix):
        return next((f for f in fields.values() if f["code"].startswith(prefix)), None)

    def fail_on_alerts():
        if alerts:
            raise RuntimeError("Zotero meldet: " + " ".join(str(alert) for alert in alerts))

    run("addEditCitation")
    citation = field_with_prefix("ITEM CSL_CITATION ")
    if citation is None:
        fail_on_alerts()
        return None

    # Zotero braucht einen Moment, bis der erste Vorgang ganz abgeschlossen ist.
    time.sleep(0.5)
    run("addEditBibliography")
    fail_on_alerts()
    bibliography = field_with_prefix("BIBL ")
    if bibliography is None or "csl-entry" not in bibliography["html"]:
        raise RuntimeError("Zotero hat kein Literaturverzeichnis geliefert.")
    return bibliography["html"], json.loads(citation["code"].removeprefix("ITEM CSL_CITATION "))


class MarkdownFromHtml(HTMLParser):
    MARKS = {"i": "*", "em": "*", "b": "**", "strong": "**"}

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.parts = []

    def handle_starttag(self, tag, attrs):
        self.parts.append(self.MARKS.get(tag, ""))

    def handle_endtag(self, tag):
        self.parts.append(self.MARKS.get(tag, ""))

    def handle_data(self, data):
        self.parts.append(re.sub(r"([*\[\]])", r"\\\1", data))


def html_to_markdown(html):
    parser = MarkdownFromHtml()
    parser.feed(html)
    return " ".join("".join(parser.parts).split())


def zotero_link(item):
    for uri in item.get("uris", []):
        match = re.search(r"/(?:users/(?:local/)?[^/]+|groups/(\d+))/items/([A-Z0-9]+)$", uri)
        if match:
            group, key = match.groups()
            library = f"groups/{group}" if group else "library"
            return f"zotero://select/{library}/items/{key}"
    return None


def compact(text):
    return re.sub(r"\W+", "", text).casefold()


def locator_text(item):
    locator = item.get("locator")
    if not locator:
        return ""
    label = item.get("label", "page")
    locator = re.sub(r"(?<=\d)-(?=\d)", "–", str(locator))
    return f"{LOCATOR_LABELS.get(label, label)} {locator}"


def definition_text(bibliography_html, code):
    """Baut pro Quelle: Eintrag im Stil, Seitenangabe und Zotero-Link."""
    entries = [
        html_to_markdown(entry)
        for entry in re.findall(r'<div class="csl-entry"[^>]*>(.*?)</div>', bibliography_html, re.S)
    ]
    parts = []
    # Zotero sortiert das Verzeichnis, deshalb werden die Eintraege ueber den Titel zugeordnet.
    for item in code["citationItems"]:
        title = compact(item.get("itemData", {}).get("title", ""))
        index = next((i for i, entry in enumerate(entries) if title and title in compact(entry)), 0)
        entry = entries.pop(index)
        locator = locator_text(item)
        if locator:
            entry = f"{entry.rstrip(' .')}, {locator}."
        if item.get("prefix"):
            entry = f"{item['prefix']} {entry}"
        if item.get("suffix"):
            entry = f"{entry} {item['suffix']}"
        link = zotero_link(item)
        parts.append(f"{entry} [{LINK_TEXT}]({link})" if link else entry)
    return " ".join(parts)


def active_note():
    """Liefert die in ZenNotes offene Notiz laut dessen Arbeitsbereichsdatei."""
    root = Path(json.loads(ZENNOTES_CONFIG.read_text())["vaultRoot"])
    workspace = json.loads((root / ".zennotes/workspace.json").read_text())

    def find_leaf(node):
        if node.get("kind") == "leaf":
            return node if node.get("id") == workspace.get("activePaneId") else None
        for value in node.values():
            for child in value if isinstance(value, list) else [value]:
                if isinstance(child, dict) and (leaf := find_leaf(child)):
                    return leaf
        return None

    leaf = find_leaf(workspace["paneLayout"])
    if not leaf or not leaf.get("activeTab"):
        return None
    note = root / leaf["activeTab"]
    return note if note.is_file() else None


def resolve_number(definition, note_text):
    """Nutzt eine vorhandene gleiche Fussnote erneut, sonst die naechste freie Nummer."""
    existing = re.search(rf"^\[\^(\d+)\]: {re.escape(definition)}$", note_text, re.M)
    if existing:
        return existing.group(1), False
    numbers = [int(number) for number in NUMBERED_REF.findall(note_text)]
    return str(max(numbers, default=0) + 1), True


def split_note(text):
    """Trennt den Inhalt vom Fussnotenblock am Notizende. Liefert (Inhalt, Fussnoten)."""
    lines = text.rstrip("\n").split("\n")
    start = len(lines)
    while start > 0 and (
        not lines[start - 1].strip() or lines[start - 1][0] in " \t" or DEFINITION.match(lines[start - 1])
    ):
        start -= 1
    while start < len(lines) and not DEFINITION.match(lines[start]):
        start += 1

    entries = []
    for line in lines[start:]:
        if DEFINITION.match(line):
            entries.append(line)
        else:
            entries[-1] += "\n" + line
    body = lines[:start]
    while body and not body[-1].strip():
        body.pop()
    # Ein vorhandener Trenner wird neu gesetzt, das Ende des Frontmatters bleibt stehen.
    is_frontmatter_end = len(body) > 1 and body[0] == "---" and "---" not in body[1:-1]
    if body and body[-1] == "---" and not is_frontmatter_end:
        body.pop()
        while body and not body[-1].strip():
            body.pop()
    return "\n".join(body), [entry.rstrip() for entry in entries]


def join_note(body, entries):
    if not entries:
        return body + "\n"
    block = "\n".join(entries)
    return f"{body}\n\n---\n\n{block}\n" if body else f"---\n\n{block}\n"


def outside_code(text, change):
    parts = CODE.split(text)
    parts[::2] = [change(part) for part in parts[::2]]
    return "".join(parts)


def count_references(text):
    body, _ = split_note(text)
    found = []
    outside_code(body, lambda part: found.extend(NUMBERED_REF.findall(part)) or part)
    return len(found)


def renumber(text):
    """Nummeriert die Fussnoten nach ihrer Reihenfolge im Text und sortiert den Block."""
    body, entries = split_note(text)
    order = []

    def collect(part):
        for line in part.split("\n"):
            if not DEFINITION.match(line):
                order.extend(n for n in NUMBERED_REF.findall(line) if n not in order)
        return part

    outside_code(body, collect)
    labels = [DEFINITION.match(entry).group(1) for entry in entries]
    order.extend(sorted((n for n in labels if n.isdigit() and n not in order), key=int))
    mapping = {old: str(new) for new, old in enumerate(order, 1)}

    def apply(part):
        return NUMBERED_REF.sub(lambda match: f"[^{mapping.get(match.group(1), match.group(1))}]", part)

    body = outside_code(body, apply)
    entries = [apply(entry) for entry in entries]

    def sort_key(entry):
        label = DEFINITION.match(entry).group(1)
        return (0, int(label), "") if label.isdigit() else (1, 0, label)

    return join_note(body, sorted(entries, key=sort_key))


def add_definition(text, number, definition):
    body, entries = split_note(text)
    return join_note(body, [*entries, f"[^{number}]: {definition}"])


def wait_for_saved_reference(note, references_before):
    deadline = time.monotonic() + SAVE_TIMEOUT
    while time.monotonic() < deadline:
        time.sleep(0.5)
        text = note.read_text()
        if count_references(text) > references_before:
            return text
    return None


def hyprland(lua):
    subprocess.run(["hyprctl", "dispatch", lua], check=True, capture_output=True)


def active_window():
    output = subprocess.run(["hyprctl", "activewindow", "-j"], capture_output=True, text=True, check=True)
    return json.loads(output.stdout or "{}")


def clipboard_text():
    types = subprocess.run(["wl-paste", "--list-types"], capture_output=True, text=True).stdout
    if "text/plain" not in types:
        return None
    return subprocess.run(["wl-paste", "--no-newline"], capture_output=True, text=True).stdout


def copy(text):
    subprocess.run(["wl-copy", "--", text], check=True)


def paste_into(window, text):
    previous = clipboard_text()
    copy(text)
    hyprland(f'hl.dsp.focus({{ window = "address:{window["address"]}" }})')
    time.sleep(0.25)
    hyprland('hl.dsp.send_shortcut({ mods = "CTRL", key = "V" })')
    time.sleep(0.3)
    if previous is not None:
        copy(previous)


def main():
    dry_run = "--dry-run" in sys.argv[1:]
    window = active_window()
    ensure_zotero()
    picked = pick_citation()
    if picked is None:
        return

    html, code = picked
    definition = definition_text(html, code)

    if dry_run:
        print(f"[^1]\n\n[^1]: {definition}")
        return

    note = active_note() if window.get("class", "").lower() == ZENNOTES_CLASS else None
    if note is None:
        copy(f"[^1]\n\n[^1]: {definition}")
        notify("Keine offene Notiz erkannt. Die Fußnote liegt in der Zwischenablage.")
        return

    text = note.read_text()
    number, is_new = resolve_number(definition, text)
    # ZenNotes uebernimmt Aenderungen von aussen nur ohne ungespeicherte Aenderungen.
    # Deshalb zuerst die Definition schreiben und danach erst den Verweis einfuegen.
    if is_new:
        text = add_definition(text, number, definition)
        note.write_text(text)
        time.sleep(RELOAD_WAIT)
    references_before = count_references(text)
    paste_into(window, f"[^{number}]")

    saved = wait_for_saved_reference(note, references_before)
    if saved is None:
        notify("ZenNotes hat noch nicht gespeichert. Die Nummern werden beim nächsten Einfügen angepasst.")
        return
    if is_new and f"[^{number}]: " not in saved:
        copy(f"[^{number}]: {definition}")
        notify("ZenNotes hat die Fußnote überschrieben. Sie liegt in der Zwischenablage.")
        return

    renumbered = renumber(saved)
    if renumbered != saved:
        note.write_text(renumbered)
        time.sleep(CHECK_WAIT)
        if renumber(note.read_text()) != note.read_text():
            notify("Die Nummern sind noch nicht angepasst. Das passiert beim nächsten Einfügen.")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        notify(f"Fehler: {error}")
        sys.exit(1)
