# 🚕 Pipeline NYC Taxi - Déploiement Azure avec Terraform

Infrastructure as Code pour déployer un pipeline de données NYC Taxi sur Azure.

## 📋 Description

Ce projet déploie une infrastructure cloud complète sur Azure pour traiter les données des taxis de New York :
- **Infrastructure** : Provisionnée avec Terraform
- **Pipeline de données** : Application Python containerisée déployée sur Azure Container Apps
- **Stockage** : Azure Blob Storage pour les fichiers bruts
- **Base de données** : Cosmos DB for PostgreSQL (Citus)
- **Monitoring** : Log Analytics Workspace

## 🏗️ Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                      AZURE CLOUD                                │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │  ORCHESTRATION LAYER                                     │  │
│  │                                                          │  │
│  │  ┌──────────────────────────────────────────────────┐  │  │
│  │  │ Container Apps Environment                        │  │  │
│  │  │  ┌────────────────────────────────────────────┐  │  │  │
│  │  │  │  NYC Taxi Pipeline Container App          │  │  │  │
│  │  │  │  - Pipeline 1: Download                   │  │  │  │
│  │  │  │  - Pipeline 2: Load to PostgreSQL         │  │  │  │
│  │  │  │  - Pipeline 3: Transform (Star Schema)    │  │  │  │
│  │  │  └────────────────────────────────────────────┘  │  │  │
│  │  └──────────────────────────────────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────┐        ┌─────────────────────────────────┐  │
│  │   STORAGE    │        │      DATA WAREHOUSE             │  │
│  │              │        │                                 │  │
│  │  Azure Blob  │───────▶│  Cosmos DB for PostgreSQL      │  │
│  │  Storage     │        │  (Citus - Distributed)          │  │
│  │              │        │                                 │  │
│  │  - raw/      │        │  Tables:                        │  │
│  │  - processed/│        │  - staging_taxi_trips           │  │
│  └──────────────┘        │  - dim_datetime                 │  │
│                          │  - dim_location                 │  │
│  ┌──────────────┐        │  - dim_payment                  │  │
│  │   REGISTRY   │        │  - dim_vendor                   │  │
│  │              │        │  - fact_trips                   │  │
│  │  Azure       │        └─────────────────────────────────┘  │
│  │  Container   │                                              │
│  │  Registry    │        ┌─────────────────────────────────┐  │
│  │              │        │     MONITORING                  │  │
│  │  Image:      │        │                                 │  │
│  │  nyc-taxi-   │        │  Log Analytics Workspace        │  │
│  │  pipeline    │        │  - Application logs             │  │
│  └──────────────┘        │  - System metrics               │  │
│                          └─────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
```

## 🗂️ Structure du Projet

```
.
├── terraform/                      # Infrastructure as Code
│   ├── providers.tf               # Configuration Azure provider
│   ├── main.tf                    # Resource Group, randoms
│   ├── variables.tf               # Définition des variables
│   ├── terraform.tfvars          # Vos valeurs de configuration
│   ├── storage.tf                # Storage Account et containers
│   ├── container_registry.tf    # Azure Container Registry
│   ├── database.tf               # Cosmos DB for PostgreSQL
│   └── container_apps.tf         # Container Apps et environnement
│
├── pipelines/                     # Application Python (fournie)
│   ├── ingestion/                # Pipeline 1 : Download
│   ├── staging/                  # Pipeline 2 : Load
│   └── transformation/           # Pipeline 3 : Transform
│
├── utils/                        # Utilitaires (fournis)
│   ├── database.py              # Connexions PostgreSQL/DuckDB
│   ├── download_helper.py       # Helper téléchargement
│   └── parquet_utils.py         # Gestion fichiers Parquet
│
├── sql/                          # Scripts SQL (fournis)
│   ├── create_staging_table.sql
│   ├── truncate.sql
│   └── transformations.sql      # Création DIM/FACT
│
├── Dockerfile                    # Image Docker (fourni)
├── main.py                       # Point d'entrée pipeline (fourni)
└── README.md                     # Documentation
```

## 🚀 Prérequis

### Outils nécessaires

1. **Azure CLI**
   ```bash
   # Installation : https://learn.microsoft.com/cli/azure/install-azure-cli
   az --version
   az login
   ```

2. **Terraform**
   ```bash
   # Installation : https://developer.hashicorp.com/terraform/install
   terraform --version  # Minimum v1.0
   ```

3. **Docker**
   ```bash
   # Installation : https://docs.docker.com/get-docker/
   docker --version
   ```

### Compte Azure

- Compte Azure avec crédits disponibles
- Souscription active : `az account show`

## ⚙️ Configuration

### 1. Configurer les variables Terraform

Créer le fichier `terraform/terraform.tfvars` :

```hcl
# Nom du projet
project_name = "nyctaxi"

