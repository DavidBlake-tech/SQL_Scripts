SET NOCOUNT ON;
PRINT 'We only store supervisors for approvers, this is for the purpose of task escalation only, we do not store the organisational hierarchy in Unit4, that is controlled by Workforce Information Team';
PRINT 'We don''t store start date in Unit4, as Unit4 is not used for personel management';
PRINT 'We don''t maintain job titles in Unit4';
PRINT 'Unit4 doesn''t have the concept of default locations, locations are tied to cost centres for purposes of delivery addresses';


WITH supervisors AS (

    select  
	a.target_value
	,u.description
	,a.rule_id
	,s.recipient
	,u2.description as 'supervisor'
 from 
	awfuserfilter a 
	left outer join aaguser u on a.client=u.def_client and a.target_value=u.user_id
	left outer join awfsupervisor s on a.client=s.client and a.rule_id=s.rule_id
	left outer join aaguser u2 on a.client=u2.def_client and s.recipient=u2.user_id
	left outer join awfuserrule r on r.client=a.client and a.rule_id=r.rule_id and a.rule_type=r.rule_type
 where 
	a.client='sd' and a.rule_type='WFSUPERVISOR'  
	and u.status='n' 
	and r.status='n' 
	and u2.status='n'  
	and s.date_to > GETDATE()
 group by  
	a.target_value
	,u.description
	,a.rule_id
	,s.recipient
	,u2.description
)

SELECT 
    u.[description] AS 'Employee Full Name'
    ,u.[user_id] AS 'Employee Username'
    ,'Not kept in Unit4' AS 'Start_Date'
    ,a.e_mail AS 'Email Address'
    ,s.supervisor AS 'Supervisors Full Name'
    ,STRING_AGG(CAST(r.role_id AS VARCHAR(MAX)), ' , ') AS role_id
    ,'Not kept in Unit4' AS 'User Job Title'
    ,'Unit4 doesnt have default locations tied to users' AS 'Default Location'
    ,   CASE 
            WHEN MAX(CASE WHEN r.role_id = 'DFCE' THEN 1 ELSE 0 END) = 1 THEN '> £100k'
            WHEN MAX(CASE WHEN r.role_id = '10K Approver' THEN 1 ELSE 0 END) = 1 THEN 'up to £100k'
            WHEN MAX(case when r.role_id = 'APPROVER'THEN 1 ELSE 0 END) = 1 THEN 'Up to £10k' 
            ELSE 'Not Approver' 
        END AS 'Invoice Limit'
    ,   CASE
            WHEN MAX(CASE WHEN r.role_id IN ('AR CLERK','AR_CLERK SUP','SO SIMPLE','SO INTERMEDI','SO FREE TXT') THEN 1 ELSE 0 END) = 1 THEN 'UNLIMITED'
            ELSE '' 
        END AS 'Sales Order Limit'
    ,   CASE
            WHEN MAX(CASE WHEN r.role_id IN ('AR CLERK','AR_CLERK SUP','SO SIMPLE','SO INTERMEDI','SO FREE TXT') THEN 1 ELSE 0 END) = 1 THEN 'UNLIMITED'
            ELSE '' 
        END AS 'Credit Memo Limit'
    , '' AS 'General Ledger Limit'
    , '' AS 'Approve Blanket Purchase Agreements'
    , '' AS 'Approve Standard Purchase Orders'
    , '' AS 'Approve Blanket Releases'
    , '' AS 'Approve Contract Purchase Orders'
FROM 
    aaguser u
    LEFT JOIN aaguserdetail r ON u.[user_id] = r.[user_id]
    LEFT JOIN agladdress a ON u.[user_id] = a.dim_value
    LEFT JOIN supervisors s on u.[user_id] = s.target_value
WHERE 
    u.[status] = 'n'
    AND u.[user_id] NOT IN ('BUDHOLD')
    AND r.role_id NOT IN ('','SALESPERSON', 'SALESMANAGER', 'PERSONAL','PM TSD')
    AND r.role_id NOT LIKE 'DC-%'
    AND r.role_id NOT LIKE 'SUP-%'
    AND r.role_id NOT LIKE 'REQ[0-9]%'
    AND r.role_id NOT LIKE 'REP-7%'
    AND r.role_id NOT LIKE 'PM %'
GROUP BY
    u.[user_id]
    ,u.[description]
    ,a.e_mail
    ,s.supervisor
ORDER BY
    u.[user_id]

