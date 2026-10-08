#!/usr/bin/env python3
"""UU Werkplek: laat de medewerker zien wat voor werkplek dit is, of hij aan de
afspraken voldoet en hoe hij bijgewerkt wordt. Een schil om de DAWO-tools
(dawo-verify, dawo-update-status) met UU-huisstijl."""

import getpass
import json
import os
import socket
import subprocess
import sys
import time

from PyQt6.QtCore import Qt, QUrl
from PyQt6.QtGui import QDesktopServices, QFont
from PyQt6.QtWidgets import (
    QApplication, QFrame, QGridLayout, QHBoxLayout, QLabel, QPlainTextEdit,
    QPushButton, QVBoxLayout, QWidget,
)

UU_GEEL = "#FFCD00"
UU_ROOD = "#C00A35"
INFO_FILE = "/etc/dawo-uu/info.json"

LINKS = [
    ("Universiteit Utrecht", "https://www.uu.nl"),
    ("Intranet", "https://intranet.uu.nl"),
    ("DAWO-UU op GitHub", "https://github.com/neerb001/DAWO-UU"),
]


def load_info():
    try:
        with open(INFO_FILE) as f:
            return json.load(f)
    except OSError:
        return {}


def current_system():
    path = os.path.realpath("/run/current-system")
    name = os.path.basename(path)
    return name[:8], name[33:]


def last_change():
    try:
        ts = os.lstat("/nix/var/nix/profiles/system").st_mtime
        return time.strftime("%d-%m-%Y %H:%M", time.localtime(ts))
    except OSError:
        return "-"


def run(cmd):
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        return (out.stdout + out.stderr).strip() or "(geen uitvoer)"
    except FileNotFoundError:
        return f"{cmd[0]} is niet beschikbaar op deze werkplek."
    except subprocess.TimeoutExpired:
        return f"{cmd[0]} reageerde niet binnen 60 seconden."


class Werkplek(QWidget):
    def __init__(self):
        super().__init__()
        info = load_info()
        self.setWindowTitle("UU Werkplek")
        self.resize(760, 640)

        root = QVBoxLayout(self)
        root.setContentsMargins(0, 0, 0, 0)
        root.setSpacing(0)

        header = QFrame()
        header.setStyleSheet(f"background: {UU_GEEL};")
        hl = QVBoxLayout(header)
        hl.setContentsMargins(24, 18, 24, 18)
        title = QLabel("Universiteit Utrecht")
        title.setFont(QFont("Inter", 20, QFont.Weight.Black))
        title.setStyleSheet("color: #111;")
        sub = QLabel("Mijn werkplek")
        sub.setFont(QFont("Inter", 12))
        sub.setStyleSheet("color: #111;")
        hl.addWidget(title)
        hl.addWidget(sub)
        root.addWidget(header)
        stripe = QFrame()
        stripe.setFixedHeight(4)
        stripe.setStyleSheet(f"background: {UU_ROOD};")
        root.addWidget(stripe)

        body = QVBoxLayout()
        body.setContentsMargins(24, 18, 24, 18)
        body.setSpacing(14)
        root.addLayout(body)

        werkplek = info.get("werkplek", "onbekend")
        uitleg = info.get("uitleg", "")
        if uitleg:
            banner = QLabel(uitleg)
            banner.setWordWrap(True)
            banner.setStyleSheet(
                f"border-left: 4px solid {UU_GEEL}; padding: 8px 12px; background: palette(alternate-base);")
            body.addWidget(banner)

        h, name = current_system()
        grid = QGridLayout()
        rows = [
            ("Werkplektype", werkplek),
            ("Apparaat", socket.gethostname()),
            ("Ingelogd als", getpass.getuser()),
            ("DAWO-UU-revisie", info.get("revisie", "-")),
            ("DAWO-basis", info.get("dawoRelease", "-")),
            ("Actieve configuratie", f"{h}  {name}"),
            ("Laatst bijgewerkt", last_change()),
        ]
        for i, (k, v) in enumerate(rows):
            key = QLabel(k)
            key.setStyleSheet("color: palette(placeholder-text);")
            val = QLabel(v)
            val.setTextInteractionFlags(Qt.TextInteractionFlag.TextSelectableByMouse)
            grid.addWidget(key, i, 0)
            grid.addWidget(val, i, 1)
        grid.setColumnStretch(1, 1)
        body.addLayout(grid)

        actions = QHBoxLayout()
        for label, cmd in [
            ("Werkplek controleren", ["dawo-verify"]),
            ("Updatestatus", ["dawo-update-status"]),
            ("Versie-informatie", ["dawo-proof"]),
        ]:
            b = QPushButton(label)
            b.clicked.connect(lambda _=False, c=cmd, l=label: self.show_output(l, c))
            actions.addWidget(b)
        body.addLayout(actions)

        self.output = QPlainTextEdit()
        self.output.setReadOnly(True)
        self.output.setFont(QFont("Fira Code", 9))
        self.output.setPlaceholderText(
            "Kies 'Werkplek controleren' om te zien of deze werkplek aan de beveiligingsafspraken voldoet.")
        body.addWidget(self.output, 1)

        links = QHBoxLayout()
        for label, url in LINKS:
            b = QPushButton(label)
            b.setFlat(True)
            b.setStyleSheet(f"color: {UU_ROOD}; text-decoration: underline;")
            b.clicked.connect(lambda _=False, u=url: QDesktopServices.openUrl(QUrl(u)))
            links.addWidget(b)
        links.addStretch(1)
        body.addLayout(links)

    def show_output(self, label, cmd):
        self.output.setPlainText(f"{label} ...")
        QApplication.processEvents()
        self.output.setPlainText(run(cmd))


def main():
    app = QApplication(sys.argv)
    app.setApplicationName("UU Werkplek")
    app.setDesktopFileName("uu-werkplek")
    w = Werkplek()
    w.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
