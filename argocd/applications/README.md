# Applications

Organize por projeto e ambiente. Cada deploy tem uma `Application` YAML e, opcionalmente, arquivos `*-values.yaml` na mesma pasta.

```
applications/
└── <projeto>/
    └── <ambiente>/
        ├── postgres-dev.yaml
        └── postgres-values.yaml
```

O `root-app` descobre Applications recursivamente (`directory.recurse: true`). Arquivos `*-values.yaml` **nao** sao Applications — entram em `helm.valueFiles`.

Referencia funcional: [example-project/dev/](example-project/dev/).

## PostgreSQL (chart neste repo)

**postgres-values.yaml** — deltas do projeto:

```yaml
fullnameOverride: postgres

postgresql:
  database: my_app_dev

service:
  nodePort: 30435
```

**postgres-dev.yaml** — multi-source (recomendado):

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: postgres-dev
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "0"
  labels:
    app.kubernetes.io/part-of: <projeto>
    environment: dev
spec:
  project: <projeto>
  sources:
    - repoURL: git@github.com:GuAntunes/platform-gitops.git
      targetRevision: main
      path: charts/postgresql
      helm:
        releaseName: postgres
        valueFiles:
          - $values/charts/postgresql/base/values.yaml
          - $values/charts/postgresql/overlays/dev/values.yaml
          - $values/argocd/applications/<projeto>/dev/postgres-values.yaml
    - repoURL: git@github.com:GuAntunes/platform-gitops.git
      targetRevision: main
      ref: values
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    syncOptions:
      - CreateNamespace=true
```

### Staging / prod

- Troque `overlays/dev` por `overlays/staging` ou `overlays/prod`.
- Ajuste `metadata.name`, label `environment` e `destination.namespace` (`staging` ou `production`).
- Mantenha deltas em `postgres-values.yaml` por ambiente (pastas `staging/`, `prod/`).

## Chart no repositorio da aplicacao

Segundo source com `ref: values` apontando para o repo da app:

```yaml
sources:
  - repoURL: git@github.com:GuAntunes/my-app.git
    targetRevision: main
    path: helm-chart/my-app
    helm:
      releaseName: backend
      valueFiles:
        - $values/helm-chart/my-app/base/values.yaml
        - $values/helm-chart/my-app/overlays/dev/values.yaml
        - $values/argocd/applications/<projeto>/dev/backend-values.yaml
  - repoURL: git@github.com:GuAntunes/my-app.git
    targetRevision: main
    ref: values
```

O delta `backend-values.yaml` pode ficar **neste** repo (`platform-gitops`) se o segundo `ref: values` for o `platform-gitops` apenas para o ultimo arquivo — padrao mais comum: dois refs (app repo para chart+overlays, gitops repo para deploy deltas). Documente no AppProject todos os `sourceRepos` usados.
