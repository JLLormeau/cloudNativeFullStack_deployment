# cloudNativeFullStack_deployment

Prerequisiste:
- linux VM (recommanded B8ms Azure) 8 CPU, 32 GB
- https://github.com/JLLormeau/lab-environment-for-dynatrace-training

Variables:  
- export DT_TENANT_URL="https://abcd.live.dynatrace.com"
- export DT_API_TOKEN="XXX"
- export PROJECT=demolab

Installation:
- k3s version = 1.27 (traeffic disabled)
- dynatrace operator with cloudNativeFullStack enabled (latest version)
- easyTrade (more information here : https://github.com/Dynatrace/easytrade)

Use case: 
 - create a full environment Dynatrace + kubernetes ° easytradde on 5 minutes.
 - usefull for training

Known limitation:  
 - host k3s is not reconnized as a technologie = "Kubernetes" (softwaretechnologies(~"KUBERNETES~"))
 - impact : the Dashboards "Kubernetes cluster overview" is impacted on 5 tiles
 - workaround : clone the dashboard and use another filter on these tiles   
