
DECLARE @StartPeriod INT = 202505;
DECLARE @EndPeriod INT = 202505;
DECLARE @Account CHAR(4) = 6150;



/* 
    This Common Table Expression returns a table of unique attributes and their descriptions.
*/
WITH attributesCTE AS (

    SELECT
        attribute_id
        , description
    FROM
        agldimension
    WHERE
        client = 'SD'
)


SELECT
    act.voucher_type
    , voucher_no
    , period
    , trans_date
    , act.account
    , a1.description AS dim1_attribute
    , act.dim_1
    , a2.description AS dim2_attribute
    , act.dim_2
    , a3.description AS dim3_attribute
    , act.dim_3
    , a4.description AS dim4_attribute
    , act.dim_4
    , a5.description AS dim5_attribute
    , act.dim_5
    , a6.description AS dim6_attribute
    , act.dim_6
    , a7.description AS dim7_attribute
    , act.dim_7
    , order_id
    , act.amount
    , value_1

FROM 
    agltransact act


LEFT JOIN attributesCTE a1 ON act.att_1_id = a1.attribute_id
LEFT JOIN attributesCTE a2 ON act.att_2_id = a2.attribute_id
LEFT JOIN attributesCTE a3 ON act.att_3_id = a3.attribute_id
LEFT JOIN attributesCTE a4 ON act.att_4_id = a4.attribute_id
LEFT JOIN attributesCTE a5 ON act.att_5_id = a5.attribute_id
LEFT JOIN attributesCTE a6 ON act.att_6_id = a6.attribute_id
LEFT JOIN attributesCTE a7 ON act.att_7_id = a7.attribute_id

WHERE
    (@StartPeriod IS NULL OR act.period >= @StartPeriod)
    AND (@EndPeriod IS NULL OR act.period <= @EndPeriod)
    AND (@Account IS NULL OR act.account = @Account)