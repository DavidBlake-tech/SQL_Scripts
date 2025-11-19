SELECT DISTINCT
    
    r.role_id
    ,[description]
    ,r.[status]
    ,COUNT(UD.role_id) AS 'User Count'
    ,'' AS 'Persona'
FROM 
    aagrole r
    LEFT JOIN aaguserdetail ud ON r.role_id = ud.role_id
WHERE
    r.status = 'N'
    AND r.role_id NOT LIKE 'SUP-%'
    AND r.role_id NOT LIKE 'DC-%'
    AND r.role_id NOT LIKE 'REQ[0-9]%'
    AND r.role_id NOT LIKE 'REQA%'
    AND r.role_id NOT LIKE 'REQM%'
    AND r.role_id NOT LIKE 'REP-%'
    AND r.role_id NOT LIKE 'REQH%'
    AND r.role_id NOT LIKE 'FINANCE %'
GROUP BY
    r.role_id
    ,[description]
    ,r.[status]