# Makefile - Platform GitOps / ArgoCD

ARGOCD_DIR := argocd
ARGOCD_NAMESPACE := argocd
ARGOCD_INSTALL_URL := https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

GITOPS_REPO_URL := git@github.com:GuAntunes/platform-gitops.git
APP_REPO_URL := git@github.com:GuAntunes/bridal-cover-crm.git
GITOPS_DEPLOY_KEY := $(HOME)/.ssh/argocd_platform_gitops
APP_DEPLOY_KEY := $(HOME)/.ssh/argocd_bridal_cover_crm

GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m

.DEFAULT_GOAL := help

.PHONY: help
help: ## Mostrar comandos disponiveis
	@echo "$(GREEN)Platform GitOps - ArgoCD$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-28s$(NC) %s\n", $$1, $$2}'

.PHONY: install
install: ## Instalar ArgoCD no cluster (manifest non-HA)
	@echo "$(GREEN)Instalando ArgoCD...$(NC)"
	kubectl create namespace $(ARGOCD_NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	kubectl apply --server-side --force-conflicts -n $(ARGOCD_NAMESPACE) -f $(ARGOCD_INSTALL_URL)
	@echo "$(YELLOW)Aguardando pods...$(NC)"
	kubectl wait --for=condition=Ready pods --all -n $(ARGOCD_NAMESPACE) --timeout=300s
	@echo "$(GREEN)ArgoCD instalado!$(NC)"
	@make status

.PHONY: status
status: ## Ver status dos pods do ArgoCD
	@kubectl get pods -n $(ARGOCD_NAMESPACE)

.PHONY: port-forward
port-forward: ## Abrir UI em https://localhost:8080
	@echo "$(GREEN)UI: https://localhost:8080$(NC)"
	@echo "$(YELLOW)Usuario: admin | Senha: make password$(NC)"
	kubectl port-forward svc/argocd-server -n $(ARGOCD_NAMESPACE) 8080:443

.PHONY: password
password: ## Exibir senha inicial do admin
	@kubectl -n $(ARGOCD_NAMESPACE) get secret argocd-initial-admin-secret \
		-o jsonpath="{.data.password}" 2>/dev/null | base64 -d; echo

.PHONY: bootstrap-project
bootstrap-project: ## Aplicar AppProject bridal-cover
	kubectl apply -f $(ARGOCD_DIR)/projects/bridal-cover.yaml
	@echo "$(GREEN)AppProject aplicado$(NC)"

.PHONY: bootstrap-root
bootstrap-root: ## Aplicar root-app (App of Apps) - executar uma vez
	kubectl apply -f $(ARGOCD_DIR)/bootstrap/root-app.yaml
	@echo "$(GREEN)root-app aplicado$(NC)"
	@echo "$(YELLOW)Sync manual: use a UI ou 'argocd app sync root-app'$(NC)"

.PHONY: validate
validate: ## Validar YAMLs sem aplicar no cluster
	kubectl apply --dry-run=client -f $(ARGOCD_DIR)/projects/
	kubectl apply --dry-run=client -R -f $(ARGOCD_DIR)/applications/
	kubectl apply --dry-run=client -f $(ARGOCD_DIR)/bootstrap/
	@echo "$(GREEN)YAMLs validos$(NC)"

.PHONY: generate-gitops-deploy-key
generate-gitops-deploy-key: ## Gerar SSH key para platform-gitops
	@test -f $(GITOPS_DEPLOY_KEY) || ssh-keygen -t ed25519 -f $(GITOPS_DEPLOY_KEY) -N "" -C "argocd-deploy-key-platform-gitops"
	@chmod 600 $(GITOPS_DEPLOY_KEY)
	@echo "$(GREEN)Chave: $(GITOPS_DEPLOY_KEY)$(NC)"
	@echo "$(YELLOW)GitHub: https://github.com/GuAntunes/platform-gitops/settings/keys$(NC)"
	@cat $(GITOPS_DEPLOY_KEY).pub

.PHONY: setup-gitops-repo-secret
setup-gitops-repo-secret: ## Registrar platform-gitops no ArgoCD
	kubectl create secret generic platform-gitops-repo -n $(ARGOCD_NAMESPACE) \
		--from-literal=url=$(GITOPS_REPO_URL) \
		--from-file=sshPrivateKey=$(GITOPS_DEPLOY_KEY) \
		--dry-run=client -o yaml | kubectl apply -f -
	kubectl label secret platform-gitops-repo -n $(ARGOCD_NAMESPACE) \
		argocd.argoproj.io/secret-type=repository --overwrite
	kubectl rollout restart deployment argocd-repo-server -n $(ARGOCD_NAMESPACE)
	@echo "$(GREEN)Secret platform-gitops aplicado$(NC)"

.PHONY: setup-app-repo-secret
setup-app-repo-secret: ## Registrar bridal-cover-crm no ArgoCD
	kubectl create secret generic bridal-cover-crm-repo -n $(ARGOCD_NAMESPACE) \
		--from-literal=url=$(APP_REPO_URL) \
		--from-file=sshPrivateKey=$(APP_DEPLOY_KEY) \
		--dry-run=client -o yaml | kubectl apply -f -
	kubectl label secret bridal-cover-crm-repo -n $(ARGOCD_NAMESPACE) \
		argocd.argoproj.io/secret-type=repository --overwrite
	kubectl rollout restart deployment argocd-repo-server -n $(ARGOCD_NAMESPACE)
	@echo "$(GREEN)Secret bridal-cover-crm aplicado$(NC)"

.PHONY: setup-repos
setup-repos: setup-gitops-repo-secret setup-app-repo-secret ## Registrar ambos repos no ArgoCD

.PHONY: verify-repos
verify-repos: ## Verificar conexao com os repositorios Git
	@kubectl port-forward svc/argocd-server -n $(ARGOCD_NAMESPACE) 8080:443 >/dev/null 2>&1 & \
		PF_PID=$$!; sleep 3; \
		ARGOCD_PASS=$$(kubectl -n $(ARGOCD_NAMESPACE) get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d); \
		argocd login localhost:8080 --username admin --password "$$ARGOCD_PASS" --insecure >/dev/null 2>&1 && \
		argocd repo list || true; \
		kill $$PF_PID 2>/dev/null || true
