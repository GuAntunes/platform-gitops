# Platform GitOps

Repositorio generico de GitOps com ArgoCD. Orquestra deploy de multiplos projetos no Kubernetes.

## Estrutura

```
platform-gitops/
├── Makefile
├── README.md
└── argocd/
    ├── bootstrap/root-app.yaml
    ├── projects/
    │   └── bridal-cover.yaml          # AppProject por projeto
    └── applications/
        └── bridal-cover/              # projeto
            └── dev/                   # ambiente
                ├── postgres-dev.yaml
                └── backend-dev.yaml
```

## Projetos configurados

| Projeto | Applications | Charts (repo externo) |
|---------|--------------|----------------------|
| bridal-cover | postgres-dev, backend-dev | `GuAntunes/bridal-cover-crm` |

## Comandos

```bash
make help                  # Ver todos os comandos
make validate              # Validar YAMLs
make install               # Instalar ArgoCD no cluster
make generate-gitops-deploy-key   # SSH key para este repo
make setup-repos           # Registrar repos no ArgoCD (fase 2)
make bootstrap-project     # Aplicar AppProject
make bootstrap-root        # Aplicar root-app
make port-forward          # UI em https://localhost:8080
```

## Bootstrap (fase 2 — cutover no cluster)

1. Adicionar Deploy Keys no GitHub (read-only):
   - `platform-gitops`
   - `bridal-cover-crm` (repo do app)
2. `make setup-repos`
3. Deletar Applications antigas se existirem:
   ```bash
   kubectl delete application root-app postgres-dev backend-dev -n argocd
   ```
4. `make bootstrap-project && make bootstrap-root`
5. Na UI: Sync `root-app` → `postgres-dev` → `backend-dev`

## Adicionar novo projeto

1. Criar `argocd/projects/<projeto>.yaml` (AppProject)
2. Criar `argocd/applications/<projeto>/dev/*.yaml` (Applications)
3. Commit e push — `root-app` descobre via `recurse: true`

## Convencoes

- **Sync manual** por padrao (sem `automated` no syncPolicy)
- Charts Helm ficam nos repos de cada aplicacao/microservico
- Este repo contem apenas configuracao ArgoCD e (futuro) values por ambiente
