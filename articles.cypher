CALL {
  LOAD CSV WITH HEADERS 
    FROM 'file:///imports/articles.tsv' AS row
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
