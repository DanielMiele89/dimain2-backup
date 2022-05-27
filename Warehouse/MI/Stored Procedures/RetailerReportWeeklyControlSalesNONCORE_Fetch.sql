-- =============================================
-- Author:		AJS
-- Create date: 10/01/2014
-- Description:	fetches all Control sales for NONCORE RETAILERS For Whom a Stratified Control Exists
-- =============================================
CREATE PROCEDURE [MI].[RetailerReportWeeklyControlSalesNONCORE_Fetch]

( @Monthid as int )
AS
BEGIN
	SET NOCOUNT ON;

	SELECT 
	  Ir.PartnerID, Min(IR.StartDate) as StartDate, MAX(IR.EndDate) as EndDate
	  into #ActiveOffers
  FROM  [Warehouse].[Relational].[IronOffer] IR
  inner join Warehouse.Relational.SchemeUpliftTrans_Month SUTM on SUTM.EndDate >= IR.StartDate and SUTM.StartDate <= IR.EndDate
  where SUTM.ID = @Monthid and IR.IronOfferID not in  (1647, 1799) 
  group by 
  Ir.PartnerID
 
select	max(p.PartnerID) as PartnerID,
		max(SUTW.ID) as WeekID,
		Sum(SUT.Amount) as TranAmount,
		Count(*) as TranCount,
		count(DISTINCT SUT.FanID) as CustomerNo

from[Warehouse].[Relational].[SchemeUpliftTrans] as SUT
inner join warehouse.relational.Partner as p
	on SUT.PartnerID = p.PartnerID
inner join Relational.Control_Stratified CON 
	on CON.fanID = SUT.fanID and p.PartnerID = CON.PartnerID 
inner join Relational.SchemeUpliftTrans_Week SUTW
	on SUT.addeddate between SUTW.StartDate and SUTW.EndDate
inner join Relational.SchemeUpliftTrans_Month SUTM
	on SUTW.[MonthID]= SUTM.id and CON.MonthID = SUTM.ID 
inner join #ActiveOffers AO 
	on AO.PartnerID = P.PartnerID and SUT.AddedDate >= AO.StartDate and SUT.AddedDate <= AO.EndDate

Where	CON.MonthID = @Monthid    and
		SUT.Amount > 0 and SUT.IsRetailReport = 1 
Group by SUTW.StartDate, p.PartnerID
order by SUTW.StartDate

drop table #ActiveOffers



END
