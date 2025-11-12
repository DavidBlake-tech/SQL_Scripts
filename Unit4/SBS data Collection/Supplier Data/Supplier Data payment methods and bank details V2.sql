WITH general_address AS (
	SELECT 
		* 
	FROM 
		agladdress
	WHERE
		client = 'SD'
		AND address_type = '1'
		AND attribute_id = 'A5'
),

delivery_address AS (
	SELECT 
		* 
	FROM 
		agladdress
	WHERE
		client = 'SD'
		AND address_type = '1'
		AND attribute_id = 'A5'
)
		
SELECT
	--*, 
	CAST(apar_id AS INT) as 'SupplierID'
	,apar_name as 'SupplierName'
	,c.country AS 'Country'
	,vat_reg_no AS 'VATregistrationNo'
	,comp_reg_no AS 'CompanyRegistrationNo'
	,h.status as 'Status'
	,apar_gr_id as 'SupplierGroup'
	,pay_Method as 'PaymentMethod (CH=Cheque or foreign manual payment, IP=BACS)'
	,'We Dont store Bank Account Name' as 'BankAccountName'
	,bank_account as 'AccountNumber'
	,clearing_code as 'SortCode'
	,h.currency as 'CurrencyCode (we only use GBP)'
	,d.description as 'Terms'
	,h.last_update As 'LastUpdated (we do not store created date)'
	,ga.address AS 'FinanceAddress'
	,ga.place AS 'FinanceCity'
	,ga.province AS 'FinanceCounty'
	,ga.zip_code AS 'FinancePostCode'
	,ga.telephone_1 AS 'FinanceTelephone1'
	,ga.telephone_2 AS 'FinanceTelephone2'
	,ga.telephone_3 AS 'FinanceTelephone3'
	,ga.telephone_4 AS 'FinanceTelephone4'
	,ga.telephone_5 AS 'FinanceTelephone5'
	,ga.telephone_6 AS 'FinanceTelephone6'
	,ga.telephone_7 AS 'FinanceTelephone7'
	,ga.e_mail AS 'FinanceEmail'
	,ga.e_mail_cc AS 'FinanceEmail_CC'
	,da.address AS 'OrderAddress'
	,da.place AS 'OrderCity'
	,da.province AS 'OrderCounty'
	,da.telephone_1 AS 'OrderTelephone1'
	,da.telephone_2 AS 'OrderTelephone2'
	,da.telephone_3 AS 'OrderTelephone3'
	,da.telephone_4 AS 'OrderTelephone4'
	,da.telephone_5 AS 'OrderTelephone5'
	,da.telephone_6 AS 'OrderTelephone6'
	,da.telephone_7 AS 'OrderTelephone7'
	,da.e_mail AS 'OrderEmail'
	,da.e_mail_cc AS 'OrderEmail_CC'



FROM
	asuheader h
	join agldimvalue d on d.dim_value = h.terms_id AND d.attribute_id = 'AY' AND d.client = 'sd'
	LEFT JOIN general_address ga ON h.apar_id = ga.dim_value
	LEFT JOIN delivery_address da ON h.apar_id = da.dim_value
	JOIN aagcountry c ON h.country_code = c.country_code AND c.language = 'en'
WHERE 
	h.client = 'SD'
	AND h.status = 'N'