############################
#!/bin/bash
#design by JLLormeau Dynatrace
# version beta
echo ""
echo ""
echo ""
echo "==> Welcome to the cloudNAtiveFullStack_deployment script" 
echo "    automatic installation of K3S on your local VM " 
echo "    automatic installation of dynatrace operator on your tenant"
echo "    automatic installation of easytrade on k3s"
echo ""
echo "==> Sizing"
echo "    VM recommanded 4 CPU + 16 GB (Azure B4ms)" 
read  -p "Press any key to continue " pressanycase
echo ""
echo "==> Setup the variables"  
echo "    export DT_TENANT_URL="$DT_TENANT_URL
echo "      - https://abcd.live.dynatrace.com"
echo "    export DT_API_TOKEN="`echo $DT_API_TOKEN| cut -d '.' -f 1,2`"..."			            
echo "      - scope Operator_token + Data_ingest_token"
echo "    export CLUSTER="$CLUSTER
echo "      - for cluster name, hostgroup, group = [a-z]([-a-z0-9]\*[a-z0-9])\? "
read  -p "Press any key to continue " pressanycase
echo ""
echo "==> Clean VM"
echo "    uninstall OneAgent, ActiveGate, easytravel docker and previous k3s version"
read  -p "Press any key to continue " pressanycase
echo ""
sudo /opt/dynatrace/oneagent/agent/uninstall.sh
sudo /opt/dynatrace/gateway/uninstall.sh
/home/dynatracelab_easytraveld/start-stop-easytravel.sh stop
sudo rm /etc/init.d/start-stop-easytravel.sh
/usr/local/bin/k3s-uninstall.sh
sleep 5

echo "==> k3s installation"
cd ~;
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=v1.27 K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--disable=traefik" sh -s -
sleep 5

echo "==> dynakuke fullstack generation"
echo 'apiVersion: dynatrace.com/v1beta1
kind: DynaKube
metadata:
  name: $CLUSTER
  namespace: dynatrace
  annotations:
spec:
  apiUrl: $DT_TENANT_URL/api
  tokens: "dynakube"
  networkZone: $CLUSTER
  oneAgent:
    cloudNativeFullStack:
      tolerations:
        - effect: NoSchedule
          operator: Exists
        - effect: NoSchedule
          operator: Exists
      args:
        - --set-host-group=$CLUSTER
      env:
      - name: ONEAGENT_ENABLE_VOLUME_STORAGE
        value: "true"
  activeGate:
    capabilities:
      - routing
      - kubernetes-monitoring
      - dynatrace-api
    image: ""
    group: "$CLUSTER"
    resources:
      requests:
        cpu: 500m
        memory: 512Mi
      limits:
        cpu: 1000m
        memory: 1.5Gi
    tolerations:
     - effect: NoSchedule
       operator: Exists' > dynakube.yaml
echo "==> namespace dynatrace"
kubectl create namespace dynatrace
sleep 5

echo "==> operator installation"
kubectl apply -f https://github.com/Dynatrace/dynatrace-operator/releases/latest/download/kubernetes.yaml
sleep 5

echo "==> operator csi"
kubectl apply -f https://github.com/Dynatrace/dynatrace-operator/releases/latest/download/kubernetes-csi.yaml
sleep 5

echo "==> create secret"
kubectl -n dynatrace create secret generic dynakube --from-literal=apiToken=$DT_API_TOKEN  --from-literal=dataIngestToken=$DT_API_TOKEN
kubectl -n dynatrace wait pod --for=condition=ready --selector=app.kubernetes.io/name=dynatrace-operator,app.kubernetes.io/component=webhook --timeout=300s
sleep 5

echo "==> dynakube installation"
envsubst < dynakube.yaml | kubectl apply -f -
sleep 5

echo "==> dynakube validation"
kubectl exec deploy/dynatrace-operator -n dynatrace -- dynatrace-operator troubleshoot
sleep 5

echo "==> start activegate pods"
while [[ `kubectl get pods -n dynatrace | grep activegate | grep "0/"` ]];do kubectl get pods -n dynatrace;echo "==> waiting for activegate  pod ready";sleep 3; done

echo "==> easytrade namespace"
kubectl create namespace easytrade
sleep 5

echo "==> easytrade copy source"
cd ~;
git clone https://github.com/Dynatrace/easytrade.git
cd easytrade
echo "==> easytrade deployment"
kubectl -n easytrade apply -f ./kubernetes-manifests
cd ~;
sleep 5

while [[ `kubectl get pods -n easytrade | grep frontend | grep "0/"` ]];do kubectl get pods -n easytrade;echo "==> waiting for frontend pod ready";sleep 3; done
kubectl -n easytrade get svc

echo "==> need to restart easytrade?"
read  -p "Press any key to continue " pressanycase
kubectl delete --all pods -n easytrade 
echo "==> enjoy"
#end
