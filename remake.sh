#!/usr/bin/env bash

RESOURCE_GROUP="petclinic"
CLUSTER_NAME="petclinic-cluster-aks"

prep() {
        kubectl apply -f ./.pipeline/k8s/pv.yaml
        kubectl apply -f ./.pipeline/k8s/coredns.yaml
        kubectl -n kube-system rollout restart deployment coredns
        kubectl apply -f ./.pipeline/k8s/prep-nodes.yaml
}

# Function to install Jenkins using Helm
install_jenkins() {
        kubectl create namespace jenkins
        helm repo add jenkins https://charts.jenkins.io
        helm repo update
        if helm install jenkins jenkins/jenkins --namespace jenkins \
                --set persistence.storageClass=manual \
                --set persistence.size=5Gi; then
                echo "Jenkins is installed"
        fi

        printf '%s' "$(kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode)"
}

# Function to install SonarQube using Helm
install_sonarqube() {
        kubectl create namespace sonarqube
        helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
        helm repo update
        if helm install sonarqube sonarqube/sonarqube --namespace sonarqube \
                --set postgresql.persistence.storageClass=manual \
                --set postgresql.persistence.size=5Gi; then
                echo "SonarQube is installed"
        fi
}

# Function to enable Nexus using Helm
install_nexus() {
        kubectl create namespace nexus
        helm repo add sonatype https://sonatype.github.io/helm3-charts/
        helm repo update

        if helm upgrade --install nexus -n nexus sonatype/nexus-repository-manager -f ./.pipeline/k8s/nexus_values.yaml; then
                echo "Nexus is installed"
        fi
}

# Function to enable approuting
enable_approuting() {
        az ask approuting enable --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
}

# Commit to get credentials
get_cred() {
        az ask get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing
}

case $1 in
init)
        prep
        ;;
jenkins)
        install_jenkins
        ;;
sonar)
        install_sonarqube
        ;;
nexus)
        install_nexus
        ;;
approuting)
        enable_approuting
        ;;
cred)
        get_cred
        ;;
*)
        echo "Usage: $0 {init|jenkins|sonar|nexus|approuting|cred}"
        exit 1
        ;;
esac
