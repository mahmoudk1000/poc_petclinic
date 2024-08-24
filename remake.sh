#!/usr/bin/env bash

RESOURCE_GROUP="petclinic"
CLUSTER_NAME="petclinic-cluster-aks"

# Function to install Jenkins using Helm
install_jenkins() {
        kubectl create namespace jenkins
        helm repo add jenkins https://charts.jenkins.io
        helm repo update
        helm install jenkins jenkins/jenkins --namespace jenkins

        echo "Jenkins is installed"
        printf '%s' "$(kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode)"
}

# Function to install SonarQube using Helm
install_sonarqube() {
        kubectl create namespace sonarqube
        helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
        helm repo update
        helm install sonarqube sonarqube/sonarqube --namespace sonarqube

        echo "SonarQube is installed"
}

# Function to enable Nexus using Helm
install_nexus() {
        kubectl create namespace nexus
        helm repo add sonatype https://sonatype.github.io/helm3-charts/
        helm repo update

        kubectl label namespace nexus app.kubernetes.io/managed-by=Helm
        kubectl annotate namespace nexus meta.helm.sh/release-name=nxrm
        kubectl annotate namespace nexus meta.helm.sh/release-namespace=default

        helm install nxrm sonatype/nxrm-ha --set namespaces.nexusNs.name=nexus

        echo "Nexus is installed"
}

install_old_nexus() {
        kubectl create namespace nexus
        helm repo add sonatype https://sonatype.github.io/helm3-charts/
        helm repo update
        helm install nexus sonatype/nexus-repository-manager --namespace nexus

        echo "Nexus is installed"
}

# Function to enable approuting
enable_approuting() {
        az aks approuting enable --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
}

# Commit to get credentials
get_cred() {
        az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing
}

case $1 in
jenkins)
        install_jenkins
        ;;
sonar)
        install_sonarqube
        ;;
nexus)
        install_old_nexus
        ;;
approuting)
        enable_approuting
        ;;
cred)
        get_cred
        ;;
*)
        echo "Usage: $0 {jenkins|sonar|nexus|approuting|cred}"
        exit 1
        ;;
esac
