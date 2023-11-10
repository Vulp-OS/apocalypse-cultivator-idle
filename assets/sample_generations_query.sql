WITH RECURSIVE generation AS (
    SELECT name, parent, name AS path
    FROM parents
    WHERE parent IS NULL
    
    UNION ALL
    
        SELECT child.name, child.parent, path || '/' || child.name AS path
        FROM parents child
        JOIN generation g
            ON g.name = child.parent
)

SELECT name, tier, path
FROM generation
JOIN dao ON dao.name=generation.name