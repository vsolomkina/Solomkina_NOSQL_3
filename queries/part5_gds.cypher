# 5.1 Page Rangk

// Крок 1: матеріалізуємо ребра фільм-фільм через спільних користувачів
MATCH (m1:Movie)<-[r1:RATED]-(u:User)-[r2:RATED]->(m2:Movie)
WHERE r1.rating >= 4 AND r2.rating >= 4 AND id(m1) < id(m2)
WITH m1, m2, count(u) AS weight
WHERE size([(m1)<-[:RATED]-() | 1]) > 20
  AND size([(m2)<-[:RATED]-() | 1]) > 20
WITH m1, m2, weight
ORDER BY weight DESC
LIMIT 50000
MERGE (m1)-[co:CO_RATED]-(m2)
SET co.weight = weight;

// Крок 2: створюємо проєкцію на основі матеріалізованих ребер
CALL gds.graph.project(
  'movieGraph',
  'Movie',
  { CO_RATED: { orientation: 'UNDIRECTED', properties: 'weight' } }
)
YIELD graphName, nodeCount, relationshipCount;

// Крок 3: Запуск алгоритму PageRank (Стрімінговий режим)
CALL gds.pageRank.stream('movieGraph', {
  relationshipWeightProperty: 'weight',
  maxIterations: 20,
  dampingFactor: 0.85
})
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).title AS MovieTitle, score
ORDER BY score DESC
LIMIT 10;

// Крок 4: видаляємо проєкцію та тимчасові ребра
CALL gds.graph.drop('movieGraph');
MATCH ()-[co:CO_RATED]-() DELETE co;

# 5.2 Виявлення спільнот (Louvain)

// Крок 1: матеріалізуємо ребра користувач-користувач через спільні фільми
MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating >= 5 AND r2.rating >= 5 AND id(u1) < id(u2) # через обмеження компютера змінила рейтинг
WITH u1, u2, count(m) AS weight
WITH u1, u2, weight
ORDER BY weight DESC
LIMIT 5000  # через обмеження компютера ліміт довелось зменшити
MERGE (u1)-[sim:SIMILAR]-(u2)
SET sim.weight = weight;

// Крок 2: створюємо проєкцію
CALL gds.graph.project(
  'userSimilarity',
  'User',
  { SIMILAR: { orientation: 'UNDIRECTED', properties: 'weight' } }
)
YIELD graphName, nodeCount, relationshipCount;

// Крок 3: Запуск Louvain та збереження ID спільнот у вузли як тимчасову властивість
CALL gds.louvain.write('userSimilarity', {
  writeProperty: 'louvainCommunity',
  relationshipWeightProperty: 'weight'
})
YIELD communityCount, modularity;

// Крок 4: Аналіз 10 найбільших кластерів та їхніх топ-3 улюблених жанрів
MATCH (u:User)
WHERE u.louvainCommunity IS NOT NULL
WITH u.louvainCommunity AS ClusterID, count(u) AS ClusterSize, collect(u) AS UsersInCluster
ORDER BY ClusterSize DESC
LIMIT 10
UNWIND UsersInCluster AS user
MATCH (user)-[r:RATED]->(m:Movie)-[:BELONGS_TO]->(g:Genre)
WHERE r.rating = 5
WITH ClusterID, ClusterSize, g.name AS GenreName, count(*) AS GenreCount
ORDER BY ClusterID, GenreCount DESC
WITH ClusterID, ClusterSize, collect({genre: GenreName, count: GenreCount})[..3] AS TopGenres
RETURN ClusterID, ClusterSize, TopGenres;

// Крок 5: видаляємо проєкцію та тимчасові ребра
CALL gds.graph.drop('userSimilarity');
MATCH ()-[sim:SIMILAR]-() DELETE sim;

# 5.3 Найкоротший шлях між користувачами

// 1. Створюємо тимчасові ребра з твоїми стабільними налаштуваннями
MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = 5 AND r2.rating = 5 AND id(u1) < id(u2)
WITH u1, u2, count(m) AS weight
WITH u1, u2, weight
ORDER BY weight DESC
LIMIT 5000
MERGE (u1)-[sim:SIMILAR]-(u2)
SET sim.weight = weight;

// 2. Створюємо проєкцію в пам'яті
CALL gds.graph.project(
  'userGraph',
  'User',
  { SIMILAR: { orientation: 'UNDIRECTED', properties: 'weight' } }
)
YIELD graphName, nodeCount, relationshipCount;

// 3. Шукаємо найкоротший шлях Дейкстри між користувачами 1 та 50
MATCH (source:User {userId: 1}), (target:User {userId: 50})
CALL gds.shortestPath.dijkstra.stream('userGraph', {
  sourceNode: source,
  targetNode: target,
  relationshipWeightProperty: 'weight'
})
YIELD index, totalCost, nodeIds
RETURN 
  [nodeId IN nodeIds | gds.util.asNode(nodeId).userId] AS UserPath, 
  totalCost;

// 4. Фінальне очищення бази (скидаємо проєкцію та ребра)
CALL gds.graph.drop('userGraph');
MATCH ()-[sim:SIMILAR]-() DELETE sim;