K="kubectl --context kind-np06"
ip() { $K -n $1 get pod $2 -o jsonpath='{.status.podIP}'; }
S=$(ip sentinel-prod sentinel); F=$(ip forge-prod forge); C=$(ip cerebro-prod cerebro); I=$(ip other intruso)
t() { if $K -n $3 exec $4 -- sh -c "echo x | nc -w 3 $5 $6 >/dev/null 2>&1" 2>/dev/null; then r=ABRE; else r=BLOQUEIA; fi
  [ "$r" = "$2" ] && s=OK || s=FALHA
  printf "%-6s %-38s esperado=%-9s obtido=%s\n" $s "$1" $2 $r; }
t "relay -> sentinel:8081"          ABRE     relay-prod relay $S 8081
t "gateway -> sentinel:8081"        ABRE     edge gw $S 8081
t "outro ns -> sentinel:8081"       BLOQUEIA other intruso $S 8081
t "sentinel -> forge:5432"          ABRE     sentinel-prod sentinel $F 5432
t "sentinel -> forge:9999"          BLOQUEIA sentinel-prod sentinel $F 9999
t "sentinel -> cerebro:9200"        ABRE     sentinel-prod sentinel $C 9200
t "sentinel -> outro ns:8082"       BLOQUEIA sentinel-prod sentinel $I 8082
if $K -n sentinel-prod exec sentinel -- nslookup kubernetes.default.svc.cluster.local >/dev/null 2>&1; then echo "OK     DNS: nslookup resolve"; else echo "FALHA  DNS: nslookup nao resolve"; fi
