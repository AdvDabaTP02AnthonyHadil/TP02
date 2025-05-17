// Load authored.tsv
CALL {
  LOAD CSV WITH HEADERS
    FROM 'file:///imports/authored.tsv' AS row
    FIELDTERMINATOR '\t'
  WITH row
  WHERE row.article_id IS NOT NULL
  AND row.author_id IS NOT NULL
  RETURN row
}
WITH row
CALL {
  WITH row
  MATCH (a:Article { _id: row.article_id })
  MATCH (p:Author { _id: row.author_id })
  CREATE (p)-[:AUTHORED]->(a) 
}
IN TRANSACTIONS OF 10_000 ROWS;

// Load cites.tsv
CALL {
  LOAD CSV WITH HEADERS
    FROM 'file:///imports/cites.tsv' AS row
    FIELDTERMINATOR '\t'
  WITH row
  WHERE row.article_id IS NOT NULL
  AND row.reference_id IS NOT NULL
  RETURN row
}
WITH row
CALL {
  WITH row
  MATCH (src:Article { _id: row.article_id })
  MATCH (tgt:Article { _id: row.reference_id })
  CREATE (src)-[:CITES]->(tgt)
}
IN TRANSACTIONS OF 10_000 ROWS;
