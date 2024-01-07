# sixinator
IPv6 Workarounds für das UnifiOS der Ubiquiti Unifi Dream Machines Pro.

Obwohl ein Marketing Slogan für Unifi "Building the Future of IT" ist, so haben die Unifi-Produkte leider noch einige Probleme mit IPv6 - auch noch in der Version 3.2.7. Eine Unique Local Address (ULA) kann beispielsweise immer noch nicht vergeben werden. Auch wenn es nicht unbedingt als Best-Practice gilt ULAs zu verwenden, fände ich eine Option dafür in der GUI ganz nett.

Außerdem konnte die UDM-Pro in der Vergangenheit nicht mit den dynamischen IPv6-Prefixen des Providers umgehen. Mit jeder neuen IPv6-Prefix habe ich daher die IPv6-Verbindung verloren (siehe auch UDM Pro 1.x: Workaround für dynamische IPv6 Prefixe). Da mein Provider aktuell scheinbar die IPv6-Addresse nicht mehr so häufig aktualisiert, konnte ich noch nicht herausfinden ob UnifiOS 3.2.7 damit immer noch ein Problem hat. Daher gehe ich lieber auf Nummer sicher und möchte das Interface resetten, wenn die IPv6-Verbindung nicht mehr bestht. Damit konnte bisher das neue IPv6-Prefix im Netzwerk verteilt werden.

## Funktionsweise
Das Script `sixinator.sh` wird wie bei dem Script natanator von jadedeane (https://github.com/jadedeane/natanator) beim Systemstart per systemd ausgeführt. Da die von sixinator erzeugten IPv6-ULAs werden bei Änderungen an der Netzwerkkonfiguration über die GUI wieder gelöscht. Daher wird über den Service alle 60 Sekunden geprüft, ob die IPv6-ULAs noch existieren und ob sie ggf. neu hinzugefügt werden müssen. Außerdem wird überprüft ob die IPv6-Verbindung noch besteht und wenn nicht werden die WAN-Interfaces neu gestartet.

## Voraussetzungen
Unifi Dream Machine Pro mit UnifiOS Version 3.x. Erfolgreich getestet mit UnifiOS 3.2.7


## Installation des Scriptes
Nachdem eine Verbindung per SSH zur UDM/UDM Pro hergestellt wurde wird das Script folgendermaßen installiert:

```
# 1. download file to directory /usr/local/bin/ and make script executable
wget -O /usr/local/bin/sixinator.sh https://raw.githubusercontent.com/nerdiges/sixinator/main/sixinator.sh
chmod +x /usr/local/bin/sixinator.sh

# 2. Download and install sixinator.service definition file in /etc/systemd/system via:
wget -O /etc/systemd/system/sixinator.service https://raw.githubusercontent.com/nerdiges/sixinator/main/sixinator.service
chmod 755 /etc/systemd/system/sixinator.service

# 3. Reload systemd, enable and start the service:
systemctl daemon-reload
systemctl enable sixinator.service
systemctl start sixinator.service
```

## Konfiguration
Im Script kann über einige Variable das Verhalten angepasst werden:

```
# WAN-Interface to be checked
wan_if="eth8 eth9"

# IPv6 hosts used to test IPv6 connection
host1="facebook.de"
host2="google.de"
host3="apple.com"
host4="microsoft.com"

# ULA prefix to be used
ula_prefix="fd00:2:0:"

# interfaces listed in exclude will not be assigned any IPv6 ULAs
# Multiple interfaces are to be separated by spaces.
exclude="br0"

# set ULA on guest interfaces?
guest_ula=false
```