CREATE PROCEDURE [Reporting].[MissingTrans_Transaction]
AS
BEGIN
	
	SET NOCOUNT ON;

select war.*,
slc.PartnerID,
case when slcp.Name like '%(%' then LEFT(slcp.Name, CHARINDEX('(',slcp.Name)-1) else slcp.Name end as [Name]
from WH_Warba.inbound.[Transaction] war
left join SLC_REPL.dbo.Retailoutlet slc on 
slc.MerchantID = war.MerchantID
left join SLC_REPL.dbo.[Partner] slcp on
slc.PartnerID = slcp.ID
where DATEADD(MONTH, -6, GETDATE()) <= war.transactiondate


END;