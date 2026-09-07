# AppProjects

Um arquivo YAML por projeto. Exemplo de nome: `my-project.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: my-project
  namespace: argocd
spec:
  description: Descricao do projeto
  sourceRepos:
    - git@github.com:org/platform-gitops.git
    - git@github.com:org/my-app.git
  destinations:
    - namespace: dev
      server: https://kubernetes.default.svc
  namespaceResourceWhitelist:
    - group: "*"
      kind: "*"
```

Aplicar: `make bootstrap-projects`
