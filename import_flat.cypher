// Uniqueness constraint for articles
CREATE CONSTRAINT article_id_unique
  IF NOT EXISTS
  FOR (a:Article)
  REQUIRE a._id IS UNIQUE;


// Uniqueness constraint for authors
CREATE CONSTRAINT author_id_unique
  IF NOT EXISTS
  FOR (x:Author)
  REQUIRE x._id IS UNIQUE;


// Load articles.tsv
CALL {
  LOAD CSV WITH HEADERS 
    FROM 'file:///articles.tsv' AS row
    FIELDTERMINATOR '\t'
  WITH row
  WHERE row._id IS NOT NULL AND row._id <> ''
  RETURN row
}
WITH row
CALL { 
   WITH row
   MERGE (a:Article { _id: row._id })
   SET a.title = row.title
}
IN TRANSACTIONS OF 5_000 ROWS;


// Load authors.tsv
CALL {
  LOAD CSV WITH HEADERS
    FROM 'file:///authors.tsv' AS row
    FIELDTERMINATOR '\t'
  WITH row
  WHERE row._id IS NOT NULL AND row._id <> ''
  RETURN row
}
WITH row
CALL {
  WITH row
  MERGE (p:Author { _id: row._id })
  SET p.name = row.name
}
IN TRANSACTIONS OF 5_000 ROWS;


// Load authored.tsv
CALL {
  LOAD CSV WITH HEADERS
    FROM 'file:///authored.tsv' AS row
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
    FROM 'file:///cites.tsv' AS row
    FIELDTERMINATOR '\t'
  WITH row
  WHERE row.article_id   IS NOT NULL
  AND row.reference_id IS NOT NULL
  RETURN row
}
WITH row
CALL {
  WITH row
  MATCH (src:Article { _id: row.article_id   })
  MATCH (tgt:Article { _id: row.reference_id })
  CREATE (src)-[:CITES]->(tgt)
}
IN TRANSACTIONS OF 10_000 ROWS;
