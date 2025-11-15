SELECT 
    r.role_id,
    r.description,
    r.status AS 'Role Status',
    CASE
        WHEN r.role_id LIKE 'sup-%' THEN SUBSTRING(r.role_id, 5, LEN(r.role_id) - 4)
        WHEN r.role_id LIKE 'dc-7-%' THEN SUBSTRING(r.role_id, 6, LEN(r.role_id) - 5)
        WHEN r.role_id LIKE 'req[0-9]%' THEN SUBSTRING(r.role_id, 4, LEN(r.role_id) - 3)
        ELSE ''
    END AS [Cost Centre],
    dv.description AS [Cost Centre Name]
	,dv.status AS 'CC Status'
    ,ud.[user_id]
FROM aagrole AS r
    LEFT JOIN agldimvalue AS dv 
        ON dv.dim_value = 
            CASE
                WHEN r.role_id LIKE 'sup-%' THEN SUBSTRING(r.role_id, 5, LEN(r.role_id) - 4)
                WHEN r.role_id LIKE 'dc-7-%' THEN SUBSTRING(r.role_id, 6, LEN(r.role_id) - 5)
                WHEN r.role_id LIKE 'req[0-9]%' THEN SUBSTRING(r.role_id, 4, LEN(r.role_id) - 3)
                ELSE ''
            END
    AND dv.attribute_id = 'c1'
    LEFT JOIN aaguserdetail ud ON r.role_id = ud.role_id --and ud.[user_id] = 'system'

WHERE 
    r.status = 'n'
	AND dv.status = 'c'
    AND (
        r.role_id LIKE 'req[0-9]%' 
        OR r.role_id LIKE 'sup-%' 
        OR r.role_id LIKE 'dc-7-%'
    )
	AND CASE
            WHEN r.role_id LIKE 'sup-%' THEN SUBSTRING(r.role_id, 5, LEN(r.role_id) - 4)
            WHEN r.role_id LIKE 'dc-7-%' THEN SUBSTRING(r.role_id, 6, LEN(r.role_id) - 5)
            WHEN r.role_id LIKE 'req[0-9]%' THEN SUBSTRING(r.role_id, 4, LEN(r.role_id) - 3)
            ELSE ''
        END NOT LIKE '8%'

ORDER BY
	CASE
            WHEN r.role_id LIKE 'sup-%' THEN SUBSTRING(r.role_id, 5, LEN(r.role_id) - 4)
            WHEN r.role_id LIKE 'dc-7-%' THEN SUBSTRING(r.role_id, 6, LEN(r.role_id) - 5)
            WHEN r.role_id LIKE 'req[0-9]%' THEN SUBSTRING(r.role_id, 4, LEN(r.role_id) - 3)
            ELSE ''
        END
