CREATE PROCEDURE Prototype.SH_PubDates 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
select distinct CLubname
,brandID
,FirstTrandate
from warehouse.Prototype.ROCP2_NFiPubdates p
inner join warehouse.insightarchive.nFIpartnerdeals pd on p.PartnerID = pd.PartnerID 
where	p.PartnerID not in (4523)
END
