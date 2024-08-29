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

        helm upgrade --install nexus -n nexus sonatype/nexus-repository-manager -f n-values.yaml
        # helm upgrade --install nexus -n nexus sonatype/nexus-repository-manager \
        #         --set namespaces.nexusNs.enabled=false \
        #         --set namespaces.nexusNs.name=nexus \
        #         --set statefulset.replicaCount=1 \
        #         --set statefulset.container.resources.requests.cpu=1 \
        #         --set statefulset.container.resources.requests.memory=1Gi \
        #         --set statefulset.container.resources.limits.cpu=1 \
        #         --set statefulset.container.resources.limits.memory=1Gi \-set statefulset.container.resources.limits.memory=1Gi \
        #         --set service.nexus.enabled=true \
        #         --set service.nexus.type=ClusterIP \
        #         --set secret.enabled=true \
        #         --set secret.data=nexus-tls \
        #         --set ingress.enabled=true \
        #         --set ingress.defaultRule=true \
        #         --set ingress.ingressClassName=webapprouting.kubernetes.azure.com \
        #         --set ingress.hostRepo=nexus.labbi.lab \
        #         --set ingress.tls=true \
        #         --set ingress.tls.secretName=nexus-tls \
        #         --set ingress.tls.hosts=nexus.labbi.lab,registry.labbi.lab \
        #         --set imagePullSecrets="name: regcred" \
        #         --set nexus.docker.enabled=true \
        #         --set nexus.docker.registries[0].ingressClassName=webapprouting.kubernetes.azure.com \
        #         --set nexus.docker.registries[0].host=registry.labbi.lab \
        #         --set nexus.docker.registries[0].port=5000

        echo "Nexus is installed"
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
        echo "Usage: $0 {jenkins|sonar|nexus|approuting|cred}"
        exit 1
        ;;
esac
