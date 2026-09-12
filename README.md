# Platform GitOps

Repositorio generico de GitOps com Argo CD: charts compartilhados (Helm com overlays) e manifestos Argo CD versionados no Git.

## O que cada parte faz

| Parte | Funcao |
|-------|--------|
| `make install` | Instala o **software** Argo CD no cluster (manifest oficial) |
| `argocd/` | **Configuracao GitOps** — AppProjects e Applications que o Argo CD aplica apos o bootstrap |
| `charts/` | Charts Helm de plataforma (ex.: PostgreSQL); charts de aplicacao ficam nos repos dos microservicos |

```text
make install → setup-repo-secret → bootstrap-projects → bootstrap-root
       → sync root-app → sync Applications → workloads no cluster
```

## Estrutura

```
platform-gitops/
├── Makefile
├── charts/
│   ├── _template/              # scaffold para novo chart (make new-chart NAME=foo)
│   └── postgresql/
│       ├── values.yaml         # fallback helm local
│       ├── base/values.yaml
│       ├── overlays/           # dev, staging, prod (so deltas)
│       └── templates/
└── argocd/
    ├── bootstrap/root-app.yaml # App of Apps (aplicar 1x)
    ├── projects/               # AppProject por produto
    └── applications/
        └── <projeto>/<ambiente>/
            ├── postgres-dev.yaml
            └── postgres-values.yaml
```

## Namespaces por ambiente

| Ambiente | Namespace Kubernetes |
|----------|----------------------|
| dev | `dev` |
| staging | `staging` |
| prod | `production` |

## Merge de values Helm (ordem)

1. `charts/<chart>/values.yaml` — defaults (`helm template .` local)
2. `charts/<chart>/base/values.yaml` — comum a todos os ambientes
3. `charts/<chart>/overlays/<env>/values.yaml` — delta do ambiente
4. `argocd/applications/<projeto>/<env>/*-values.yaml` — delta do projeto (DB, nodePort, `fullnameOverride`, tags de imagem)

No Argo CD use **multi-source** com `ref: values` e paths `$values/...` (ver [argocd/applications/example-project/dev/postgres-dev.yaml](argocd/applications/example-project/dev/postgres-dev.yaml)).

## Comandos

```bash
make help
make validate
make helm-template-postgres ENV=dev PROJECT=example-project
make new-chart NAME=my-service          # copia charts/_template
make install                            # Argo CD no cluster
make generate-deploy-key
make setup-repo-secret
make bootstrap-projects
make bootstrap-root
make port-forward                       # UI https://localhost:8081
```

## Novo projeto (checklist)

1. Copiar [argocd/projects/example-project.yaml](argocd/projects/example-project.yaml) → `argocd/projects/<projeto>.yaml` (ajustar `sourceRepos` e nomes).
2. Copiar [argocd/applications/example-project/](argocd/applications/example-project/) → `argocd/applications/<projeto>/` e ajustar labels, `project`, deltas em `*-values.yaml`.
3. Deploy key deste repo no GitHub + `make setup-repo-secret` (e keys para repos de app listados no AppProject).
4. `make bootstrap-projects && make bootstrap-root`
5. Sync manual na UI: `root-app` → apps do projeto (sync manual por padrao; evite auto-sync em prod).

## Chart em outro repositorio

Mantenha overlays no repo da aplicacao e deltas de deploy em `argocd/applications/<projeto>/<env>/`. No `Application`, use dois sources: chart no repo da app + `ref: values` no mesmo repo (ou neste repo apenas para o delta). Detalhes em [argocd/applications/README.md](argocd/applications/README.md).

## Convencoes

- Sync manual por padrao
- Applications: `<componente>-<env>` (ex.: `postgres-dev`)
- Arquivos `*-values.yaml` nao sao Applications — so entram em `helm.valueFiles`
- Labels: `app.kubernetes.io/part-of: <projeto>`, `environment: dev|staging|prod`
