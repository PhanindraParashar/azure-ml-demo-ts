from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # Azure Configuration
    azure_subscription_id: str = Field(..., alias="AZURE_SUBSCRIPTION_ID")
    azure_resource_group: str = Field(..., alias="AZURE_RESOURCE_GROUP")
    azure_ml_workspace: str = Field(..., alias="AZURE_ML_WORKSPACE")
    azure_location: str = Field(..., alias="AZURE_LOCATION")

    # Azure Data Lake Storage Configuration
    adls_account_name: str = Field(..., alias="ADLS_ACCOUNT_NAME")
    adls_filesystem: str = Field(..., alias="ADLS_FILESYSTEM")

    # Synapse Configuration
    synapse_sql_admin_login: str = Field(..., alias="SYNAPSE_SQL_ADMIN_LOGIN")
    synapse_sql_admin_password: str = Field(..., alias="SYNAPSE_SQL_ADMIN_PASSWORD")

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )


# Global settings instance
settings = Settings()

