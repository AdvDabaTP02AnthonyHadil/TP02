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
