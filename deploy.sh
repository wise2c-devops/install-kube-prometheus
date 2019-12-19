#!/bin/bash
set -e

MyImageRepositoryIP=`cat components.txt |grep "Harbor Address" |awk '{print $3}'`
MyImageRepositoryProject=library
KubePrometheusVersion=`cat components.txt |grep "KubePrometheus Version" |awk '{print $3}'`
NAMESPACE=monitoring

######### Push images #########
docker load -i file/kube-prometheus-images-v$KubePrometheusVersion.tar

for file in $(cat file/images-list.txt); do docker tag $file $MyImageRepositoryIP/$MyImageRepositoryProject/${file##*/}; done

echo 'Images taged.'

for file in $(cat file/images-list.txt); do docker push $MyImageRepositoryIP/$MyImageRepositoryProject/${file##*/}; done

echo 'Images pushed.'

######### Update deploy yaml files #########
cd file
rm -rf kube-prometheus-$KubePrometheusVersion
tar zxvf kube-prometheus-v$KubePrometheusVersion-origin.tar.gz
cd kube-prometheus-$KubePrometheusVersion
sed -i "s/quay.io\/coreos/$MyImageRepositoryIP\/$MyImageRepositoryProject/g" $(grep -lr "quay.io/coreos" ./ |grep .yaml)
sed -i "s/quay.io\/prometheus/$MyImageRepositoryIP\/$MyImageRepositoryProject/g" $(grep -lr "quay.io/prometheus" ./ |grep .yaml)
sed -i "s/grafana\/grafana/$MyImageRepositoryIP\/$MyImageRepositoryProject\/grafana/g" $(grep -lr "grafana/grafana" ./ |grep .yaml)
sed -i "s/gcr.io\/google_containers/$MyImageRepositoryIP\/$MyImageRepositoryProject/g" $(grep -lr "gcr.io/google_containers" ./ |grep .yaml)
#sed -i "s/k8s.gcr.io/$MyImageRepositoryIP\/$MyImageRepositoryProject/g" $(grep -lr "k8s.gcr.io" ./ |grep .yaml)

######### Update yaml files to supports K8s v1.16 #########
cd manifests/
sed -i "s#apps/v1beta2#apps/v1#g" $(ls *.yaml)
cd setup
sed -i "s#apps/v1beta2#apps/v1#g" $(ls *.yaml)
cd ../../

######### Deploy prometheus operator and kube-prometheus #########

kctl() {
    kubectl --namespace "$NAMESPACE" "$@"
}

kubectl apply -f manifests/setup

# Wait for CRDs to be ready.
printf "Waiting for Operator to register custom resource definitions..."

crd_servicemonitors_status="false"
until [ "$crd_servicemonitors_status" = "True" ]; do sleep 1; printf "."; crd_servicemonitors_status=`kctl get customresourcedefinitions servicemonitors.monitoring.coreos.com -o jsonpath='{.status.conditions[1].status}' 2>&1`; done

crd_prometheuses_status="false"
until [ "$crd_prometheuses_status" = "True" ]; do sleep 1; printf "."; crd_prometheuses_status=`kctl get customresourcedefinitions prometheuses.monitoring.coreos.com -o jsonpath='{.status.conditions[1].status}' 2>&1`; done

crd_alertmanagers_status="false"
until [ "$crd_alertmanagers_status" = "True" ]; do sleep 1; printf "."; crd_alertmanagers_status=`kctl get customresourcedefinitions alertmanagers.monitoring.coreos.com -o jsonpath='{.status.conditions[1].status}' 2>&1`; done

until kctl get servicemonitors.monitoring.coreos.com > /dev/null 2>&1; do sleep 1; printf "."; done
until kctl get prometheuses.monitoring.coreos.com > /dev/null 2>&1; do sleep 1; printf "."; done
until kctl get alertmanagers.monitoring.coreos.com > /dev/null 2>&1; do sleep 1; printf "."; done

echo 'Phase1 done!'

kubectl apply -f manifests/
cd ../../

echo 'Phase2 done!'

kubectl apply -f template/prometheus-service.yaml
kubectl apply -f template/alertmanager-service.yaml
kubectl apply -f template/grafana-service.yaml

echo 'NodePorts are set for services.'

kubectl apply -f addon/k8s

echo 'Kube-Prometheus is installed.'

#kubectl apply -f addon/etcd-monitor.yaml
