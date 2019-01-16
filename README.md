# simple-dns-adblock
simple dns adblocker using dnsmasq
![alt text](https://raw.githubusercontent.com/wilyarti/simple-dns-adblock/master/graph.png)
![alt text](https://raw.githubusercontent.com/wilyarti/simple-dns-adblock/master/graph2.png)


## Web Front End
Please see my repository https://github.com/wilyarti/opens3.net/ for the front
end.

To build a Fat Jar run:
> ./gradlew build

This will generate a Fat Jar that contains the web server that you can run with
Java in the build/libs/ directory.

You can see an example running on http://opens3.net

### Running the web front end
To run the web front end (on FreeBSD): 
> su -m nobody -c "java -jar opens3.net-0.0.1-all.jar"

This will run the server as the user nobody. If you want allow connections from the internet use Nginx as a proxy server.

### Updating the blocklist
To update the blocklist simple run (on FreeeBSD):
>su -m nobody -c "update_dnsmasq"

After placing update_dnsmasq in your PATH and making it executable (chmod +x
update_dnsmasq).

This script will pull down the latest blocklist consisting of over 130,000 domains.

### Running the log processor
"enterstats.pl" first processes all the lines in the dnmasq logfile then monitors the file for changes and continues to add entried to a redis database.

The database is queried by the Web App which sends request which are processed
by the Kotlin backend.

To run:
>su -m nobody -c "perl enterstats.pl" &


#### To install DNS Server (FreeBSD only):
Install dnsmasq. Enable dnsmasq:
```
sysrc dnsmasq_enable="YES"
sysrc dnsmasq_flags="-R"
```
Create directory /usr/local/etc/dnsmasq.d/ with "nobody:nobody" permissions. 

Place the update_dnsmasq in /usr/local/bin/ (make it executable - chmod +x )

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


