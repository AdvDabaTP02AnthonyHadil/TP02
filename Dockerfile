# Use the official Neo4j image as base
FROM neo4j:latest

# Switch to root to install Python & curl
USER root
RUN apt-get update \
    && apt-get install -y python3 python3-pip curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory for import scripts and data
WORKDIR /app

# Copy conversion scripts, new unified TSV generator, requirements, Cypher and wrapper
COPY to_tsvs_from_json.py requirements.txt import_flat.cypher import_all.sh ./

# Make wrapper executable & install dependencies
RUN chmod +x import_all.sh \
    && pip3 install --no-cache-dir -r requirements.txt

# Expose Neo4j HTTP and Bolt ports
EXPOSE 7474 7687

# Default command: run import wrapper
ENTRYPOINT ["bash", "import_all.sh"]
