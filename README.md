# azure-ml-demo-ts
End-to-end demand forecasting project on Azure using Azure ML and Terraform. Covers data prep, feature engineering, training, batch forecasting, model registry, and MLOps best practices.


## Creating Datastores and Data Assets

Before running EDA or training in Azure ML, the datasets must be uploaded to storage and registered in the workspace.

### 1. Upload data to storage

Upload the following files to the ADLS Gen2 filesystem used by Synapse and Azure ML:

```
synapse/data/
├── train_test.csv
└── holdout.csv
```

* `train_test.csv` → used for EDA and model development
* `holdout.csv` → isolated final evaluation dataset

---

### 2. Create the Azure ML Datastore

Register the ADLS Gen2 filesystem as a datastore:

```bash
az ml datastore create \
  -f aml/datastores/synapse_adls.yml \
  -g demo-azure-ml-prod-rg \
  -w demo-azure-ml-prod-ws
```

---

### 3. Register Data Assets

```bash
az ml data create \
  -f aml/data-assets/train_test.yml \
  -g demo-azure-ml-prod-rg \
  -w demo-azure-ml-prod-ws

az ml data create \
  -f aml/data-assets/holdout.yml \
  -g demo-azure-ml-prod-rg \
  -w demo-azure-ml-prod-ws
```

These commands register references to the files; no data is copied.

---

### 4. Verify

```bash
az ml datastore show -n synapse_adls -g demo-azure-ml-prod-rg -w demo-azure-ml-prod-ws

az ml data show -n train_test_csv --label latest -g demo-azure-ml-prod-rg -w demo-azure-ml-prod-ws
az ml data show -n holdout_csv    --label latest -g demo-azure-ml-prod-rg -w demo-azure-ml-prod-ws
```

---

### Notes

* Datastore = storage connection
* Data asset = versioned file reference
* Holdout data must not be used for training
