-- =============================================
-- Author:		<Adam Scott>
-- Create date: <16/06/2014>
-- Description:	<Cumulative monthly SUT_fetch>
-- =============================================


CREATE PROCEDURE [MI].[MonthlyRetailerReportsCumulativeNONCoreSUT_fetch] 
(@MonthID int)
AS
BEGIN



select	max(p.PartnerID) as PartnerID,
		max(c.monthID) as MonthID,
		Sum(SUT.Amount)  as TranAmount,
		Count(*) as TranCount,
		count(DISTINCT SUT.FanID) as CustomerNo,
		C.ClientServicesRef
from warehouse.relational.[SchemeUpliftTrans] as SUT
inner join warehouse.relational.Partner as p
	on SUT.PartnerID = p.PartnerID
inner join Relational.SchemeUpliftTrans_Month SUTM
on SUT.addeddate between SUTM.startDate and SUTM.EndDate 
inner join [Warehouse].[MI].[StagingCustomer] as c
	on SUT.FanID = c.FanID and  P.PartnerID = C.PartnerID 
inner join  MI.SchemeMarginsAndTargets SMT
on SMT.PartnerID  = P.PartnerID and IsNonCore = 1 and @MonthID <= EndMonthID 

Where	SUT.IsRetailReport = 1 and
		SUT.Amount > 0 and 
		SUTM.ID between SMT.StartMonthID and @MonthID and 
		c.monthID = @MonthID and
		c.[LabelID] = 104 and 
		SUT.addeddate between SUTM.StartDate and C.EndDate
group by c.monthID, p.PartnerID, C.ClientServicesRef
order by c.monthID, C.ClientServicesRef
END