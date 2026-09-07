# Platform GitOps

Repositorio generico de GitOps com ArgoCD.

## Estrutura

```
platform-gitops/
├── Makefile
├── README.md
└── argocd/
    ├── bootstrap/
    │   └── root-app.yaml
    ├── projects/              # AppProjects (1 YAML por projeto)
    │   └── README.md
    └── applications/            # Applications (por projeto/ambiente)
        └── README.md
```

Convencao de pastas para applications:

```
argocd/applications/<projeto>/<ambiente>/<app>.yaml
```

## Comandos

```bash
make help
make validate
make install
make generate-deploy-key
make setup-repo-secret
make bootstrap-projects    # apos adicionar AppProjects
make bootstrap-root
make port-forward
```

## Bootstrap inicial

1. Adicionar AppProjects em `argocd/projects/`
2. Adicionar Applications em `argocd/applications/<projeto>/<ambiente>/`
3. Deploy key deste repo no GitHub + `make setup-repo-secret`
4. `make bootstrap-projects && make bootstrap-root`
5. Sync manual na UI do ArgoCD

## Convencoes

- Sync manual por padrao (sem `automated` no syncPolicy)
- Charts Helm ficam nos repos de cada aplicacao
- Este repo contem apenas configuracao ArgoCD