# Environnement
environment = "dev"

# Région Azure (obligatoire: francecentral)
location = "francecentral"

# Tags
tags = {
  Project     = "NYC Taxi Pipeline"
  ManagedBy   = "Terraform"
  Environment = "dev"
  Owner       = "VotreNom"
}

# Configuration des pipelines
start_date = "2025-01"  # Date de début (YYYY-MM)
end_date   = "2025-02"  # Date de fin (YYYY-MM)

# Cosmos DB
cosmos_db_admin_username = "taxiadmin"
# cosmos_db_admin_password = null  # Généré automatiquement si null

# Container Apps
container_apps_cpu         = 0.5
container_apps_memory      = "1Gi"
container_apps_min_replicas = 0
container_apps_max_replicas = 1
```

### 2. Initialiser Terraform

```bash
cd terraform
terraform init
```

### 3. Valider la configuration

```bash
terraform validate
terraform plan
```

## 📦 Déploiement

### Étape 1 : Créer l'infrastructure de base

Créer d'abord l'ACR pour pouvoir y pousser l'image Docker :

```bash
# Déployer uniquement ACR et Storage (pour commencer)
terraform apply -target=azurerm_container_registry.main -target=azurerm_storage_account.main
```

### Étape 2 : Build et Push de l'image Docker

```bash
# Récupérer le nom de l'ACR
ACR_NAME=$(terraform output -raw acr_name)
ACR_URL=$(terraform output -raw acr_login_server)

# Se connecter à ACR
az acr login --name $ACR_NAME

# Revenir à la racine du projet
cd ..

# Builder l'image Docker
docker build -t nyc-taxi-pipeline:latest .

# Tagger l'image pour ACR
docker tag nyc-taxi-pipeline:latest $ACR_URL/nyc-taxi-pipeline:latest

# Pousser vers ACR
docker push $ACR_URL/nyc-taxi-pipeline:latest

# Vérifier que l'image est bien dans ACR
az acr repository show-tags --name $ACR_NAME --repository nyc-taxi-pipeline
```

### Étape 3 : Déployer l'infrastructure complète

```bash
# Revenir dans terraform/
cd terraform

# Déployer toute l'infrastructure
terraform apply
```

**⏱️ Durée estimée** : 5-10 minutes (Cosmos DB prend du temps à provisionner)

### Étape 4 : Vérifier le déploiement

```bash
# Lister toutes les ressources créées
az resource list --resource-group rg-nyctaxi-dev --output table

# Vérifier le Container App
az containerapp list --resource-group rg-nyctaxi-dev --output table
```

## 📊 Utilisation

### Voir les logs du pipeline

```bash
# Suivre les logs en temps réel
az containerapp logs show \
  --name ca-nyctaxi-pipeline-dev \
  --resource-group rg-nyctaxi-dev \
  --follow

# Voir les derniers logs
az containerapp logs show \
  --name ca-nyctaxi-pipeline-dev \
  --resource-group rg-nyctaxi-dev \
  --tail 100
```

### Se connecter à la base de données

```bash
# Récupérer la connection string
terraform output cosmos_db_connection_string

# Se connecter avec psql (si votre IP est autorisée)
psql "postgresql://taxiadmin:PASSWORD@cosmos-nyctaxi-dev-XXXXX.postgres.cosmos.azure.com:5432/citus?sslmode=require"
```

### Requêtes SQL pour vérifier les données

```sql
-- Vérifier la table staging
SELECT COUNT(*) FROM staging_taxi_trips;

-- Vérifier les tables de dimensions
SELECT COUNT(*) FROM dim_datetime;
SELECT COUNT(*) FROM dim_location;
SELECT COUNT(*) FROM dim_payment;
SELECT COUNT(*) FROM dim_vendor;

-- Vérifier la table de faits
SELECT COUNT(*) FROM fact_trips;

-- Exemple : Revenus par jour de la semaine
SELECT
    d.jour_semaine_nom,
    COUNT(*) as nombre_courses,
    AVG(f.montant_total) as revenu_moyen
