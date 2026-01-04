from __future__ import annotations

from pathlib import Path
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application + Azure ML settings loaded from environment variables."""

    # ------------------------------------------------------------------
    # Azure core
    # ------------------------------------------------------------------
    azure_subscription_id: str = Field(..., alias="AZURE_SUBSCRIPTION_ID")
    azure_resource_group: str = Field(..., alias="AZURE_RESOURCE_GROUP")
    azure_ml_workspace: str = Field(..., alias="AZURE_ML_WORKSPACE")
    azure_location: str = Field(..., alias="AZURE_LOCATION")

    # ------------------------------------------------------------------
    # Azure ML runtime
    # ------------------------------------------------------------------
    aml_compute_name: str = Field(
        default="demo-azure-ml-prod-cpu-small",
        alias="AML_COMPUTE_NAME",
    )

    aml_base_image: str = Field(
        default="mcr.microsoft.com/azureml/openmpi4.1.0-ubuntu20.04",
        alias="AML_BASE_IMAGE",
    )

    # ------------------------------------------------------------------
    # ADLS / curated outputs
    # ------------------------------------------------------------------
    adls_account_name: str = Field(..., alias="ADLS_ACCOUNT_NAME")
    adls_filesystem: str = Field(..., alias="ADLS_FILESYSTEM")

    curated_train_test_parquet_uri: str = Field(
        default="azureml://datastores/synapse_adls/paths/curated/train_test_parquet/",
        alias="CURATED_TRAIN_TEST_PARQUET_URI",
    )

    # ------------------------------------------------------------------
    # Derived paths (computed)
    # ------------------------------------------------------------------
    repo_root: Path | None = None
    src_dir: Path | None = None
    aml_dir: Path | None = None
    etl_code_dir: Path | None = None
    aml_env_dir: Path | None = None
    pandas_parquet_env_file: Path | None = None

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    def model_post_init(self, __context) -> None:
        """
        settings.py is inside src/
        → repo root is one level up
        """
        self.src_dir = Path(__file__).resolve().parent
        self.repo_root = self.src_dir.parent

        self.aml_dir = self.repo_root / "aml"
        self.etl_code_dir = self.src_dir / "etl"
        self.aml_env_dir = self.aml_dir / "environments"
        self.pandas_parquet_env_file = self.aml_env_dir / "pandas-parquet.yml"


# Singleton instance
settings = Settings()