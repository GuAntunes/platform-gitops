# Applications

Organize por projeto e ambiente. Cada deploy pode ter Application + values do projeto na mesma pasta:

```
applications/
└── <projeto>/
    └── <ambiente>/
        ├── postgres-dev.yaml
        └── postgres-values.yaml
```

O `root-app` descobre Applications recursivamente (`directory.recurse: true`). Arquivos `*-values.yaml` nao sao Applications — sao referenciados via `valueFiles`.

## Exemplo: PostgreSQL dev

Substitua `<projeto>` pelo nome do AppProject.

**postgres-values.yaml** (deltas do projeto):

```yaml
postgresql:
  database: my_app_dev

service:
  nodePort: 30435
```

**postgres-dev.yaml**:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: postgres-dev
  namespace: argocd
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

Para staging/prod, troque `overlays/dev` por `overlays/staging` ou `overlays/prod` e o namespace de destino.
