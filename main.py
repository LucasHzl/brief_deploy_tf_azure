import sys
import runpy
from loguru import logger

def main():
    try:
        logger.info("🚀 Démarrage du pipeline NYC Taxi")
        runpy.run_path("pipelines/ingestion/download.py", run_name="__main__")
        
        logger.info("📥 Étape 1: Chargement dans DuckDB...")
        runpy.run_path("pipelines/staging/load_duckdb.py", run_name="__main__")
        
        logger.info("🔄 Étape 2: Transformation des données...")
        runpy.run_path("pipelines/transformation/transform.py", run_name="__main__")
        
        logger.success("✅ Pipeline terminé avec succès")
        return 0
        
    except Exception as e:
        logger.error(f"❌ Erreur dans le pipeline : {e}")
        import traceback
        traceback.print_exc()
        return 1

if __name__ == "__main__":
    sys.exit(main())