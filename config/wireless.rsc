# jan/02/1970 01:09:27 by RouterOS 6.18
# software id = 8E9X-W5NG
#
/interface bridge
add l2mtu=1600 name=bridge1
/interface wireless
set [ find default-name=wlan1 ] band=2ghz-b/g/n channel-width=\
    20/40mhz-ht-above disabled=no frequency=5180 l2mtu=2290 mode=ap-bridge \
    ssid=UKSA
/interface bridge port
add bridge=bridge1 interface=ether1
add bridge=bridge1 interface=wlan1
/ip address
add address=192.168.88.10/24 interface=ether1 network=192.168.88.0
/ip upnp
set allow-disable-external-interface=no
/system leds
set 0 interface=wlan1
/system routerboard settings
set cpu-frequency=600MHz
