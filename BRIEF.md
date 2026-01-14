# Brief : Déploiement d'une Infrastructure Data Engineering sur Azure

## 📋 Informations Générales

**Durée estimée** : 2-3 jours
**Niveau** : Intermédiaire
**Type** : Projet individuel
**Technologies** : Terraform, Azure, Docker
**Livrable** : Repository GitHub + README.md

---

## 🎯 Contexte du Projet

Vous êtes Data Engineer dans une startup de mobilité urbaine. Votre mission est de mettre en place une infrastructure cloud permettant d'analyser les données historiques des taxis de New York.

L'équipe data science a besoin d'accéder à ces données dans un entrepôt de données (data warehouse) pour construire des modèles prédictifs de demande de taxis.

Votre responsabilité est de construire un pipeline de données automatisé et une infrastructure reproductible en utilisant l'approche **Infrastructure as Code** avec Terraform.

### Dataset Utilisé

Les données sont disponibles publiquement via le NYC Taxi & Limousine Commission :
- **Format** : Parquet (colonnes)
- **Taille** : ~2-4 millions de trajets par mois
- **URL Pattern** : `https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_YYYY-MM.parquet`
- **Documentation** : [NYC TLC Trip Record Data](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)

---

## 🎓 Objectifs Pédagogiques

### Compétences Techniques

À l'issue de ce brief, vous serez capable de :

1. **Infrastructure as Code**
   - Concevoir une architecture cloud avec Terraform
   - Gérer le cycle de vie des ressources cloud
   - Utiliser les variables, outputs et modules Terraform
   - Gérer le state Terraform

2. **Services Cloud Azure**
   - Déployer et configurer Azure Storage (Blob)
   - Déployer Azure Container Registry
   - Configurer Azure Container Apps pour l'orchestration
   - Provisionner Cosmos DB for PostgreSQL
   - Mettre en place Log Analytics pour le monitoring

3. **Containerisation**
   - Construire des images Docker optimisées (multi-stage)
   - Gérer un registry privé de containers
   - Configurer des variables d'environnement et secrets
   - Optimiser la taille et les layers d'images

4. **Data Engineering**
   - Ingérer des données depuis une source externe
   - Transformer des données avec DuckDB
   - Modéliser un schéma en étoile (star schema)
   - Optimiser les chargements de données

5. **DevOps & Monitoring**
   - Gérer les logs applicatifs
   - Debugger des containers en production
   - Optimiser les coûts cloud

### Compétences Transversales

- Lecture de documentation technique
- Résolution de problèmes techniques (debugging)
- Gestion de projet (organisation, planning)
- Rédaction de documentation technique

---

## 📐 Architecture Attendue

Votre infrastructure doit implémenter l'architecture suivante :

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

---

## 🔧 Spécifications Techniques

### 1. Infrastructure Terraform

#### Resource Group
- **Nom** : `rg-{project_name}-{environment}`
- **Région** : Au choix (ex: `francecentral`, `westeurope`)

#### Storage Account
- **Type** : General Purpose v2
- **Réplication** : LRS (Locally Redundant Storage)
- **Containers** :
  - `raw` : stockage des fichiers Parquet bruts
  - `processed` : stockage des fichiers transformés (optionnel)
- **⚠️ Contrainte** : Le nom doit être globalement unique

#### Container Registry
- **SKU** : Basic (suffisant pour le dev/test)
- **Admin** : Activé pour permettre l'authentification
- **Image à stocker** : `nyc-taxi-pipeline:latest`

#### Cosmos DB for PostgreSQL
- **Edition** : `BurstableMemoryOptimized` (pour 1 vCore)
- **vCores** : 1 (minimum)
- **Stockage** : 32 GB (32768 MB)
- **Nodes** : 0 (single-node cluster)
- **Firewall** :
  - Autoriser les services Azure (0.0.0.0)
  - Optionnel : votre IP publique pour tests
- **SSL** : Requis (`sslmode=require`)

#### Log Analytics Workspace
- **SKU** : PerGB2018
- **Rétention** : 30 jours

#### Container Apps Environment
- **Lié à** : Log Analytics Workspace

