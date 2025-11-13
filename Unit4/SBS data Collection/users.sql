WITH supervisors AS (
    SELECT  
        a.target_value,
        u.description,
        supervisors = STUFF((
            SELECT DISTINCT ', ' + u2a.description
            FROM awfuserfilter a2
            INNER JOIN awfsupervisor s2 
                ON a2.client = s2.client AND a2.rule_id = s2.rule_id
            INNER JOIN aaguser u2a 
                ON a2.client = u2a.def_client AND s2.recipient = u2a.user_id
            WHERE a2.client = a.client
              AND a2.target_value = a.target_value
              AND u2a.status = 'n'
              AND s2.date_to > GETDATE()
            FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'), 1, 2, '')
    FROM awfuserfilter a
    INNER JOIN aaguser u ON a.client = u.def_client AND a.target_value = u.user_id
    INNER JOIN awfuserrule r ON r.client = a.client AND a.rule_id = r.rule_id AND a.rule_type = r.rule_type
    WHERE a.client = 'sd' AND a.rule_type = 'WFSUPERVISOR' AND u.status = 'n' AND r.status = 'n'
    GROUP BY a.client, a.target_value, u.description
),
LatestAssignment AS (
    SELECT 
        LEFT(ua.assignment_number, CHARINDEX('-', ua.assignment_number + '-') - 1) AS assignment_number,
        ua.position_title,
        ua.file_date,
        ua.client
    FROM uESRassignment ua
    WHERE ua.file_date = (
        SELECT MAX(file_date) 
        FROM uESRassignment ua2
        WHERE ua2.assignment_number = ua.assignment_number
    )
),
LatestPerUser AS (
    SELECT 
        ud.user_id,
        ud.dim_value AS ESR_Number,
        la.position_title,
        la.file_date,
        ROW_NUMBER() OVER (PARTITION BY ud.user_id ORDER BY la.file_date DESC) AS rn
    FROM aagviuserdetail ud
    INNER JOIN LatestAssignment la
        ON LEFT(ud.dim_value, CHARINDEX('-', ud.dim_value + '-') - 1) = la.assignment_number
    WHERE ud.status = 'n' AND ud.dim_value != ''
),
UserMap AS (
    SELECT user_id, ESR_Number, position_title
    FROM LatestPerUser
    WHERE rn = 1
      
)
SELECT 
    CASE 
        WHEN CHARINDEX(' ', u.[description]) > 0 
            THEN LEFT(u.[description], CHARINDEX(' ', u.[description]) - 1)
        ELSE u.[user_id]
    END AS 'First Name',
    CASE 
        WHEN CHARINDEX(' ', u.[description]) > 0 
            THEN LTRIM(SUBSTRING(u.[description], CHARINDEX(' ', u.[description]) + 1, LEN(u.[description])))
        ELSE ''
    END AS 'Last Name',
    a.e_mail AS 'Email Address',
    'Not stored in Unit4' AS 'Telephone',
    CASE
        WHEN um.ESR_Number LIKE '[0-9]%' THEN um.ESR_Number ELSE 'Not available from Unit4'
    END AS 'ESR Number',
    'Unit4 doesnt have default locations tied to users' AS 'Default Cost Centre (Legacy)',
    '' AS 'New Cost Centre',
    '' AS 'Department',
    '' AS 'Department Other (Please state)',
    '' AS 'Oracle Location',
    'Not held in Unit4' AS 'Physical Location',
    'See CC_ReqPoints Sheet' AS 'NHS SC Transfer Point',
    s.supervisors AS 'Default System Line Manager',
    CASE 
        WHEN MAX(CASE WHEN r.role_id = 'DFCE' THEN 1 ELSE 0 END) = 1 THEN 'All TRX Unlimited'
        WHEN MAX(CASE WHEN r.role_id = '10K Approver' THEN 1 ELSE 0 END) = 1 THEN 'All TRX 100000'
        WHEN MAX(CASE WHEN r.role_id = 'APPROVER' THEN 1 ELSE 0 END) = 1 THEN 'All TRX 10000' 
        ELSE 'NO APPROVAL LIMIT' 
    END AS 'Approval Levels',
    CASE
        WHEN MAX(CASE WHEN r.role_id IN ('AR CLERK','AR_CLERK SUP','SO SIMPLE','SO INTERMEDI','SO FREE TXT') THEN 1 ELSE 0 END) = 1 THEN 'UNLIMITED'
        ELSE '' 
    END AS 'Sales Invoice',
    CASE
        WHEN MAX(CASE WHEN r.role_id IN ('AR CLERK','AR_CLERK SUP','SO SIMPLE','SO INTERMEDI','SO FREE TXT') THEN 1 ELSE 0 END) = 1 THEN 'UNLIMITED'
        ELSE '' 
    END AS 'Sales Adjustment',
    '' AS 'Persona 1',
    '' AS 'Persona 2',
    '' AS 'Persona 3',
    '' AS 'Persona 4',
    '' AS 'Persona 5',
    '' AS 'Persona 6',
    '' AS 'Persona 7',
    '' AS 'Persona 8',
    '' AS 'Persona 9',
    '' AS 'Persona 10',
    '' AS 'Persona 11',
    '' AS 'Persona 12',
    '' AS 'Persona 13',
    '' AS 'Persona 14',
    '' AS 'Project Rate',
    STRING_AGG(CAST(r.role_id AS VARCHAR(MAX)), ' , ') AS 'Unit4 Functional Roles',
    um.position_title AS 'User Job Title'
    ,u.USER_ID
FROM aaguser u
LEFT JOIN aaguserdetail r ON u.[user_id] = r.[user_id]
LEFT JOIN agladdress a ON u.[user_id] = a.dim_value
LEFT JOIN supervisors s ON u.[user_id] = s.target_value
LEFT JOIN UserMap um ON u.[user_id] = um.[user_id]
WHERE u.[status] = 'n'
  AND u.[user_id] NOT IN ('BUDHOLD', 'SYSTEM')
  AND r.role_id NOT IN ('','SALESPERSON', 'SALESMANAGER', 'PERSONAL','PM TSD')
  AND r.role_id NOT LIKE 'DC-%'
  AND r.role_id NOT LIKE 'SUP-%'
  AND r.role_id NOT LIKE 'REQ[0-9]%'
  AND r.role_id NOT LIKE 'REP-7%'
  AND r.role_id NOT LIKE 'PM %'
GROUP BY
    u.[user_id],
    u.[description],
    a.e_mail,
    s.supervisors,
    um.ESR_Number,
    um.position_title
ORDER BY u.[user_id];
