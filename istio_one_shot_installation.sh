#! /bin/bash
set -e
echo 'Istio installation started'

# Getting to the installation folder
cd ~/Documents

# Creating "Code" folder and "Istio_installation" folder
mkdir -p Code/Istio_installation
cd Code/Istio_installation

echo 'Installing hyperkit'
brew install hyperkit

echo 'Installing docker'
brew install docker

echo 'Installing kubectl'
brew install kubectl

echo 'Installing minikube'
brew install minikube

echo 'Setting up minikube'
minikube config set cpus 6
minikube config set memory 16384
minikube config set driver hyperkit
minikube config set container-runtime docker

# alias kubectl="minikube kubectl --" kap="kubectl apply" kget="kubectl get"

istio_version="1.13.3"

curl -L https://github.com/istio/istio/releases/download/$istio_version/istio-$istio_version-osx.tar.gz | tar -xz
cd istio-$istio_version
curl -LJO https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/main/release/kubernetes-manifests.yaml

path_to_current_dir=$(pwd)
export PATH=$PATH://$path_to_current_dir/bin

# Starting minikube and installing Istio
echo 'Starting minikube'
minikube start

echo 'Installing Istio'
istioctl install -y

echo 'Installation finished'
echo 'Setting up demo'
minikube kubectl -- get ns default --show-labels
kubectl label namespace default istio-injection=enabled
minikube kubectl -- apply -f kubernetes-manifests.yaml

echo 'Dashboards time'
minikube kubectl -- apply -f samples/addons

echo '\n Pods'
minikube kubectl -- get po -n istio-system
echo '\n Services'
minikube kubectl -- get svc -n istio-system

echo '\nPlease wait until all services are up and running and then you may open Kiali 127.0.0.1:20001 for monitoring\n'

minikube kubectl -- rollout status --watch --timeout=900s deployment kiali -n istio-system
minikube kubectl -- wait --for=condition=ready pod -l app=kiali --timeout=900s -n istio-system
echo 'Kiali Pod is ready'
minikube kubectl -- port-forward svc/kiali -n istio-system 20001
echo 'Success'
