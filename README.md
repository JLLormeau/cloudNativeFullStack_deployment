# cloudNativeFullStack_deployment

Prerequisiste:
- linux VM recommanded 4CPU & 16GB (Azure B4ms)
-  https://github.com/JLLormeau/lab-environment-for-dynatrace-training

Variables:  
- export DT_TENANT_URL="https://abcd.live.dynatrace.com"
- export DT_API_TOKEN="XXX"
- export CLUSTER=k3slab

Installation:
- k3s version = 1.27 (traeffic disabled)
- dynatrace operator with cloudNativeFullStack enabled (latest version)
- easyTrade 

=> run: 

    wget -O cloudNativeFullStack_deployement.sh https://raw.githubusercontent.com/JLLormeau/cloudNativeFullStack_deployment/main/cloudNativeFullStack_deployement.sh
    bash cloudNativeFullStack_deployement.sh

Use case: 
 - create a full environment Dynatrace + kubernetes easytradde on 5 minutes.
 - usefull for training

Additionnal configurations recommanded:  
 - from the K8S settings view : enable monitor events, anomalie detection 
 - follow the recommandation for easytrade : https://github.com/Dynatrace/easytrade

Known limitations:  
 - host k3s is not reconnized as a technologie = "Kubernetes" (softwaretechnologies("KUBERNETES"))
 - impact : the Dashboards "Kubernetes cluster overview" is impacted on 5 tiles
 - workaround : clone the dashboard and use another filter on these tiles
 - at the beginning some standalone/paas hostid in are created, but once the installation is completed these hostid disappear

