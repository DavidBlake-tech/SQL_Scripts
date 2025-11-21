select *
from awflock where oid in (
select oid
from acrtransmap 
where voucher_no='6820477' )

--Then run this to unlock them:
 
 
begin transaction 
update awflock
set lock_expiry=getdate()
where oid in
(
select oid
from acrtransmap 
where voucher_no='6138823'
)
-- rollback                   commit transaction