#### Container App
- **Nom** : `ca-{project_name}-pipeline-{environment}`
- **Image** : `{acr_name}.azurecr.io/nyc-taxi-pipeline:latest`
- **Ressources** :
  - CPU : 0.5 core
  - Mémoire : 1 Gi
- **Scaling** :
  - Min replicas : 0 (comportement job-like)
  - Max replicas : 1
- **Variables d'environnement** : (voir section dédiée)
- **Secrets** : Storage connection string, PostgreSQL password, ACR password

### 2. Application Python (Fournie)

**⚠️ Important** : L'application Python est **fournie dans le repository de départ**. Vous n'avez **pas à la modifier**.

Votre rôle est de :
1. Comprendre son fonctionnement
2. La containeriser avec Docker
3. La déployer via Terraform

#### Fonctionnement de l'Application

L'application exécute 3 pipelines séquentiels :

**Pipeline 1 : Download**
- Télécharge les fichiers Parquet depuis NYC TLC
- Stocke dans Azure Blob Storage (container `raw`)
- Utilise les variables `START_DATE` et `END_DATE`

**Pipeline 2 : Load**
- Lit les fichiers Parquet depuis Azure Blob Storage
- Charge dans PostgreSQL via DuckDB
- Applique des filtres de qualité

**Pipeline 3 : Transform**
- Crée un modèle en étoile (star schema)
- Tables de dimensions et de faits

#### Variables d'Environnement à Configurer

```
# Azure Storage
AZURE_STORAGE_CONNECTION_STRING  (secret)
AZURE_CONTAINER_NAME             (raw)

# PostgreSQL
POSTGRES_HOST                    (from Cosmos DB)
POSTGRES_PORT                    (5432)
POSTGRES_DB                      (citus)
POSTGRES_USER                    (variable)
POSTGRES_PASSWORD                (secret)
POSTGRES_SSL_MODE                (require)

# Pipeline Config
START_DATE                       (YYYY-MM)
END_DATE                         (YYYY-MM)
```

### 3. Containerisation Docker (Fournie)

**⚠️ Important** : Le `Dockerfile` est **fourni dans le repository de départ**.

Votre rôle est de :
1. **Comprendre** le Dockerfile multi-stage
2. **Builder** l'image Docker localement
3. **Pousser** l'image vers Azure Container Registry
4. **Configurer** Terraform pour utiliser cette image

#### Commandes à exécuter

```bash
# 1. Se connecter à ACR
az acr login --name <votre-acr-name>

# 2. Builder l'image
docker build -t nyc-taxi-pipeline:latest .

# 3. Tagger l'image
docker tag nyc-taxi-pipeline:latest <acr-url>/nyc-taxi-pipeline:latest

# 4. Pousser vers ACR
docker push <acr-url>/nyc-taxi-pipeline:latest
```

**⚠️ L'image doit être poussée vers ACR AVANT d'exécuter `terraform apply`**

---

## 📦 Livrables

**À rendre** : Un repository GitHub public ou privé contenant :

### 1. Code Terraform (60%)

**Contenu attendu** :
- Tous les fichiers `.tf` organisés et commentés
- Fichier `terraform.tfvars.example` (sans vos secrets)
- Fichier `.gitignore` configuré (exclure `.tfstate`, secrets, etc.)
- Architecture reproductible (`terraform destroy` puis `terraform apply`)

**Critères d'évaluation** :
- ✅ Structure du code (organisation en fichiers logiques)
- ✅ Variables correctement définies et utilisées
- ✅ Outputs pertinents (URLs, noms de ressources)
- ✅ Gestion des dépendances entre ressources
- ✅ Commentaires expliquant les choix techniques
- ✅ Respect des bonnes pratiques Terraform
- ✅ Utilisation de `random_string` pour l'unicité des noms

### 2. Documentation - README.md (30%)

**Contenu attendu** :
- **Description** : Objectif du projet et architecture déployée
- **Prérequis** : Outils nécessaires (Azure CLI, Terraform, Docker)
- **Configuration** :
  - Comment configurer `terraform.tfvars`
  - Quelles variables sont requises
- **Déploiement** :
  - Commandes étape par étape pour déployer
  - Build et push de l'image Docker vers ACR
  - Vérification du déploiement
- **Utilisation** :
  - Comment voir les logs du Container App
  - Comment se connecter à PostgreSQL
