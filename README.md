# sixinator
IPv6 Workarounds für das UnifiOS der Ubiquiti Unifi Dream Machines Pro.

Unique Local Addresses (ULA) können auch in unifiOD 3.2.7 und in Network App 8.0.36 können immer noch nicht vergeben werden. Auch wenn es nicht unbedingt als Best-Practice gilt ULAs zu verwenden, ist die Nutzung gerade bei dynamischen IPv6 Präfixes ggf. sinnvoll.

Außerdem konnte die UDM-Pro in der Vergangenheit nicht mit den dynamischen IPv6-Prefixen des Providers umgehen. Mit jedem neuen IPv6-Prefix wurde das WAN interface nicht korrekt aktualisiert, so dass die IPv6-Verbindung verloren ging (siehe auch UDM Pro 1.x: Workaround für dynamische IPv6 Prefixe). Da mein Provider aktuell scheinbar die IPv6-Addresse nicht mehr so häufig aktualisiert, konnte ich noch nicht herausfinden ob UnifiOS 3.2.7 damit immer noch ein Problem hat. Um die IPv6 Verbindung nicht zu verlieren, wird regelmäßig überprüft ob die IPv6 Verbindung verloren geht. Falls ja, wird das WAN Interface resettet. Dadurch wird das neue IPv6-Prefix auch im Netzwerk verteilt und IPv6 sollte wieder funktionieren.

## Voraussetzungen
Unifi Dream Machine Pro mit UnifiOS Version 3.x. Erfolgreich getestet mit UnifiOS 3.2.7 und Network App 8.0.26.

## Funktionsweise
Das Script `udm-ipv6.sh` wird bei jedem Systemstart und anschließend alle 90 Sekunden per systemd ausgeführt. Da die von Script erzeugten IPv6-ULAs bei Änderungen an der Netzwerkkonfiguration über die GUI wieder gelöscht werden, wird regelmäßig überprüft, ob die IPv6-ULAs noch passen. Neben dem systemd-Service wird daher auch ein systemd-Timer eingerichtet der das Script alle 90 Sekunden neu startet und die ULAs bei Bedarf wiederherstellt.

## Features
- Überprüfung der IPv6-Verbindung  
- Vergabe von IPv6-ULAs für die konfigurierten Netzwerke 

## Disclaimer
Änderungen die dieses Script an der Konfiguration der UDM-Pro vornimmt, werden von Ubiquiti nicht offiziell unterstützt und können zu Fehlfunktionen oder Garantieverlust führen. Alle BAckup werden auf eigene Gefahr durchgeführt. Vor der Installation: Backup, Backup, Backup!!!


## Installation
Nachdem eine Verbindung per SSH zur UDM/UDM Pro hergestellt wurde wird udm-wireguard folgendermaßen installiert:

**1. Download der Dateien**

```
mkdir -p /data/custom
dpkg -l git || apt install git
git clone https://github.com/nerdiges/udm-ipv6.git /data/custom/ipv6
chmod +x /data/custom/ipv6/udm-ipv6.sh
```

**2. Parameter im Script anpassen (optional)**

Im Script kann über einige Variable das Verhalten angepasst werden:

```
######################################################################################
#
# Configuration
#

# check and try to restore IPv6 connection
check_v6=true

# WAN-Interface to be checked
wan_if="eth8 eth9"

# IPv6 hosts used to test IPv6 connection
host1="facebook.de"
host2="google.de"
host3="apple.com"
host4="microsoft.com"

# set ULA on lan interfaces?
lan_ula=true

# set ULA on guest interfaces?
guest_ula=false

# ULA prefix to be used
ula_prefix="fd00:2:0:"

# interfaces listed in exclude will not be assigned any IPv6 ULAs
# Multiple interfaces are to be separated by spaces.
exclude="br0"

#
# No further changes should be necessary beyond this line.
#
######################################################################################
```

Die Konfiguration kann auch in der Datei udm-wireguard.conf gespeichert werden, die bei einem Update nicht überschrieben wird.

**3. Einrichten der systemd-Services**

Ist auf der UDM-Pro auch das Script [udm-firewall](https://github.com/nerdiges/udm-firewall) installiert, kann dieser Schritt übersprungen werden, da das Script automatisch von [udm-firewall](https://github.com/nerdiges/udm-firewall) mit ausgeführt wird. Damit das funktioniert müssen sowohl das [udm-firewall](https://github.com/nerdiges/udm-firewall) als auch udm-ipv6, wie in den jeweiligen README.md beschrieben installiert wurden. 

```
# Install udm-ipv6.service und timer definition file in /etc/systemd/system via:
ln -s /data/custom/ipv6/udm-ipv6.service /etc/systemd/system/udm-ipv6.service
ln -s /data/custom/ipv6/udm-ipv6.timer /etc/systemd/system/udm-ipv6.timer

# Reload systemd, enable and start the service and timer:
systemctl daemon-reload
systemctl enable udm-ipv6.service
systemctl start udm-ipv6.service
systemctl enable udm-ipv6.timer
systemctl start udm-ipv6.timer

# check status of service and timer
systemctl status udm-ipv6.timer udm-ipv6.service
```

