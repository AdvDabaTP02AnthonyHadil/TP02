// node counts
MATCH (a:Article) RETURN count(a);
MATCH (u:Author)  RETURN count(u);
MATCH ()-[r:AUTHORED]->() RETURN type(r), count(r);
MATCH ()-[r:CITES]->()    RETURN type(r), count(r);
