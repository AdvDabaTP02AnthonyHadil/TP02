# DBLP to Neo4j Import

## Overview
This project loads the DBLP v14 dataset into Neo4j, producing:

- `Article` nodes (`_id`, `title`)
- `Author` nodes (`_id`, `name`)
- `AUTHORED` relationships (Author → Article)
- `CITES` relationships (Article → Article)

All import steps are driven by `import_all.sh`, which converts raw JSON to TSVs and then bulk‐loads via `import_flat.cypher`.

---

## Repository Layout

```
import/
├── Dockerfile
├── import_all.sh
├── to_tsvs_from_json.py
├── requirements.txt
├── import_flat.cypher
├── metrics_queries.cql
├── .env.example
├── performance.json      # manually compiled summary
├── README.md             # this file
└── k8s/                  # optional Kubernetes manifests
    ├── configmap.yaml
    ├── secret.yaml
    ├── import-job.yaml
    ├── pvc.yaml
    └── pvc-filler.yaml  
```

Large data files (`*.json`, `*.tsv`, `*.csv`) and temporary files are excluded via `.gitignore`.

---

## Prerequisites

- Docker (with at least 3 GB allocated to containers)  
- Neo4j 5.x authentication credentials (`neo4j/testtest`)  
- Place `dblpv14.json` (raw DBLP data) alongside this `import` directory, NOT committed to Git.

---

## Local Import Steps

### 1. Build the importer image
```powershell
cd import
docker build -t advdaba_import:latest .
```

### 2. Start Neo4j
```powershell
# Stop any existing server
docker stop neo4j-server 2>$null

# Launch with import volume mounted
docker run -d --rm --name neo4j-server \
  --memory=3g \
  --network advdaba_net \
  -p7474:7474 -p7687:7687 \
  -v "$PWD":/var/lib/neo4j/import:rw \
  -e NEO4J_AUTH=neo4j/testtest \
  neo4j:latest


# Wait ~15s for Bolt to come up
Start-Sleep -Seconds 15
```

### 3. Run importer (100 000 records - if you would like to run it on all of the records just don't specify any number next to dblpv14.json )
```powershell
docker run --rm -it \
  --memory=3g \
  --network advdaba_net \
  -v "$PWD":/app \
  -e NEO4J_AUTH=neo4j/testtest \
  -e NEO4J_URI=bolt://neo4j-server:7687 \
  -e TEAM_NAME=AnthonyAtallah_HadilZenati \
  advdaba_import:latest \
  dblpv14.json 100000

```
_Output should include TSV generation, import progress, and_ `✅ All done!`_

### 4. Verify counts
```powershell
docker run --rm `
  --network advdaba_net `
  -v "$PWD":/app `
  neo4j:latest `
  cypher-shell `
    -a bolt://neo4j-server:7687 `
    -u neo4j -p testtest `
    -f /app/metrics_queries.cql
```

### 5. Review performance summary

| Metric                       | Count        |
|------------------------------|-------------:|
| Articles                     | 5 259 865    |
| Authors                      | 2 863 644    |
| `AUTHORED` relationships     | 24 222 719   |
| `CITES` relationships        | 36 629 113   |
| Memory used (peak, container)| ~1900 MB      |
| Total import time            | ~5 487 s     |

We have got these numbers from running each command on the neo4j browser and then summing up the delays.
Also to be noted generating the TSVs files from all N=5259865 articles took us 2362.1 seconds.

```json
{
  "team": "AnthonyAtallah_HadilZenati",
  "N": 5259865,
  "RAM_MB": 3000,
  "seconds": 5487
}
```

---

## Full‐scale Import & Submission

The Kubernetes job currently fails in our environment. Instead, please run the full import **locally** with the same 3 GiB memory cap to ensure it stays under the required limit:

```powershell
# Import the entire dataset without a record limit, but cap container RAM at 3 GiB
docker run --rm -it `
  --memory=3g `
  --network advdaba_net `
  -v "$PWD":/app `
  -e NEO4J_AUTH=neo4j/testtest `
  -e NEO4J_URI=bolt://neo4j-server:7687 `
  -e TEAM_NAME=AnthonyAtallah_HadilZenati `
  advdaba_import:latest `
  dblpv14.json
```

> **Note:** The `--memory=3g` flag enforces the 3 GiB RAM cap on both the Neo4j server and importer.

---

*Prepared by AnthonyAtallah_HadilZenati*
