#!/bin/bash
KubePrometheusVersion=`cat components.txt |grep "KubePrometheus Version" |awk '{print $3}'`
kubectl delete  --ignore-not-found=true -f file/kube-prometheus-$KubePrometheusVersion/manifests/
kubectl delete  --ignore-not-found=true -f file/kube-prometheus-$KubePrometheusVersion/manifests/setup
