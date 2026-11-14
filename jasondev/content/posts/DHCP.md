+++
date = '2026-11-14T13:11:11+01:00'
draft = false
title = 'DHCP'
lang=es,en,ita
+++

# DHCP

Es el protocolo de la capa de aplicación diseñado para implementar un servidor de
configuración automática de redes TCP/IP.

Permite a los nodos de una red obtener sus parámetros de configuración de manera
totalmente automática sin intervención manual.

## Funcionamiento

- Asignación dinámica: Un servidor posee rangos de IP dinámica y las
  asigna progresivamente a los clientes
- Registro MAC-IP: Asocia en todo momento la IP asignada con la dirección **MAC**.

### Proceso petición DHCP

1. Cuando un cliente DHCP se conecta a la red envía una solicitud en forma de broadcast
   a través de la red
2. Todos los servidores alcanzados por la solicitud responden al cliente con sus
   respectivas propuestas
3. El cliente acepta una de ellas haciéndoselo saber al servidor elegido
4. El servidor le otorga la información requerida y un _lease time_.
5. Esta información se mantiene asociada mientras el cliente no desactive su
   interfaz de red o no expire el _lease time_.
6. Renovaciones:

- Cada vez que el cliente arranca, cada cierto tiempo o antes de la expiración
  del _lease time_.
- Cuando se acaba el _lease time_.
  - Renovar la información del cliente.
  - Asignar otra nueva.
  - Extender el plazo.

## Ventajas

- Conexión de hosts a la red sin intervención del administrador
- Disminución de errores en la configuración de red de los hosts.
- Permite reestructurar la red y añadir/modificar servicios sin tener que
  acceder a los equipos.

## ZeroConf networking (mDNS)

Conjunto de técnicas que permiten configurar de forma automática una red IP sin
configuración manual.

- Avahi: Linux

  - Permite conectar un host y directamente empezar a _hablar_ con otros hosts
    en la red, como **impresoras u otros hosts**. A diferencia de Bonjour puede
    perder servicios cuando se manejan redes de cierto tamaño. Resulta la
    implementación más completa del protocolo para asignar IPs y descubrir _hosts_ y
    asignarles un dominio .local a una IP y que otros hosts descubran las
    impresoras sin tener que saber su IP.

- Bonjour: MacOS
- APIPA: Windows

  - Le **asigna una IP** del rango link-local **169.254.0.0/16** (169.254.1.0 - 169.254.254.255),
    pero no
    configura el resto de parámetros. Verifica además que la IP no esté en uso

## Arquitectura de la Asignación de IPs

En una red local se asignan IPs fijas a hosts que proveen servicios tipo **DHCP** o
**DNS**, reservándolas del _pool dhcp_ y IPs dinámicas para el resto de hosts.

### Componentes

- **Cliente DHCP**: el host que solicita su configuración de red (IP, máscara,
  gateway, DNS y _lease time_).
- **Servidor DHCP**: el host que mantiene el rango de IPs y los parámetros de
  configuración, y los concede a los clientes.
- Las IPs se conceden de forma dinámica y por tiempo limitado: el cliente solo
  puede usar la IP durante el _lease time_ que fija el servidor.

### Asignación de la IP

El servidor escucha en el puerto UDP 67 y el cliente en el 68. Como el cliente
todavía no tiene IP, los primeros mensajes se envían por _broadcast_.

1. **DHCPDISCOVER**: el cliente difunde la petición (IP origen 0.0.0.0, IP
   destino 255.255.255.255, MAC destino FF:FF:FF:FF:FF:FF, puerto 68 ➜ 67).
   Incluye el tipo de mensaje (opción 53), su identificador de cliente
   (opción 61) y la lista de parámetros que solicita (opción 55).
2. **DHCPOFFER**: el servidor responde (puerto 67 ➜ 68) con la IP que ofrece
   (`yiaddr`), la máscara (opción 1), el gateway (opción 3), los DNS
   (opción 6), el _lease time_ (opción 51) y su identificador de servidor
   (opción 54).
3. **DHCPREQUEST**: el cliente acepta una oferta con otro _broadcast_
   (0.0.0.0 ➜ 255.255.255.255, puerto 68 ➜ 67), indicando la IP que pide
   (opción 50) y el servidor elegido (opción 54). Al ser un _broadcast_, los
   servidores no elegidos también lo reciben y descartan sus ofertas.
4. **DHCPACK**: el servidor confirma la concesión (opción 53 = 5) con la misma
   configuración de la oferta. El cliente configura su interfaz con esos
   datos y empieza a contar el _lease time_.