- **Troubleshooting** :
  - Erreurs rencontrées et solutions
  - Points d'attention spécifiques
- **Nettoyage** : Commande pour détruire l'infrastructure

**Critères d'évaluation** :
- ✅ Clarté et complétude des instructions
- ✅ Reproductibilité (quelqu'un d'autre peut déployer)
- ✅ Qualité rédactionnelle (français, structure)
- ✅ Captures d'écran pertinentes
- ✅ Section troubleshooting documentant les erreurs rencontrées

### 3. Bonus (+10%) : Démonstration

**Attendu** :
- Vidéo Loom/Screen recording (5-10 min) montrant :
  - Exécution de `terraform plan`
  - Déploiement réussi avec `terraform apply`
  - Logs de l'exécution du pipeline dans Container Apps
  - Requête SQL montrant les données dans PostgreSQL
  - Explication de l'architecture déployée

---

## 📅 Planning Suggéré

### Jour 1 : Setup et Terraform
- ✅ Installer tous les outils (Azure CLI, Terraform, Docker)
- ✅ Étudier la documentation Terraform et Azure
- ✅ Forker/cloner le repository de départ
- ✅ Initialiser le projet Terraform (`terraform init`)
- ✅ Créer les fichiers `.tf` pour toutes les ressources
- ✅ Configurer les variables dans `terraform.tfvars`
- ✅ Tester `terraform plan` et résoudre les erreurs de syntaxe

### Jour 2 : Build et Déploiement
- ✅ Builder l'image Docker localement
- ✅ Tester le Terraform pour créer l'ACR
- ✅ Pousser l'image vers ACR
- ✅ Exécuter `terraform apply` (infrastructure complète)
- ✅ Vérifier l'exécution dans Container Apps
- ✅ Analyser les logs avec Azure CLI

### Jour 3 : Documentation et Finition
- ✅ Rédiger le README.md complet
- ✅ Ajouter des captures d'écran
- ✅ Documenter les erreurs rencontrées et solutions
- ✅ Vérifier la reproductibilité (`terraform destroy` + `terraform apply`)
- ✅ Nettoyer le code et ajouter des commentaires
- ✅ Préparer le repository GitHub (bonus: vidéo démo)


---

## 🎯 Critères d'Évaluation

| Critère | Excellent (90-100%) | Satisfaisant (70-89%) | À améliorer (<70%) |
|---------|-------------------|---------------------|-------------------|
| **Infrastructure Terraform (60%)** | Infrastructure complète, bien structurée, variables utilisées correctement, outputs pertinents, commentaires clairs | Infrastructure fonctionnelle, quelques hardcoded values, commentaires basiques | Infrastructure incomplète ou non reproductible, pas de variables |
| **Documentation README (30%)** | README complet avec toutes les sections, captures d'écran, troubleshooting détaillé, reproductible | README présent avec instructions de base, manque quelques détails | Documentation minimale ou absente, pas reproductible |
| **Autonomie (10%)** | Recherche proactive, résolution autonome des blocages, documentation des erreurs | Quelques questions mais débrouillardise globale | Dépendance excessive au formateur |

---

## 📚 Ressources Recommandées

### Documentation Officielle

**Terraform**
- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

