# simple-dns-adblock
simple dns adblocker using dnsmasq

Install dnsmasq.

All directories need to be "nobody:nobody" permissions. Place the update_dnsmasq in /usr/local/bin/

Add the following lines to /etc/crontab:
30      5       1       *       *       root    update_dnsmasq
30      5       1       *       *       root    service dnsmasq restart

That should be all!
