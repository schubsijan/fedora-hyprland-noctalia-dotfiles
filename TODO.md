- [x] SUPER+w/a/s/d für grouping
- [x] Lautsprecher fixen
- [x] mute Tast geht nicht, helligkeits-tasten gehen nicht
- [x] backupen von noctalia settings
- [x] shortucts für Ausschalten, blutooth & wlan, lock nicht erlauben (idle) hinzufügen
- [x] system size etwas größer -> 1.2
- [x] install, remove, install copr selection Menu anlegen
- [x] beim Schließen von Terminal nicht nochmal Yes - No Frage
- [x] default auf yes bei dnf stellen
- [x] update-option mit ins super+alt+space-menu aufnehmen

- [x] noch ein optional-install.txt anlegen -> darin Sachen, die automatisch optional installiert werden können und im script als optionale selects auftauchen (browser, Zotero, prism-launcher, zennotes...)
  - [x] überlegen, ob ich sachen als copr installiere oder als tar (kann ich sie dann updaten??)
- [x] keyring bei browserstart ergründen (gnome-keyring-pam fehlte)
- [x] nvim dots mit hier rein

- [x] zwei-fache Passworteingabe von encryption und login bündeln (wenn das geht und sicher ist?); nicht nochmal nach boot über limine (omarchy) in Grup werfen
  - gelöst mit `greetd-autologin` (Autologin + Schlüsselbund ohne Passwort) und `boot-fedora-first` (nach Omarchy-Updates ggf. erneut ausführen)

- [x] theming
  - [x] shortcut für das switchen von themes (über den schon existierenden theswitcher von noctalia) & das switchen von wallpapern
  - [x] richtige Integration des noctalia-themes mit thunar, helium, nvim, claude, zennotes einstellen (natürlich Änderungen mit hier im repo backupen)

- [x] Minecraft Anpassung
  - [x] in MC Fenster auch erlauben, dass Touchpad bedient werden darf, wenn Tasten gedrückt werden

- [x] Passworteingabe bei Freischalten der verschlüsselten Festplatte verschönern/an Theme anpassen
  - gelöst mit Plymouth-Theme `noctalia` (`system/usr/share/plymouth/themes/`, nach Omarchy) und
    `boot-fedora-first` ohne `fastboot` (sonst druckt GRUB "Booting `Fedora Linux …'")
  - [x] auch die command-ausgabe von hyprland wegmachen (wenn das geht??)
    - gelöst in `greetd-autologin`: Ausgabe von start-hyprland nach /dev/null
  - [x] bei der Gelegenheit auch mal die startuptime von KI checken lassen und gucken, ob man da was beschleunigen kann
  - [x] ich hatte bei einem startup noch kurze Terminal-Meldungen zu ttui 1 "Booting Fedora 44" (evtl. von Grub) wäre sehr clean die noch auszustellen

- [x] Anpassungen zum Laptop-tochscreen deaktivieren (die ich ganz am Anfang aktiviert habe) mit in die dotfiles aufnehmen

- [x] fastfetch anpassen

- [x] Überlegen, ob man die Struktur in diesem Repo nicht besser machen könnte, dass stow nativer funktioniert und install.sh nicht so viele edgecases prüfen muss

- [x] Meine Blutooth-Kopfhörer werden bei einem reboot nicht automatisch conected
  - ich habe das Setting dazu in Noctalia-Setttings einfach mal angemacht. Sollte jetzt klappen

- [ ] Anweisungen zum setupen in README.md anlegen (lassen)
  - [x] auch meine learnings aus dem installieren von Fedora (mit anderem USB-Livemedium und gparted Platz schaffen, die Auswahl der optionen im Fedora-Installer -> Bilder im Handy, setup meines keyboards/wlans..., minimaDots)
    - README, ausklappbarer Block: Ventoy + GParted Live (ein Stick), Tabelle mit den Installer-Einstellungen
  - [x] postinstall Anweisungen zur Anwendung/Installation dieser Dots
  - [x] noch gucken ob ich meine Setups nach dem erstenmal Starten hier alle richtig vermekt habe: Keboard-layot setzen, github und git verknüpfen
    - Tastatur setzt der Fedora-Installer (README-Tabelle), Git/GitHub per `git-setup`
  - [ ] Repo als git-Repo anlegen und **öffentlich** auf GitHub hochladen (Voraussetzung für den Test auf einem neuen Install)

- [x] Default Programme festlegen und hier backupen

- [x] laptop zuklappen können und trotzdem weiter laufen lassen können -> vlg. [Chris Titus in seinem System](https://youtu.be/-8GmPlhzN9I?t=408)
  - gelöst mit `lid-awake` (Eintrag im SUPER+ALT+SPACE-Menü): dauerhaftes logind-Drop-in, umschaltbar

- [x] security des Systems mal KI fragen, ob das so gut ist?

- [ ] einen backup-Reiter in super+alt+space menu -> da dann bakup-alle, backup-helium, -minecraft, Daten, Zotero als optionen
