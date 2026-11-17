# Teste em cluster das NetworkPolicy do CP06. Uso:
#   kind create cluster --name np06 && bash setup.sh   (cria namespaces e pods)
#   kubectl --context kind-np06 apply -f <politica.yaml> && bash probe.sh
#   kind delete cluster --name np06
set -e
K="kubectl --context kind-np06"
for ns in sentinel-prod relay-prod edge forge-prod cerebro-prod other; do $K create ns $ns --dry-run=client -o yaml | $K apply -f - >/dev/null; done
# servidor: escuta em varias portas (80 sentinel; 5432; 9200; 8080)
srv() { # ns nome label-k=v portas...
 ns=$1; n=$2; lab=$3; shift 3; cmd=""; for p in "$@"; do cmd="$cmd nc -lk -p $p -e /bin/echo ok &"; done
 $K -n $ns run $n --image=busybox:1.36 --labels=$lab --restart=Never -- sh -c "$cmd sleep 36000" >/dev/null
}
srv sentinel-prod sentinel app=sentinel 80 8080
srv forge-prod forge app=forge 5432 9999
srv cerebro-prod cerebro app=cerebro 9200
for p in "relay-prod relay app=relay" "edge gw app=api-gateway" "other intruso app=x"; do set -- $p; $K -n $1 run $2 --image=busybox:1.36 --labels=$3 --restart=Never -- sleep 36000 >/dev/null; done
$K -n sentinel-prod run cliente-no-sentinel --image=busybox:1.36 --labels=app=sentinel --restart=Never -- sleep 36000 >/dev/null
$K wait --for=condition=Ready pod --all --all-namespaces --timeout=300s -l 'run' >/dev/null 2>&1 || true
