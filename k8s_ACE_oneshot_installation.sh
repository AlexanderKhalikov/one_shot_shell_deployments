#!/bin/sh
echo "documentation page: https://www.ibm.com/docs/en/app-connect/containers_cd?topic=connect-installing-uninstalling-kubernetes
 prerequisits:

\tkubectl
\toperator SDK
\thelm
"

#brew install kubectl operator-sdk helm

echo "Enter your IBM Entitelment key
Obtain it from here: https://myibm.ibm.com/products-services/containerlibrary
"

read -p 'YOUR_IBM_ENTITELMENT_KEY: ' YOUR_IBM_ENTITELMENT_KEY
read -p 'Your namespace: ' MY_NAMESPACE

echo "
$YOUR_IBM_ENTITELMENT_KEY
$MY_NAMESPACE
"

echo download your KUBECONFIG file to the same directory

read -p 'Name of your kube_config file
(example: config_kube_download.config)' MY_KUBE_CONFIG

#export KUBECONFIG=MY_KUBE_CONFIG


echo "
Installing cert-manager in your Kubernetes cluster
https://www.ibm.com/docs/en/app-connect/containers_cd?topic=kubernetes-installing-cert-manager-in-your-cluster
"

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/cert-manager.yaml
echo ""
kubectl get pods --namespace cert-manager

echo "
patch your deployment with correct namespace
"

kubectl patch deployment \
  cert-manager \
  --namespace cert-manager  \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": [
  "--v=2",
  "--cluster-resource-namespace=$(POD_NAMESPACE)",
  "--leader-election-namespace=kube-system",
  "--enable-certificate-owner-ref"
]}]'


echo "
Installing the Operator Lifecycle Manager (OLM) in your Kubernetes cluster
"

operator-sdk olm install

echo "
Creating an OperatorGroup for the IBM App Connect Operator
"

kubectl create namespace $MY_NAMESPACE

echo "apiVersion: operators.coreos.com/v1
kind: OperatorGroup
 metadata:
   name: operatorgroupName
   namespace: $MY_NAMESPACE
 spec:
   targetNamespaces:
   - $MY_NAMESPACE" > appconn-operator-group.yaml

kubectl apply -f appconn-operator-group.yaml

echo "
Creating the IBM App Connect Operator catalog
"

echo "apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-appconnect-catalog
  namespace: olm
spec:
  displayName: "IBM App Connect Operator Catalog k8S"
  publisher: IBM
  sourceType: grpc
  image: icr.io/cpopen/appconnect-operator-catalog-k8s
  updateStrategy:
    registryPoll:
      interval: 45m
  grpcPodConfig:
    securityContextConfig: restricted" > appconn-catalog-source.yaml

kubectl apply -f appconn-catalog-source.yaml -n olm

echo "
Creating the IBM App Connect Operator subscription
"

echo "apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-appconnect
  namespace: $MY_NAMESPACE
spec:
  channel: v11.5
  name: ibm-appconnect
  source: ibm-appconnect-catalog
  sourceNamespace: olm" > appconn-sub.yaml

kubectl apply -f appconn-sub.yaml

