// 1. Користувачі

LOAD CSV WITH HEADERS FROM 'file:///users.csv' AS row
CREATE (:User {
  userId: toInteger(row.userId),
  gender: row.gender,
  age: toInteger(row.age),
  occupation: toInteger(row.occupation),
  zipCode: row.zipCode
});

// 2. Жанри та фільми

LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS row
MERGE (m:Movie {movieId: toInteger(row.movieId)})
SET m.title = row.title
WITH m, row
UNWIND split(row.genres, '|') AS genreName
MERGE (g:Genre {name: genreName})
MERGE (m)-[:BELONGS_TO]->(g);

// 3. Оцінки

CALL apoc.periodic.iterate(
  "LOAD CSV WITH HEADERS FROM 'file:///ratings.csv' AS row RETURN row",
  "MATCH (u:User {userId: toInteger(row.userId)})
   MATCH (m:Movie {movieId: toInteger(row.movieId)})
   CREATE (u)-[:RATED {rating: toInteger(row.rating), timestamp: toInteger(row.timestamp)}]->(m)",
  {batchSize: 10000, parallel: false}
);