MATCH (n)
WITH n, count{(n)-[]-()} AS Degree
ORDER BY Degree DESC
LIMIT 10
RETURN 
  labels(n)[0] AS NodeType, 
  coalesce(n.title, n.name, toString(n.userId)) AS NodeIdentifier, 
  Degree;