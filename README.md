# Platform GitOps

Repositorio generico de GitOps com ArgoCD.

## Estrutura

```
platform-gitops/
├── Makefile
├── charts/
│   └── postgresql/
│       ├── values.yaml
│       ├── base/
│       ├── overlays/          # dev, staging, prod
│       └── templates/
└── argocd/
    ├── bootstrap/
    ├── projects/
    └── applications/
        └── <projeto>/<ambiente>/
            ├── postgres-dev.yaml
            └── postgres-values.yaml   # deltas do projeto
```

## Comandos

```bash
make help
make validate
make install
make generate-deploy-key
make setup-repo-secret
make bootstrap-projects
make bootstrap-root
make port-forward          # UI em https://localhost:8081
```

## Bootstrap inicial

1. AppProject em `argocd/projects/<projeto>.yaml`
2. Application + values em `argocd/applications/<projeto>/<ambiente>/`
3. Deploy key no GitHub + `make setup-repo-secret`
4. `make bootstrap-projects && make bootstrap-root`
5. Sync manual na UI do ArgoCD

## Convencoes

- Sync manual por padrao
- Charts compartilhados em `charts/`
- Charts de aplicacao nos repos de cada microservico
- Overlays de ambiente no chart; deltas de projeto junto da Application
