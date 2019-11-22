#!/bin/bash
KubePrometheusVersion=`cat components.txt |grep "KubePrometheus Version" |awk '{print $3}'`
kubectl delete -f file/kube-prometheus-$KubePrometheusVersion/manifests/phase2
kubectl delete -f file/kube-prometheus-$KubePrometheusVersion/manifests/phase1
