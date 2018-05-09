# simple-dns-adblock
simple dns adblocker using dnsmasq
![alt text](https://raw.githubusercontent.com/wilyarti/simple-dns-adblock/master/Screenshot_2018-05-09_23-59-00.png)

#### To install on windows:

Download windnsblock.exe and run as administrator this will use the host file to DNS block the 122k domains in the main Ad Blocker list.

#### To install (FreeBSD only):
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
I have written a simple JavaScript based grapher that uses Perl and Mojolicious as a backend.

It is currently only for internal use at it analyses the whole log file ever 3rd time a GET request is issued.

The future plan is to have a dedicated server that get's queries about certain statistics and analyses the log file as it runs.

To run the program:
```
1.) create /home/nobody and /home/nobody/public
2.) place graphstats.pl in /home/nobody
3.) change ownership to "nobody:nobody" 
> chown -R nobody:nobody /home/nobody
4.) run the server
> su -m nobody -c 'hypnotoad graphstats.pl'
5.) type in the following url:
> 127.0.0.1:8080/03:28
```

The url can be changed to your hosts IPV4 public address, the 03:28 refers to the month and day. Change it accordingly to which date you want polled.

