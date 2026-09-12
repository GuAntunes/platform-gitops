# PostgreSQL (platform-postgresql)

Chart Helm compartilhado com overlays por ambiente. Deltas por produto ficam em `argocd/applications/<projeto>/<ambiente>/postgres-values.yaml`.

## Estrutura

```
charts/postgresql/
├── Chart.yaml
├── values.yaml              # fallback helm install/template local
├── base/values.yaml         # comum a todos os ambientes
├── overlays/
│   ├── dev/values.yaml
│   ├── staging/values.yaml
│   └── prod/values.yaml
└── templates/
```

## Ordem de merge

1. `values.yaml` — nao listado no Argo CD; uso local apenas
2. `base/values.yaml`
3. `overlays/<ambiente>/values.yaml`
4. `argocd/applications/<projeto>/<ambiente>/postgres-values.yaml`

Teste local com a mesma ordem:

```bash
make helm-template-postgres ENV=dev PROJECT=example-project
```

## O que vai em cada camada

| Camada | Exemplos |
|--------|----------|
| base | imagem Postgres, probes, persistence padrao, `service.type` |
| overlay env | recursos por ambiente, `service.type` ClusterIP em prod |
| delta projeto | `postgresql.database`, `service.nodePort`, `fullnameOverride: postgres` |

`nodePort` e nome de database **por projeto** evitam colisao quando varios produtos usam o mesmo cluster.

## DNS interno

Com `releaseName: postgres` e `fullnameOverride: postgres` no delta do projeto:

`postgres.<namespace>.svc.cluster.local`

## Novo projeto

1. Copie [argocd/applications/example-project/dev/postgres-values.yaml](../../argocd/applications/example-project/dev/postgres-values.yaml) para sua pasta de projeto.
2. Copie e ajuste `postgres-dev.yaml` (project, labels, paths `$values/...`).
3. Sync via Argo CD.

## Producao

O overlay `prod` usa `CHANGE_ME` para senha — substitua por External Secrets / Sealed Secrets antes de sync em cluster real.
