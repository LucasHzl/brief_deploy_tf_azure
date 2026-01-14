.PHONY: help install docker-up docker-down docker-logs setup-local pipeline-1 pipeline-2 pipeline-3 pipeline-all clean

# Couleurs pour le terminal
GREEN  := \033[0;32m
YELLOW := \033[0;33m
NC     := \033[0m # No Color

help: ## Affiche l'aide
	@echo "$(GREEN)🚕 NYC Taxi Pipeline - Commandes disponibles$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

install: ## Installer les dépendances avec UV
	@echo "$(GREEN)📦 Installation des dépendances...$(NC)"
	uv sync

docker-up: ## Démarrer les services Docker (PostgreSQL + Azurite)
	@echo "$(GREEN)🐳 Démarrage de Docker Compose...$(NC)"
	docker-compose up -d
	@echo "$(GREEN)✅ Services démarrés !$(NC)"
	@echo ""
	@echo "Services disponibles :"
	@echo "  - PostgreSQL : localhost:5432"
	@echo "  - Azurite    : localhost:10000"
	@echo "  - pgAdmin    : http://localhost:8080"

docker-down: ## Arrêter les services Docker
	@echo "$(YELLOW)🛑 Arrêt de Docker Compose...$(NC)"
	docker-compose down

docker-logs: ## Afficher les logs Docker
	docker-compose logs -f

docker-clean: ## Arrêter et supprimer tous les volumes Docker (⚠️ supprime les données)
	@echo "$(YELLOW)⚠️  ATTENTION : Cette commande va supprimer toutes les données !$(NC)"
	@read -p "Êtes-vous sûr ? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose down -v; \
		echo "$(GREEN)✅ Volumes supprimés$(NC)"; \
	else \
		echo "$(YELLOW)❌ Annulé$(NC)"; \
	fi

setup-local: ## Configurer l'environnement local (copier .env.local vers .env)
	@echo "$(GREEN)⚙️  Configuration de l'environnement local...$(NC)"
	@if [ ! -f .env ]; then \
		cp .env.local .env; \
		echo "$(GREEN)✅ Fichier .env créé depuis .env.local$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  Le fichier .env existe déjà (non écrasé)$(NC)"; \
	fi

pipeline-1: ## Exécuter Pipeline 1 (Téléchargement)
	@echo "$(GREEN)🚀 Exécution de la Pipeline 1 : Téléchargement$(NC)"
	uv run python pipeline_1_download.py

pipeline-2: ## Exécuter Pipeline 2 (Chargement et nettoyage)
	@echo "$(GREEN)🚀 Exécution de la Pipeline 2 : Chargement$(NC)"
	uv run python pipeline_2_load_to_postgres.py

pipeline-3: ## Exécuter Pipeline 3 (Transformation DIM/FACT)
	@echo "$(GREEN)🚀 Exécution de la Pipeline 3 : Transformation$(NC)"
	uv run python pipeline_3_transform.py

pipeline-all: pipeline-1 pipeline-2 pipeline-3 ## Exécuter toutes les pipelines
	@echo ""
	@echo "$(GREEN)✅ Toutes les pipelines ont été exécutées avec succès !$(NC)"

clean: ## Nettoyer les fichiers générés (data/, logs, cache)
	@echo "$(YELLOW)🧹 Nettoyage des fichiers générés...$(NC)"
	rm -rf data/
	rm -rf .dlt/
	rm -rf __pycache__/
	rm -rf *.log
	@echo "$(GREEN)✅ Nettoyage terminé$(NC)"

test-local: docker-up setup-local ## Setup complet pour tests locaux
	@echo ""
	@echo "$(GREEN)✅ Environnement local prêt !$(NC)"
	@echo ""
	@echo "Prochaines étapes :"
	@echo "  1. Vérifier que Docker est lancé : $(YELLOW)docker-compose ps$(NC)"
	@echo "  2. Exécuter les pipelines : $(YELLOW)make pipeline-all$(NC)"
	@echo "  3. Accéder à pgAdmin : $(YELLOW)http://localhost:8080$(NC)"
	@echo ""
