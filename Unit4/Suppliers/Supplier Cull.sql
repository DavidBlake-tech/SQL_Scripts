/*
Variable to set the date cuttoff for a supplier cull
*/

DECLARE @DateCutoff DATE;
SET @DateCutoff = DATEADD(month,-18, GETDATE());

-----------------------------------------------------------------------------------------
/*
The following checks and removes any residual temp tables.
*/

-- Check if the #TEMP_SUPPLIER_APPROVED_TRANSACTIONS table exists and drop it if it does
IF OBJECT_ID('tempdb..#TEMP_SUPPLIER_APPROVED_TRANSACTIONS') IS NOT NULL
    DROP TABLE #TEMP_SUPPLIER_APPROVED_TRANSACTIONS;

-- Check if the #ACTIVE_REQUISITIONS table exists and drop it if it does
IF OBJECT_ID('tempdb..#TEMP_ACTIVE_REQUISITIONS') IS NOT NULL
    DROP TABLE #TEMP_ACTIVE_REQUISITIONS;

-- Check if the #OPEN_PO_LINES table exists and drop it if it does
IF OBJECT_ID('tempdb..#TEMP_OPEN_PO_LINES') IS NOT NULL
    DROP TABLE #TEMP_OPEN_PO_LINES;

-- Check if the #A_STATUS table exists and drop it if it does
IF OBJECT_ID('tempdb..#TEMP_A_STATUS') IS NOT NULL
    DROP TABLE #TEMP_A_STATUS;

	-- Check if the ##TEMP_PRODUCT_COUNT table exists and drop it if it does
IF OBJECT_ID('tempdb..#TEMP_PRODUCT_COUNT') IS NOT NULL
    DROP TABLE #TEMP_PRODUCT_COUNT;
--------------------------------------------------------------------------------------------------------------------

-- Create the temporary tables
------------------------------

/* 
	This temporary table filters agltransact to only return AP transactions from GL and has one row per supplier
	and contains the Supplier ID and the most recent 'last_update' for each supplier.
*/
CREATE TABLE #TEMP_SUPPLIER_APPROVED_TRANSACTIONS (
    apar_id INT,
    LastTransDate DATE
	);

-- Insert AP agltransact data into a temporary table
	INSERT INTO #TEMP_SUPPLIER_APPROVED_TRANSACTIONS (apar_id, LastTransDate)
		SELECT 
			apar_id,
			MAX(CAST(last_update AS DATE)) AS LastTransDate
		FROM 
			agltransact
		WHERE 
			voucher_type IN ('IIP', 'IIR','SP','SR','SI','PP')
		GROUP BY
			apar_id;
-----------------------------------------------------------------------------------------------------------------------
/*
	This temporary table returns a count of requisition lines that are not CLOSED or FINISHED
*/
CREATE TABLE #TEMP_ACTIVE_REQUISITIONS(
	apar_id INT,
	OpenReqLines INT,
	MostRecentOpenRequsition DATE
	)

	INSERT INTO #TEMP_ACTIVE_REQUISITIONS
		SELECT
			apar_id,
			count(agrtid) as 'Open Req Lines',
			MAX(last_update) as 'Most Recent Open Req'
		FROM 
			aporeqdetail
		WHERE 
			status not in ('F','C','T')
		GROUP BY
			apar_id
------------------------------------------------------------------------------------------------
/*
This temp table returns PO lines that are NOT Closed(C) or Finished (F)
*/

CREATE TABLE #TEMP_OPEN_PO_LINES(
	apar_id INT,
	ActiveOrderLines INT
	)

	INSERT INTO #TEMP_OPEN_PO_LINES
		SELECT
			apar_id,
			COUNT(order_id) AS 'Active Order Lines'
		FROM 
			apodetail
		WHERE 
			STATUS not in ('F','C','T') and client ='SD'
		GROUP BY
			apar_id
--------------------------------------------------------------------------------------------------------
/*
This temp table returns A status invoices
*/
CREATE TABLE #TEMP_A_STATUS(
	apar_id INT,
	UnapprovedCount INT
	)

	INSERT INTO #TEMP_A_STATUS	
		SELECT	
			APAR_ID,
			COUNT(DISTINCT VOUCHER_NO) 
		FROM 
			ACRTRANS
		GROUP BY
			APAR_ID
--------------------------------------------------------------------------------------------------
/*
This temp table returns a count of active products per supplier in the product master file
*/
CREATE TABLE #TEMP_PRODUCT_COUNT(
	apar_id INT,
	ProductCount INT
	)

	INSERT INTO #TEMP_PRODUCT_COUNT
	SELECT 
		apar_id,
		COUNT(DISTINCT article)
	FROM 
		algarticle
	WHERE 
		bflag =1 and 
		client ='sd' and 
		status != 'c'
	GROUP BY
		apar_id
--------------------------------------------------------------------------------------------------------

SELECT
    a.apar_id,
    a.apar_name,
	a.apar_gr_id,
	MAX(CAST(a.last_update AS DATE)) AS 'Last Supplier Update',
    a.status as 'Supplier Status',
	c.UnapprovedCount AS 'Unapproved Invoices',
	CASE 
		WHEN MAX(CAST(b.last_update AS DATE)) IS NULL THEN 'NONE' 
		ELSE 'Unpaid Transaction Present' END AS 'B Status',
	MAX(CAST(d.LastTransDate AS DATE)) as 'Last Transaction update',
	e.OpenReqLines AS 'Open Req Lines',
	e.MostRecentOpenRequsition as 'Most Recent Open Req',
	f.ActiveOrderLines AS 'Active Order Lines',
	g.ProductCount

FROM 
    asuheader AS a
	LEFT OUTER JOIN asutrans AS b ON a.apar_id = b.apar_id -- if trans is B, it'll still show in ASUTRANS
	LEFT OUTER JOIN #TEMP_A_STATUS AS c ON a.apar_id = c.apar_id -- Check ACRTRANS for A Status
	LEFT OUTER JOIN #TEMP_SUPPLIER_APPROVED_TRANSACTIONS AS d ON a.apar_id = d.apar_id -- If it is an B or C it'll show in agltransact
	LEFT OUTER JOIN #TEMP_ACTIVE_REQUISITIONS AS e ON a.apar_id = e.apar_id -- returns the count of active Req Lines
	LEFT OUTER JOIN #TEMP_OPEN_PO_LINES AS f ON a.apar_id = f.apar_id -- returns count of open PO Lines
	LEFT OUTER JOIN #TEMP_PRODUCT_COUNT AS g on a.apar_id = g.apar_id -- returns the count of active products for the supplier.

WHERE 
	a.client ='sd' and
	a.status IN ('N','P') AND
	a.apar_id != 888888 AND
	(d.LastTransDate < @DateCutoff OR d.LastTransDate is NULL) AND -- only returns last trans more then the DateCuttoff variable (or NULL)
	a.last_update < @DateCutoff -- only returns suppliers that were last updated more then the DateCuttoff variable

GROUP BY
	A.apar_id,
	a.apar_name,
	a.apar_gr_id,
	a.last_update,
    a.status,
	c.UnapprovedCount,
	e.OpenReqLines,
	e.MostRecentOpenRequsition,
	f.ActiveOrderLines,
	g.ProductCount

ORDER BY
	A.last_update

-- Drop the temporary tables
DROP TABLE #TEMP_SUPPLIER_APPROVED_TRANSACTIONS 
DROP TABLE #TEMP_ACTIVE_REQUISITIONS
DROP TABLE #TEMP_OPEN_PO_LINES
DROP TABLE #TEMP_A_STATUS
DROP TABLE #TEMP_PRODUCT_COUNT