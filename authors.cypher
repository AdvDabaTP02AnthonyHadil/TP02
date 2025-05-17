CALL {
  LOAD CSV WITH HEADERS
    FROM 'file:///imports/authors.tsv' AS row
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
