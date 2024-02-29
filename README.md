# helloworld-demo-python deployment poc

This repo contains a simple python webservice, and a ci/cd flow to deploy this to kubernetes via helm and argo.

## CI/CD overview

The .github folder contains a Github workflow to run CI. This flow will run linting and testing on every push to the main branch. When there is a tag pushed (indicating a release), it will build and push a docker image to a docker hub registry, render some helm charts to deploy, and push these to a manifests repo. ArgoCD monitors that manifests repo and performs actual deployment.

Due to limitations in the given Github space (e.g. no access to Github Actions settings, only single repository), some parts or this are on my own github space, all publicly accessible.

This repo: https://github.com/mhindery/helloworld-demo-python
Repo with external charts: https://github.com/mhindery/charts
Repo with manifests for argocd: https://github.com/mhindery/argo

For the docker image being pushed, a public docker hub registry was used: https://hub.docker.com/repository/docker/mhindery/demo/general

The CI/CD flow needs Github Actions secrets with credentials for the docker registry and for pushing to the argocd manifests repo.

## ArgoCD deployment explanation

*Why argo? Gitops approach, better visibility, reconciliation flow on external modifications, metrics, UI ... Better than just helm deploy fire-and-forget approach*

I made both a deployment with a helm chart being made in this repo, and one where an external helm chart is used (managed by e.g. the devops / sre / cicd team). This can be found in this repo under the `server_config/helm` folder, the latter deployment has the 'external' suffix.

The helm charts for a release will be pushed to the `argocd` repository. This will not automatically deploy the new version. It only makes them available to be deployed. In order to perform a release, the config in the `environments/poc` folder (in the argocd repo) must be updated. It is there where one chooses which apps (and which versions/releases of every app) are running in the POC environment. You can find the two deployments declared there, each having their own yaml file.

It is best practice to have a separate repo for manifests and application code, hence the approach with a separate repo.

## Setting this up yourself

The demo setup is done using microk8s, which creates a local k8s cluster on your machine.

Install microk8s according to the installation here: https://microk8s.io/#install-microk8s
Install the argocd add-on: 

```shell
microk8s enable argocd
```

Port-forward the argocd webUI and log in (the password can be obtained using a command displayed during the argocd installation)

```shell
mkctl port-forward service/argo-cd-argocd-server -n argocd 8080:443
```

https://localhost:8080/

Using the mkctl cli, create an application to bootstrap argoCD.

Create this yaml file (taken from the argocd repository mentioned above in the argo-cd folder)

```yaml
# file: environment_poc.yaml
# App of apps root per environment
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: environment-poc
  namespace: argocd
spec:
  destination:
    namespace: argocd
    server: https://kubernetes.default.svc
  project: default
  source:
    path: environments/poc
    repoURL: "https://github.com/mhindery/argo.git"
    targetRevision: HEAD
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

Create this resource:

```shell
mkctl create -f environment_poc.yaml -n argocd
```

You should now see the application in the ArgoCD ui. Refresh/Sync and the application will be getting deployed.

You can see the new services having been created:

```shell
mhindery@MacBook-Pro-van-Mathieu ~ % mkctl get services --all-namespaces
NAMESPACE            NAME                                              TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                  AGE
default              kubernetes                                        ClusterIP   10.152.183.1     <none>        443/TCP                  2d20h
kube-system          kube-dns                                          ClusterIP   10.152.183.10    <none>        53/UDP,53/TCP,9153/TCP   2d20h
container-registry   registry                                          NodePort    10.152.183.33    <none>        5000:32000/TCP           2d20h
argocd               argo-cd-argocd-redis                              ClusterIP   10.152.183.212   <none>        6379/TCP                 2d20h
argocd               argo-cd-argocd-applicationset-controller          ClusterIP   10.152.183.225   <none>        7000/TCP                 2d20h
argocd               argo-cd-argocd-server                             ClusterIP   10.152.183.71    <none>        80/TCP,443/TCP           2d20h
argocd               argo-cd-argocd-dex-server                         ClusterIP   10.152.183.107   <none>        5556/TCP,5557/TCP        2d20h
argocd               argo-cd-argocd-repo-server                        ClusterIP   10.152.183.82    <none>        8081/TCP                 2d20h
poc                  helloworld-demo-python                            ClusterIP   10.152.183.95    <none>        80/TCP                   19h
poc                  helloworld-demo-python-external-cp-microservice   ClusterIP   10.152.183.238   <none>        80/TCP                   9s
mhindery@MacBook-Pro-van-Mathieu ~ % 
```

Port-forward the service to a local port and you can access the app.

```shell
mkctl port-forward service/helloworld-demo-python -n poc 9000:80
```

http://localhost:9000