**Azure**
- [Azure Documentation](https://learn.microsoft.com/en-us/azure/)
- [Container Apps Documentation](https://learn.microsoft.com/en-us/azure/container-apps/)
- [Cosmos DB for PostgreSQL](https://learn.microsoft.com/en-us/azure/cosmos-db/postgresql/)
- [Azure Storage Documentation](https://learn.microsoft.com/en-us/azure/storage/)

**Python & Libraries**
- [DuckDB Documentation](https://duckdb.org/docs/)
- [psycopg2 Documentation](https://www.psycopg.org/docs/)
- [Azure SDK for Python](https://learn.microsoft.com/en-us/azure/developer/python/)

**Docker**
- [Docker Documentation](https://docs.docker.com/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)

### Tutoriels Vidéo

**Terraform**
- [Terraform Course - Automate Infrastructure](https://www.youtube.com/watch?v=7xngnjfIlK4) - freeCodeCamp
- [Terraform explained in 15 mins](https://www.youtube.com/watch?v=l5k1ai_GBDE) - TechWorld with Nana
- [Terraform with Azure Tutorial](https://www.youtube.com/results?search_query=terraform+azure+tutorial+2024)

**Azure Services**
- [Azure Full Course](https://www.youtube.com/watch?v=NKEFWyqJ5XA) - freeCodeCamp
- [Azure Container Apps Tutorial](https://www.youtube.com/results?search_query=azure+container+apps+tutorial)
- [Azure Cosmos DB for PostgreSQL](https://www.youtube.com/results?search_query=azure+cosmos+db+postgresql)

**Docker**
- [Docker Tutorial for Beginners](https://www.youtube.com/watch?v=pTFZFxd4hOI) - Programming with Mosh
- [Docker Deep Dive](https://www.youtube.com/watch?v=3c-iBn73dDE) - TechWorld with Nana

**Data Engineering**
- [DuckDB Tutorial](https://www.youtube.com/results?search_query=duckdb+tutorial)
- [Star Schema Explained](https://www.youtube.com/results?search_query=star+schema+data+warehouse)

### Articles et Blogs

**Terraform**
- [Medium - Terraform Best Practices](https://medium.com/search?q=terraform+best+practices)
- [HashiCorp Blog](https://www.hashicorp.com/blog)

**Azure**
- [Azure Blog](https://azure.microsoft.com/en-us/blog/)
- [Azure Tips and Tricks](https://microsoft.github.io/AzureTipsAndTricks/)

**Data Engineering**
- [Locally Optimistic Blog](https://locallyoptimistic.com/)
- [Data Engineering Weekly](https://www.dataengineeringweekly.com/)

---

## ⚠️ Points d'Attention

### Erreurs Fréquentes

1. **Cosmos DB SKU**
   - ❌ Utiliser GeneralPurpose avec 1 vCore → Erreur
   - ✅ Utiliser BurstableMemoryOptimized avec 1 vCore

2. **Image Docker absente**
   - ❌ Lancer terraform apply sans avoir push l'image → Erreur
   - ✅ Build → Tag → Push → Terraform apply

3. **Storage Account Name**
   - ❌ Nom hardcodé → Conflit si déjà pris
   - ✅ Utiliser random_string pour garantir unicité

4. **Secrets en clair**
   - ❌ Mettre les passwords dans les variables d'environnement standard
   - ✅ Utiliser le bloc `secret` dans Container App

5. **Firewall PostgreSQL**
   - ❌ Oublier la firewall rule → Connection refused
   - ✅ Créer la règle pour autoriser les services Azure

### Conseils de Débogage

**Logs Container Apps**
```bash
# Suivre les logs en temps réel
az containerapp logs show --name <nom> --resource-group <rg> --follow

# Voir les révisions
az containerapp revision list --name <nom> --resource-group <rg>
```

**Vérifier les ressources créées**
```bash
# Lister toutes les ressources du Resource Group
az resource list --resource-group <rg> --output table

# Vérifier l'image dans ACR
az acr repository list --name <acr-name>
az acr repository show-tags --name <acr-name> --repository <image-name>
```

**Tester la connexion PostgreSQL**
```bash
# Depuis votre machine (si IP autorisée)
psql "postgresql://username:password@hostname:5432/citus?sslmode=require"
```

---

## 💰 Gestion du Budget Azure

### Estimation des Coûts

Pour une utilisation de développement/test (quelques heures par jour) :

| Service | Configuration | Coût estimé |
|---------|--------------|-------------|
| Storage Account | LRS, <1GB | ~0.02€/mois |
| Container Registry | Basic | ~5€/mois |
| Container Apps | 0.5 vCPU, min=0 | ~0.01€/seconde active |
| Cosmos DB | 1 vCore Burstable | ~50-70€/mois |
| Log Analytics | <5GB/mois | Gratuit (tier gratuit) |

**💡 Total estimé : ~60-80€/mois** si infrastructure active 24/7

### Optimisation des Coûts

**Stratégies recommandées** :

1. **Destruction quotidienne**
   ```bash
   # En fin de journée
   terraform destroy

   # Le lendemain
   terraform apply
   ```
   → **Économie** : ~70% (Cosmos DB facturé à l'heure)

2. **Min Replicas à 0**
   - Container Apps ne coûte rien quand inactif
   - Se démarre automatiquement si nécessaire

3. **Nettoyage du Storage**
   - Supprimer les fichiers Parquet après transformation
   - Utiliser lifecycle policies

**⚠️ Alerte Budget**

Configurez une alerte budget dans Azure Portal :
1. Cost Management + Billing
2. Budgets → Create
3. Définir limite (ex: 50€)
4. Configurer email d'alerte

📖 [Tutoriel : Create and manage budgets](https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-acm-create-budgets)

---

## 🚀 Pour Aller Plus Loin (Optionnel)

### Améliorations Possibles

1. **CI/CD avec GitHub Actions**
   - Automatiser le build et push de l'image Docker
   - Automatiser le déploiement Terraform
   - 📖 [GitHub Actions pour Azure](https://learn.microsoft.com/en-us/azure/developer/github/github-actions)

2. **Backend Terraform Distant**
   - Stocker le state dans Azure Storage
   - Activer le locking pour travail en équipe
   - 📖 [Terraform Backend Configuration](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm)

3. **Modules Terraform**
   - Créer des modules réutilisables
   - Versionner vos modules
   - 📖 [Terraform Modules](https://developer.hashicorp.com/terraform/language/modules)

4. **Monitoring Avancé**
   - Créer des dashboards dans Log Analytics
   - Configurer des alertes sur les erreurs
   - Mettre en place Application Insights
   - 📖 [Azure Monitor](https://learn.microsoft.com/en-us/azure/azure-monitor/)

5. **Tests**
   - Tests unitaires Python avec pytest
   - Validation Terraform avec `terraform validate` et `tflint`
   - Tests d'intégration du pipeline

6. **Sécurité**
   - Utiliser Azure Key Vault pour les secrets
   - Rotation automatique des credentials
   - Scan de vulnérabilités Docker
   - 📖 [Azure Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/)

7. **Optimisation Performance**
   - Parallélisation du download des fichiers
   - Partitioning PostgreSQL
   - Indices optimisés pour les requêtes

---

## ❓ FAQ

**Q: Dois-je créer un compte Azure spécifique ?**
R: Non, votre compte Azure personnel ou étudiant suffit. Vérifiez vos crédits disponibles.

**Q: Puis-je utiliser une autre région qu'France Central ?**
R: Non, utilisez obligatoirement `francecentral` pour ce brief. 

**Q: Combien de temps prend le déploiement Terraform ?**
R: Première fois : 5-10 minutes (Cosmos DB est long à provisionner). Redéploiements : 1-3 minutes.

**Q: Mon terraform apply échoue, que faire ?**
R:
1. Lire attentivement le message d'erreur
2. Vérifier la documentation de la ressource concernée
3. Vérifier les quotas de votre souscription Azure
4. Demander de l'aide en fournissant l'erreur complète

**Q: Comment débugger mon Container App qui ne démarre pas ?**
R: Consulter les logs via `az containerapp logs show` ou le portail Azure. Vérifier les variables d'environnement et secrets.

**Q: Puis-je utiliser PostgreSQL standard au lieu de Cosmos DB ?**
R: Non, utilisez obligatoirement Cosmos DB for PostgreSQL comme spécifié dans le brief.

**Q: Combien de données dois-je charger ?**
R: Minimum : 1-2 mois. Recommandé : 3-6 mois. Maximum : 12 mois (attention au volume et temps de traitement).

---

## 📧 Support et Questions

**Ressources d'aide** :
- Documentation officielle (liens fournis)
- Stack Overflow avec tags `terraform`, `azure`, `docker`
- Azure Community Support
- Reddit : r/Terraform, r/Azure, r/dataengineering

**Lors de vos questions** :
- Fournir le message d'erreur complet
- Expliquer ce que vous avez déjà essayé
- Partager les logs pertinents
- Indiquer votre environnement (OS, versions)


**Bon courage pour ce projet ! 🚀**

Ce brief vous permettra d'acquérir des compétences essentielles en Data Engineering moderne. N'hésitez pas à expérimenter et à aller au-delà des exigences minimales.

**Remember** : L'échec fait partie de l'apprentissage. Chaque erreur est une opportunité d'apprendre. Documentez vos erreurs et solutions dans votre README !
