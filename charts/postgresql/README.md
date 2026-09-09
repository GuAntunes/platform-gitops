# PostgreSQL (platform-postgresql)

Chart Helm com overlays por ambiente. Deltas por projeto ficam em `argocd/applications/<projeto>/<ambiente>/postgres-values.yaml`.

## Estrutura

```
charts/postgresql/
├── Chart.yaml
├── values.yaml              # defaults do chart
├── base/values.yaml           # comum a todos os ambientes
├── overlays/
│   ├── dev/values.yaml
│   ├── staging/values.yaml
│   └── prod/values.yaml
└── templates/
```

## Ordem de merge

1. `values.yaml` (chart)
2. `base/values.yaml`
3. `overlays/<ambiente>/values.yaml`
4. `argocd/applications/<projeto>/<ambiente>/postgres-values.yaml`

## Novo projeto

1. Crie `argocd/applications/<projeto>/dev/postgres-values.yaml` com deltas (database, nodePort, etc.)
2. Crie `argocd/applications/<projeto>/dev/postgres-dev.yaml` (ver `argocd/applications/README.md`)
3. Sync via ArgoCD

## DNS interno

Com `releaseName: postgres`, o host costuma ser `postgres.<namespace>.svc.cluster.local`.

Use `fullnameOverride` no `postgres-values.yaml` do projeto se precisar de um nome especifico.