Si el servidor no puede conceder la IP pedida responde con un **DHCPNAK**
(opción 53 = 6) y el cliente vuelve a empezar por el **DHCPDISCOVER**.

### Renovación de la concesión

- Al llegar a la mitad del _lease time_ (T1), el cliente envía un
  **DHCPREQUEST** por _unicast_ al servidor que le concedió la IP (IP origen
  la del cliente y `ciaddr` con su IP). No repite el **DHCPDISCOVER** ni
  incluye las opciones 50 y 54.
- El servidor responde con un **DHCPACK** por _unicast_ y la concesión se
  extiende: el _lease time_ vuelve a empezar.
- Si el servidor no responde, al 87,5 % del _lease time_ (T2) el cliente
  difunde el **DHCPREQUEST** por _broadcast_ para que lo conteste cualquier
  servidor (_rebind_).

### Liberación de la concesión

- Cuando el cliente ya no necesita la IP (por ejemplo, al apagarse de forma
  ordenada o con `ipconfig /release` o `dhclient -r`), envía un **DHCPRELEASE**
  por _unicast_ al servidor (opción 53 = 7, con su IP en `ciaddr` y la opción
  54).
- El servidor no responde: marca la IP como libre y puede concederla a otro
  cliente.
- Si el cliente no envía el **DHCPRELEASE** (por ejemplo, si se apaga de golpe),
  el servidor recupera la IP cuando expira el _lease time_.

### Varios Servidores (HA)

En una misma red pueden coexistir varios servidores **DHCP**.

Los servidores **DHCP** no se comunican entre ellos para saber qué direcciones
IP deben asignar cada uno. Es responsabilidad del sysadmin evitar conflictos
en la asignación de IPs.

#### DHCP Failover protocol

Si tenemos 2 o más servidores **DHCP** en la misma red tenemos 2 opciones:

- Asignar diferentes rangos IP a cada servidor
- Utilizar el mismo rango de direcciones ➜ **DHCP Failover protocol**
- Podemos tener varias opciones de configuración:

## Configuración

Los principales parámetros con **DHCP** son:

- IP y máscara de red

- Tiempo de concesión, _lease time_.

- Servidores DNS y dominio.

- **GW** (gateway)

### Lease time

Es el tiempo que un cliente **DHCP** mantiene como propios los datos de
configuración que le otorga un servidor.

El cliente debe solicitar la renovación:

- Cuando el cliente arranca
- Cada cierto tiempo
- Cuando alcanza la mitad del _lease time_ (T1) y de nuevo al 87,5 % (T2).

  - Renueva la información del cliente extendiendo el _lease time_
  - Asigna una nueva información junto con su _lease time_.

El tiempo de concesión facilita la tarea de reestructuración.
El tiempo depende de las características de la red.
Redes con rango alto de direcciones IP y configuración de los clientes rara vez
cambia ➜ Incrementar _lease time_, para reducir tráfico de red.

Redes con rango muy limitado de direcciones IP y configuración de los clientes
cambia frecuentemente ➜ reducir el _lease time_ para que las direcciones IPs que
no están siendo usadas estén disponibles para nuevas asignaciones.

### Debian/Linux (isc-dhcp-server)

```bash
# Comandos configuración

## Mostrar la ip del host
ip a

## Editamos /etc/network/interfaces
sudoedit /etc/network/interfaces

## Cambiamos el hostname (server1, c1,c2)
sudoedit /etc/hostname
sudo hostnamectl set-hostname <nombre-hostname>
hostnamectl

## Reiniciamos networking.service

sudo systemctl stop networking.service
sudo systemctl start networking.service
```

Ejemplo de sentencias a usar en el fichero /etc/network/interfaces

```dsconfig

allow-hotplug <dev-name>

iface <dev-name> inet <[manual][dhcp][static]>
  [address <ip-address>/<netmask-cidr>]
  [netmask <netmask>]
  [gateway <gateway-ip-address>]
  [dns-nameservers <ip-address>]
  [dns-search <domain-name>]
  [hostname <hostname-to-be-requested>]

```

#### Configuración del servicio

Instalamos con `sudo apt update&&sudo apt install isc-dhcp-server`.
Editamos el fichero `sudoedit /etc/default/isc-dhcp-server`.

```dsconfig
INTERFACESv4="<nombre-interfaz>"
```

Editamos el fichero `sudoedit /etc/dhcp/dhcpd.conf`

```dsconfig
  subnet [<network-address>] netmask [<netmask>] {
  range [<ip-address-range>];
  option routers [<gateway-ip-address>];
  option domain-name "<local-domain-assigned-to-clients>";
  option domain-name-servers [<dns-ip-address>];
  default-lease-time [<lease-time-in-seconds>];
  max-lease-time [<lease-time-in-seconds>];
}

# Reserve static IP
host <hostname>{
  hardware ethernet [<MAC>];
  fixed-address [<ip-address>];
}
```

