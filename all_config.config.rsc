# apr/23/2015 08:45:46 by RouterOS 6.18
# software id = TPUB-W0EI
#
/interface ethernet
set [ find default-name=ether1 ] comment=BGAN name=ether1-gateway
set [ find default-name=ether2 ] comment=WebRelay name=ether2-master-local
set [ find default-name=ether3 ] comment=HotSpot name=ether3-master-local
set [ find default-name=ether4 ] comment=NUC master-port=ether2-master-local \
    name=ether4-slave-local
set [ find default-name=ether5 ] comment=Support master-port=\
    ether2-master-local name=ether5-slave-local
/ip neighbor discovery
set ether1-gateway comment=BGAN discover=no
set ether2-master-local comment=WebRelay
set ether3-master-local comment=HotSpot
set ether4-slave-local comment=NUC
set ether5-slave-local comment=Support
/ip hotspot profile
add hotspot-address=10.5.50.1 login-by=mac,http-pap name=hsprof1
/ip pool
add name=default-dhcp ranges=192.168.88.10-192.168.88.254
add name=hs-pool-3 ranges=10.5.50.2-10.5.50.254
/ip dhcp-server
add address-pool=default-dhcp disabled=no interface=ether2-master-local \
    lease-time=10m name=default
add address-pool=hs-pool-3 disabled=no interface=ether3-master-local \
    lease-time=1h name=dhcp1
/ip hotspot
add address-pool=hs-pool-3 disabled=no interface=ether3-master-local name=\
    hotspot1 profile=hsprof1
/ip address
add address=192.168.88.5/24 comment="Local Network" interface=\
    ether2-master-local network=192.168.88.0
add address=10.5.50.1/24 comment="hotspot network" interface=\
    ether3-master-local network=10.5.50.0
/ip dhcp-client
add comment="default configuration" dhcp-options=hostname,clientid disabled=\
    no interface=ether1-gateway
/ip dhcp-server network
add address=10.5.50.0/24 comment="hotspot network" gateway=10.5.50.1
add address=192.168.88.0/24 comment="default configuration" dns-server=\
    192.168.88.1 gateway=192.168.88.1
/ip dns
set allow-remote-requests=yes servers=8.8.8.8
/ip dns static
add address=192.168.88.1 name=router
/ip firewall filter
add action=passthrough chain=unused-hs-chain comment=\
    "place hotspot rules here" disabled=yes
add chain=input comment="default configuration" protocol=icmp
add chain=input comment="default configuration" connection-state=established
add chain=input comment="default configuration" connection-state=related
add action=drop chain=input comment="default configuration" in-interface=\
    ether1-gateway
add chain=forward comment="default configuration" connection-state=\
    established
add chain=forward comment="default configuration" connection-state=related
add action=drop chain=forward comment="default configuration" \
    connection-state=invalid
/ip firewall nat
add action=passthrough chain=unused-hs-chain comment=\
    "place hotspot rules here" disabled=yes
add action=masquerade chain=srcnat comment="default configuration" \
    out-interface=ether1-gateway
add action=masquerade chain=srcnat comment="masquerade hotspot network" \
    src-address=10.5.50.0/24
/ip hotspot user
add name=admin
/ip hotspot walled-garden
add comment="place hotspot rules here" disabled=yes
/ip hotspot walled-garden ip
add action=accept disabled=no dst-address=192.168.88.50 server=hotspot1
/ip upnp
set allow-disable-external-interface=no
/system ntp client
set enabled=yes primary-ntp=91.189.94.4
/tool mac-server
set [ find default=yes ] disabled=yes
add interface=ether2-master-local
add interface=ether3-master-local
add interface=ether4-slave-local
add interface=ether5-slave-local
/tool mac-server mac-winbox
set [ find default=yes ] disabled=yes
add interface=ether2-master-local
add interface=ether3-master-local
add interface=ether4-slave-local
add interface=ether5-slave-local
