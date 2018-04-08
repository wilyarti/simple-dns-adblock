# simple-dns-adblock
simple dns adblocker using dnsmasq
![alt text](https://github.com/wilyarti/simple-dns-adblock/raw/master/2018-03-07_10.dat.jpg)

#### To install on windows:

Download windnsblock.exe and run as administrator.

#### To install:
Install dnsmasq. Enable dnsmasq:
```
sysrc dnsmasq_enable="YES"
sysrc dnsmasq_flags="-R"
```
Create directory /usr/local/etc/dnsmasq.d/ with "nobody:nobody" permissions. 

Place the update_dnsmasq in /usr/local/bin/ (make it executable - chmod +x )

Add the following lines to /etc/crontab:
```
30      5       1       *       *       nobody   update_dnsmasq
30      5       1       *       *       nobody   service dnsmasq restart
```

Create this file (change as neccessary):
usr/local/etc/dnsmasq.d/simple-dns-block.conf 
```
#Config credit - Pi-Hole
addn-hosts=/usr/local/etc/dnsmasq.d/blocklist.txt

localise-queries

no-resolv

cache-size=10000

log-queries=extra
log-facility=/var/log/sdb.log

local-ttl=2

log-async
#open dns servers - change if needed
server=208.67.222.222
server=208.67.220.220
#change interface to match yours
interface=re1
```
Edit /usr/local/etc/dnsmasq.conf:
```
config-dir="/usr/local/etc/dnsmasq.d/"
```
Run update_dnsmasq:
> su -m nobody -c 'update_dnsmasq'

Check for any errors regarding file permissions.

If there are any make sure /usr/local/etc/dnsmasq.d is owned by "nobody:nobody".
Start dnsmasq:
> service dnsmasq start

### Graphing
To create graphs like the one at the top of this document, download minutelog.pl and run this command:
> perl minutelog.pl 28 Mar /var/log/pihole.log

You will need to install GNUplot and ImageMagick installed to create the graphs.

### Web front end
I have written basic web server front end that interprets any dnsmasq log file (provided the blocklist is named "blocklist.txt".

To run it you will need Mojolicious, gnuplot and imagemagick installed.

To run the program:
1.) create /home/nobody and /home/nobody/public
2.) place servestats.pl in /home/nobody
3.) change ownership to "nobody:nobody" 
> chown -R nobody:nobody /home/nobody
4.) run the server
> su -m nobody -c 'hypnotoad servestats.pl'
5.) type in the following url:
> 127.0.0.1:8080/03:28

The url can be changed to your hosts IPV4 public address, the 03:28 refers to the month and day. Change it accordingly to which date you want polled.

To prevent overload only one result per hour will be polled. 

There is no limit to the size of log file being polled as the alogorith is quite efficient - however it is quite slow as it generates all files server side. The first generation may take a few seconds.