```bash
sudo dhcpd -t -cf /etc/dhcp/dhcpd.conf
sudo systemctl stop isc-dhcp-server
sudo systemctl start isc-dhcp-server
sudo systemctl status isc-dhcp-server
```

Comprobamos los logs del servidor para verificar el correcto funcionamiento o
detectar errores en el servicio, se pueden revisar los registros del sistema
mediante los siguientes comandos:
Ver los registros del servicio en tiempo real usando journalctl:

```bash
sudo journalctl -xeu isc-dhcp-server -f
```

O con el fichero de registros del sistema

```bash
grep "dhcpd" /var/log/syslog
```

##### Fichero de concesiones

El fichero **dhcpd.leases** es utilizado por el servidor **DHCP** para mantener
un registro persistente de todas las concesiones activas e históricas asignadas
a los clientes. En este fichero se almacenan la siguiente información:

- **Direcciones IPs asignadas**: dirección de red otorgada a los clientes.
- **Direcciones MAC**: dirección física de los clientes
- **Lease time**: Tiempo de concesión.

#### Configuración de los clientes debian

Para configurar una interfaz de red en Debian/Linux, para que solicite automáticamente
una dirección IP a través de **DHCP**, se debe editar el archivo de configuración
de red del sistema

```bash
sudoedit /etc/network/interfaces
```

Editamos el fichero con estas sentencias:

```dsconfig
auto <device-name>
iface <device-name> inet dhcp
```

Reiniciamos el servicio de red:

```bash
sudo systemctl stop networking
sudo systemctl start networking
```

##### Gestión de la concesión cliente DHCP

En los clientes Debian/Linux, se utiliza **dhclient** para administrar la obtención
y liberación de direcciones IPs asignadas por el servidor **DHCP**.

```bash

# Solicitar o renovar
sudo dhclient "<device-name>"

# Liberar y descartar la concesión
sudo dhclient -r "<device-name>"
# Consultar el estado
ip addr show  "<device-name>"
```

El fichero dhclient.leases almacena el registro de las concesiones obtenidas por
el cliente. En él se pueden consultar detalladamente los siguientes parámetros:

- fixed-address: La dirección IP asignada al cliente por el servidor **DHCP**.
- dhcp-server-identifier: La dirección IP del servidor **DHCP**.
- renew, rebind, expire y obtai: los tiempos y fechas exactas de inicio y fin de
  la concesión, marcando cuándo _lease time_, cuándo se intentará renovar y la
  fecha de expiración definitiva.
- option routers: La dirección IP del gateway predeterminada asignada.
- option domain-name-servers: La lista de servidores **DNS** proporcionados
- option subnet-mask y domain-name: La máscara de subred y el nombre de dominio
  asignados al equipo.

```bash
cat "/var/lib/dhcp/dhclient.<device-name>.leases"
```

```bash
cat /etc/resolv.conf
```

```bash
dhcpd -U <device-name>
```

## Proceso DHCP entre cliente y servidor

El servidor permanece a la escucha en el puerto 67 UDP.

- Descubrimiento **DHCP** por el puerto 67.

  - El cliente difunde por broadcast un paquete **DHCPDISCOVER**

- Oferta **DHCP** por el puerto 68.
- Solicitud **DHCP** por el puerto 67 UDP.
- ACK **DHCP**.

## Seguridad

No incluye ningún mecanismo de autenticación. Posibles ataques:

- **DHCP spoofing**: Suplantación del servidor **DHCP**. Servidores no
  autorizados suplantan al servidor **DHCP** y proporcionan configuraciones
  falsas.
- **DoS**: Denegación de servicio. Cliente no autorizado agota las direcciones IP.
  Solicita una dirección, cambia su **MAC** y vuelve a solicitar otra
- **_Man-in-the-middle_**: El servidor no autorizado envía una dirección válida
  pero le da su dirección IP como puerta de enlace. Recibe paquetes que luego
  reenvía al router para que el cliente no se dé cuenta del ataque.
- **Configuración manual**: Clientes no autorizados podrían acceder a los
  recursos configurando manualmente la **NIC**.

Soluciones:

- **DHCP snooping**: En el switch se declara de confianza el puerto por el que
  genera respuestas el servidor **DHCP** autorizado, siendo todos los demás
  puertos no fiables. Resuelve el problema del **_Man-in-the-middle_** y spoofing

- Logs del servidor **DHCP**: Auditar posibles peticiones no autorizadas.
