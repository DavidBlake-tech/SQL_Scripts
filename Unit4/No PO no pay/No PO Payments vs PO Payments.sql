SELECT 
    * 
FROM 
    agltransact
WHERE   
    voucher_type in ('IP', 'ch')
    AND period > '202500'