# DBLP to Neo4j Import (Kubernetes Version)

## 👥 Team

- Anthony Atallah
- Hadil Zenati

## 🧠 Overview

This project loads the full **DBLP v14 dataset (~5.2M articles)** into **Neo4j** using a Kubernetes Job + Deployment setup. It performs:

- `Article` nodes (`_id`, `title`)
- `Author` nodes (`_id`, `name`)
- `AUTHORED` relationships (Author → Article)
- `CITES` relationships (Article → Article)

---

## 📁 Repository Layout

```
import/
├── Dockerfile
├── import_all.sh
├── to_tsvs_from_json.py
├── import_flat.cypher
├── wait-for-neo4j.sh
├── requirements.txt
├── dblpv14.json (⚠️ not included in Git)
├── job.log (generated after full import)
└── k8s/
    ├── job.yaml
    ├── neo4j-deployment.yaml
    ├── neo4j-service.yaml
    ├── neo4j.conf
    └── configmap.yaml
```

---

## 🧱 Prerequisites

- Docker Desktop with Kubernetes enabled
- ~3 GB+ memory allocated to Docker/K8s
- `dblpv14.json` placed at the root of the `import/` folder
- Windows WSL2 or native Linux recommended

---

## 🚀 Deployment Steps (Full Dataset)

### 1. Build the image

```bash
cd import
docker build -t advdaba_import:latest .
```

### 2. Deploy Neo4j in Kubernetes

```bash
kubectl apply -f k8s/neo4j-deployment.yaml
kubectl apply -f k8s/neo4j-service.yaml
```

### 3. Forward ports to access Neo4j (in 2 terminals)

```bash
kubectl port-forward service/neo4j-service 7474:7474
kubectl port-forward service/neo4j-service 7687:7687
```

Then open [http://localhost:7474](http://localhost:7474)  
**Login:** neo4j / testtest

---

### 4. Run the import job (on all 5M+ records)

```bash
kubectl apply -f k8s/job.yaml
```

Follow logs with:

```bash
kubectl logs job/advdaba-import-job -f
```

You should see:
```
✓ TSVs generated (N=5259865)
✅ Neo4j is ready!
🚀 Importing into Neo4j
✅ All done!
```

---

## 🔍 Verify Results in Neo4j Browser

Try the following Cypher queries:

```cypher
MATCH (n) RETURN count(n);
MATCH (a:Article) RETURN count(a);
MATCH (a:Author) RETURN count(a);
MATCH (a:Author)-[:AUTHORED]->(ar:Article) RETURN a.name, ar.title LIMIT 10;
```

---

## 📄 Submission Content

- ✅ `Dockerfile`, `import_all.sh`, `to_tsvs_from_json.py`
- ✅ `wait-for-neo4j.sh` (ensures Neo4j is reachable)
- ✅ `import_flat.cypher`
- ✅ `k8s/job.yaml`, `neo4j-deployment.yaml`, `neo4j-service.yaml`, `neo4j.conf`
- ✅ `job.log` (export logs via `kubectl logs job/advdaba-import-job > job.log`)
- ✅ This `README.md`

---

## 🧪 Performance Notes

| Metric                       | Value        |
|-----------------------------|--------------|
| Articles imported           | 5 259 865     |
| Authors                     | ~2.8M         |
| AUTHORED relationships      | ~24M          |
| CITES relationships         | ~36M          |
| Total nodes                 | ~14M+         |
| RAM limit enforced          | 3 GiB         |
| Import time (TSV+Neo4j)     | ~5400s        |

---

## ℹ️ Notes for Reviewers

- The import runs **entirely inside Kubernetes**, with shared volume from host
- Neo4j and the importer are two separate containers
- TSVs are mounted into `/imports` inside the Neo4j pod for access via `LOAD CSV`
- Default ports: `7474` (HTTP), `7687` (Bolt)
- `NEO4J_AUTH=neo4j/testtest`

> For convenience, all logs are available in `job.log`. The system was tested and verified with a full 5M+ dataset import.

---

**Prepared by Anthony Atallah & Hadil Zenati**