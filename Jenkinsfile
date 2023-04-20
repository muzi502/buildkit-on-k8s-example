def JOB_NAME = "${env.JOB_BASE_NAME}"
def BUILD_NUMBER = "${env.BUILD_NUMBER}"
def POD_NAME = "jenkins-${JOB_NAME}-${BUILD_NUMBER}"
def POD_IMAGE = params.pod_image ?: 'ghcr.io/muzi502/jenkins-agent-pod-image:726bd38e1887'
def POD_NAMESPACE = params.pod_namespace ?: 'default'
def JENKINS_CLOUD = params.jenkins_cloud ?: 'kubernetes'
def REGISTRY = params.registry ?: 'ghcr.io'
def REGISTRY_CREDENTIALS_ID = params.registry_credentials_id ?: 'muzi502-ghcr'

// Kubernetes pod template to run.
podTemplate(
    cloud: JENKINS_CLOUD,
    namespace: POD_NAMESPACE,
    name: POD_NAME,
    label: POD_NAME,
    yaml: """
apiVersion: v1
kind: Pod
metadata:
 annotations:
    kubectl.kubernetes.io/default-container: runner
spec:
  nodeSelector:
    kubernetes.io/arch: amd64
  containers:
  - name: runner
    image: ${POD_IMAGE}
    imagePullPolicy: Always
    tty: true
    volumeMounts:
    - name: buildx-config
      mountPath: /root/.docker/buildx/instances/kube
      readOnly: true
      subPath: kube
    env:
    - name: HOST_IP
      valueFrom:
        fieldRef:
          fieldPath: status.hostIP
  - name: jnlp
    args: ["\$(JENKINS_SECRET)", "\$(JENKINS_NAME)"]
    image: "docker.io/jenkins/inbound-agent:4.11.2-4-alpine"
    imagePullPolicy: IfNotPresent
  volumes:
    - name: buildx-config
      configMap:
        name: buildx.config
        items:
          - key: data
            path: kube
""",
) {
    node(POD_NAME) {
        try {
            container("runner") {
                stage("Checkout") {
                    retry(10) {
                        checkout([
                            $class: 'GitSCM',
                            branches: scm.branches,
                            doGenerateSubmoduleConfigurations: scm.doGenerateSubmoduleConfigurations,
                            extensions: [[$class: 'CloneOption', noTags: false, shallow: false, depth: 0, reference: '']],
                            userRemoteConfigs: scm.userRemoteConfigs,
                        ])
                    }
                }
                stage("Init") {
                    withCredentials([usernamePassword(credentialsId: "${REGISTRY_CREDENTIALS_ID}", passwordVariable: "REGISTRY_PASSWORD", usernameVariable: "REGISTRY_USERNAME")]) {
                        sh """
                        docker buildx install && docker buildx use kube
                        docker login ${REGISTRY} -u '${REGISTRY_USERNAME}' -p '${REGISTRY_PASSWORD}'
                        """
                    }
                }
                stage("Build Image") {
                    sh """#!/bin/bash
                    make build-image
                    """
                }
            }
        } catch (Exception e) {
            throw e
        }
    }
}
