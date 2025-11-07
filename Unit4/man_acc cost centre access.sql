WITH UserInfo AS (
    SELECT
        ur.user_id,
        ud.description,
        ud.status
    FROM 
        aaguserdetail ur
        LEFT JOIN aaguser ud ON ur.user_id = ud.user_id
    WHERE 
        (role_id LIKE 'SUP-%' OR role_id LIKE 'REQ%' OR role_id LIKE 'DC-7-%')
        AND role_id NOT LIKE 'REQ %'
        AND role_id NOT IN ('REQUISTIONER', 'SUP-PENS', 'SUP-PU', 'SUP-TSD')
        AND ur.user_id NOT IN ('SYSTEM')
    GROUP BY ur.user_id, ud.description, ud.status
),
InvoiceApprovers AS (
    SELECT
        user_id,
        SUBSTRING(role_id, 5, LEN(role_id) - 4) AS CostCentre
    FROM aaguserdetail
    WHERE role_id LIKE 'SUP-%'
),
RequisitionApprovers AS (
    SELECT
        user_id,
        SUBSTRING(role_id, 4, LEN(role_id) - 3) AS CostCentre
    FROM aaguserdetail
    WHERE role_id LIKE 'REQ%' AND role_id != 'REQUISTIONER'
),
Requisitioners AS (
	SELECT
		user_id,
		SUBSTRING(role_id, CHARINDEX('-', role_id, CHARINDEX('-', role_id) + 1) + 1, LEN(role_id)) AS CostCentre
	FROM aaguserdetail
	WHERE role_id LIKE 'DC-7-%'
),
UserRoles AS (
    SELECT user_id, CostCentre,
        1 AS Inv_approver,
        0 AS Req_approver,
        0 AS Reqstr_flag
    FROM InvoiceApprovers

    UNION ALL

    SELECT user_id, CostCentre,
        0 AS Inv_approver,
        1 AS Req_approver,
        0 AS Reqstr_flag
    FROM RequisitionApprovers

    UNION ALL

    SELECT user_id, CostCentre,
        0 AS Inv_approver,
        0 AS Req_approver,
        1 AS Reqstr_flag
    FROM Requisitioners
),
DistinctUserRoles AS (
    SELECT 
        user_id, 
        CostCentre,
        MAX(Inv_approver) AS Inv_approver,
        MAX(Req_approver) AS Req_approver,
        MAX(Reqstr_flag) AS Reqstr_flag
    FROM UserRoles
    GROUP BY user_id, CostCentre
),
InvoiceApproverCount AS (
	SELECT CostCentre, COUNT(*) AS InvApproverCount
	FROM InvoiceApprovers
	GROUP BY CostCentre
),
RequisitionApproverCount AS (
	SELECT CostCentre, COUNT(*) AS ReqApproverCount
	FROM RequisitionApprovers
	GROUP BY CostCentre
),
RequisitionerCount AS (
	SELECT CostCentre, COUNT(*) AS Reqstr_Count
	FROM Requisitioners
	GROUP BY CostCentre
),
CostCentreInfo AS (
	SELECT 
		dim_value,
		description, 
		status,
		dim_f AS Spec,
		dim_f_name AS Speciality_Name
	FROM agldimvalue cc
	LEFT JOIN uvitrees t ON t.tree_id = '46' AND cc.dim_value = t.cat_1
	WHERE attribute_id = 'C1' AND cc.client = 'SD'
),
BudgetHolderInfo AS (
	SELECT 
		b.dim_value, 
		b.user_name, 
		u.description 
	FROM afxbudhold b
	LEFT JOIN aaguser u ON b.user_name = u.user_id
)
SELECT 
	u.user_id,
	ui.description AS User_Name,
	ui.status AS User_Status,
	u.CostCentre,
	cci.description AS Cost_Centre_Description,
	cci.status AS CC_Status,
    CASE WHEN u.Reqstr_flag = 1 THEN 'Yes' ELSE '' END AS Requisitioner,
    rc.Reqstr_Count AS RequisitionerCount,
	CASE WHEN u.Req_approver = 1 THEN 'Yes' ELSE '' END AS Req_approver,
	rac.ReqApproverCount,
	CASE WHEN u.Inv_approver = 1 THEN 'Yes' ELSE '' END AS Inv_approver,
	iac.InvApproverCount,
	bh.user_name AS Budget_Holder_ID,
	bh.description AS Budget_Holder_Name,
	cci.Spec,
	cci.Speciality_Name,
    '' AS 'MA Comments'
FROM DistinctUserRoles u
LEFT JOIN InvoiceApproverCount iac ON u.CostCentre = iac.CostCentre
LEFT JOIN RequisitionApproverCount rac ON u.CostCentre = rac.CostCentre
LEFT JOIN RequisitionerCount rc ON u.CostCentre = rc.CostCentre
LEFT JOIN CostCentreInfo cci ON u.CostCentre = cci.dim_value
LEFT JOIN UserInfo ui ON u.user_id = ui.user_id
LEFT JOIN BudgetHolderInfo bh ON u.CostCentre = bh.dim_value
WHERE   
    cci.dim_value NOT IN (
        SELECT dim_value 
        FROM agldimvalue 
        WHERE attribute_id = '9'
    )
    AND u.[user_id] IN ('NIKOS98', 'BALIA99', 'SPURI99', 'TRENA96', 'HOWARDL', 'COLLG97', 'ROBES82', 'KNIGA94', 'SUSUE99', 'LEWIH91', 'GILMS99', 'COTTT97', 'FOULS99', 'RYLANC0R', 'BLACJ92', 'HOLGS99', 'WOOD', 'ELLIOC0R', 'CROCD98', 'REYNH98', 'POURJ99', 'MARTA81', 'MEYEK99', 'HUGGE98', 'HINER99', 'ASPRP99', 'GIBBSC0R', 'DODDA99', 'REESN98', 'BOLTJ96', 'AVGHEH0R', 'ROVAIN0R'
)
ORDER BY u.CostCentre, ui.description;
