############################
#!/bin/bash
#design by JLLormeau Dynatrace
# version beta
export PROJECT=k8slab

. env.sh
echo "==> install  easyTrade on K3S with cloud native operator"
echo "==> export DT_TENANT_URL="$DT_TENANT_URL
echo "==> export DT_API_TOKEN="$DT_API_TOKEN
echo "==> export PROJECT="$PROJECT
read  -p "Press any key to continue " pressanycase

echo "==> clean env (OA, AG, easytravel docker)"
sudo /opt/dynatrace/oneagent/agent/uninstall.sh
sudo /opt/dynatrace/gateway/uninstall.sh
/home/dynatracelab_easytraveld/start-stop-easytravel.sh stop
sudo rm /etc/init.d/start-stop-easytravel.sh
sleep 5

echo "==> k3s installation"
cd ~;
curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=v1.27 K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--disable=traefik" sh -s -
sleep 5

echo "==> dynakuke fullstack generation"
echo 'apiVersion: dynatrace.com/v1beta1
kind: DynaKube
metadata:
  name: $PROJECT
  namespace: dynatrace
  annotations:
spec:
  apiUrl: $DT_TENANT_URL/api
  tokens: "dynakube"
  networkZone: $PROJECT
  oneAgent:
    cloudNativeFullStack:
      tolerations:
        - effect: NoSchedule
          operator: Exists
        - effect: NoSchedule
          operator: Exists
      args:
        - --set-host-group=$PROJECT
      env:
      - name: ONEAGENT_ENABLE_VOLUME_STORAGE
        value: "true"
  activeGate:
    capabilities:
      - routing
      - kubernetes-monitoring
      - dynatrace-api
    image: ""
    group: "$PROJECT"
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

#echo "==> restart easytrade"
#kubectl delete --all pods -n easytrade 
echo "==> enjoy"
#end
