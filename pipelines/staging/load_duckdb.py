from pathlib import Path

from dotenv import load_dotenv
from loguru import logger

from utils.database import (
    execute_sql_file_duckdb,
    execute_sql_file_postgresql,
    get_database_duckdb,
)

load_dotenv()


def charger_avec_duckdb():
    with get_database_duckdb():
        data_path = Path("data/raw")
        fichiers = list(data_path.glob("*.parquet"))

    if not fichiers:
        logger.warning("Aucun fichier trouvé")
        return

    logger.info(f"{len(fichiers)} fichiers détectés")

    try:
        glob_pattern = str(data_path / "*.parquet")
        logger.info(f"Chargement optimisé de TOUS les fichiers : {glob_pattern}")
        execute_sql_file_duckdb("sql/insert_to.sql", params={"glob_pattern": glob_pattern})
        logger.success("insert_to.sql exécuté avec succès")
    except Exception as e:
        logger.error(f"Erreur : {e}")
        raise


if __name__ == "__main__":
    logger.info("Démarrage de la Pipeline DUCKDB")
    execute_sql_file_postgresql("sql/create_staging_table.sql")
    logger.info("TRUNCATE")
    execute_sql_file_postgresql("sql/truncate.sql")
    charger_avec_duckdb()