FROM fact_trips f
JOIN dim_datetime d ON f.pickup_datetime_key = d.datetime_key
GROUP BY d.jour_semaine_nom
ORDER BY nombre_courses DESC;
```

## 🔧 Troubleshooting

### Erreur : "MANIFEST_UNKNOWN: manifest tagged by 'latest' is not found"

**Cause** : L'image Docker n'a pas été poussée vers ACR avant `terraform apply`

**Solution** :
1. Builder et pusher l'image (voir Étape 2)
2. Réessayer `terraform apply`

### Erreur : Cosmos DB SKU Invalid

**Cause** : Configuration SKU incorrecte dans `database.tf`

**Solution** : Vérifier que `coordinator_server_edition = "BurstableMemoryOptimized"` pour 1 vCore

### Erreur : Container App ne démarre pas

**Vérifications** :
1. Vérifier les logs : `az containerapp logs show ...`
2. Vérifier les variables d'environnement dans le portail Azure
3. Vérifier que l'image existe dans ACR
4. Vérifier les secrets (storage, postgres, acr)

### Erreur : Connexion PostgreSQL refusée

**Vérifications** :
1. Vérifier que la firewall rule existe (autoriser services Azure)
2. Vérifier SSL mode = `require`
3. Vérifier les credentials

### L'image Docker ne se build pas

**Vérifications** :
1. Vérifier que `pyproject.toml` et `uv.lock` existent
2. Vérifier que tous les dossiers requis existent (pipelines/, utils/, sql/)
3. Essayer de builder en mode verbose : `docker build --progress=plain -t nyc-taxi-pipeline:latest .`

## 💰 Gestion des Coûts

### Estimation des coûts mensuels

| Service | Configuration | Coût estimé |
|---------|--------------|-------------|
| Storage Account | LRS, <1GB | ~0.02€/mois |
| Container Registry | Basic | ~5€/mois |
| Container Apps | 0.5 vCPU, min=0 | ~0.01€/s active |
| Cosmos DB | 1 vCore Burstable | ~50-70€/mois |
| Log Analytics | <5GB | Gratuit |

**Total** : ~60-80€/mois si actif 24/7

### Optimisation

**Destruction quotidienne** (recommandé pour environnement de dev) :
```bash
# En fin de journée
terraform destroy

# Le lendemain
terraform apply
```
→ **Économie : ~70%** (Cosmos DB facturé à l'heure)

**Alerte budget** :
1. Azure Portal → Cost Management + Billing
2. Budgets → Create
3. Définir limite (ex: 50€/mois)

## 🧹 Nettoyage

### Détruire l'infrastructure

```bash
cd terraform
terraform destroy
```

**⚠️ Attention** : Cette commande supprime TOUTES les ressources et TOUTES les données.

### Vérifier la suppression

```bash
# Vérifier qu'il ne reste rien
az resource list --resource-group rg-nyctaxi-dev

# Si le resource group existe encore, le supprimer manuellement
az group delete --name rg-nyctaxi-dev --yes
```

## 📚 Ressources

### Documentation officielle
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Container Apps](https://learn.microsoft.com/azure/container-apps/)
- [Cosmos DB for PostgreSQL](https://learn.microsoft.com/azure/cosmos-db/postgresql/)

### Tutoriels
- [Terraform avec Azure](https://learn.microsoft.com/azure/developer/terraform/)
- [Azure CLI Reference](https://learn.microsoft.com/cli/azure/)

## 📝 Notes

### Fonctionnement de l'application

L'application Python s'exécute en 3 étapes séquentielles :

1. **Pipeline 1 : Download**
   - Télécharge les fichiers Parquet depuis NYC TLC
   - Stocke dans Azure Blob Storage (container `raw`)

2. **Pipeline 2 : Load**
   - Lit les fichiers depuis Azure Blob Storage
   - Nettoie les données (filtres qualité)
   - Charge dans PostgreSQL (table `staging_taxi_trips`)

3. **Pipeline 3 : Transform**
   - Crée les tables de dimensions (date, location, payment, vendor)
   - Crée la table de faits (fact_trips)
   - Modèle en étoile optimisé pour l'analyse

### Tables créées

**Dimensions** :
- `dim_datetime` : dimensions temporelles
- `dim_location` : zones géographiques
- `dim_payment` : types de paiement
- `dim_vendor` : fournisseurs

**Faits** :
- `fact_trips` : métriques (montants, distances, durées, etc.)

## 🎓 Améliorations Possibles

- [ ] Backend Terraform distant (Azure Storage)
- [ ] CI/CD avec GitHub Actions
- [ ] Modules Terraform réutilisables
- [ ] Monitoring avancé (Application Insights)
- [ ] Tests d'infrastructure (Terratest)
- [ ] Secrets dans Azure Key Vault
- [ ] Multi-environnements (dev, staging, prod)

## 📄 Licence

Projet éducatif - Brief Terraform NYC Taxi Pipeline
# brief_deploy_tf_azure
