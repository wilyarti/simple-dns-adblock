# simple-dns-adblock
simple dns adblocker using dnsmasq
![alt text](https://raw.githubusercontent.com/wilyarti/simple-dns-adblock/master/dnsblock_stats.png)

## Web Front End
The web front end "rtgraph.pl" connects to a sqlite database created by "enterstats.pl". It pulls usage statistics for a 24 hour period and plots them using canvas.js. For security and privacy reasons only blocked queries are recorded in the sqlite database.

The "rtgraph.pl" server is a Mojolicious Lite web app that uses JSON to communicate with the JavaScript web app.

You can see an example running on http://opens3.net

### Running the web front end
To run the web front end: 
> su -m nobody -c "hypnotoad rtgraph.pl"

This will run the server as the user nobody. If you want allow connections from the internet use Nginx as a proxy server.

### Updating the blocklist
To update the blocklist simple run:
>su -m nobody -c "update_dnsmasq"

After placing update_dnsmasq in your PATH and making it executable.

This script will pull down the latest blocklist consisting of over 130,000 domains.

### Running the log processor
"enterstats.pl" first processes all the lines in the dnmasq logfile then monitors the file for changes and continues to add entried to the sqlite database.

This database is polled by the web app to get statistics to send to the front end.

To run:
>su -m nobody -c "perl enterstats.pl" &


#### Simple windows only version:

Download windnsblock.exe and run as administrator this will use the host file to DNS block the 122k domains in the main Ad Blocker list.

#### To install DNS Server (FreeBSD only):
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


