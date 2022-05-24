-- =============================================
-- Author:		<Adam Scott>
-- Create date: <23/06/2014>
-- Description:	<Cumulative monthly SUTOO_fetch>
-- =============================================


CREATE PROCEDURE [MI].[MonthlyRetailerReportsCumulativeNONCoreSUTOO_fetch] 
(@MonthID int, @PartnerID int)
AS
BEGIN
--declare @MonthID as int, @PartnerID int
--set @MonthID =30
--Set @PartnerID = 3730

declare @startID int 
set @startID = (select StartMonthID from MI.SchemeMarginsAndTargets where PartnerID  = @PartnerID)


select	isnull(max(p.PartnerID),0) as PartnerID,
		case when SUT.isonline = 1 then 105 else 106 end as lableid,
		isnull(max(SUTM.ID),0) as MonthID,
		Sum(SUT.Amount)  as TranAmount,
		Count(*) as TranCount,
		count(DISTINCT SUT.FanID) as CustomerNo
		, ST.ClientServicesRef
from warehouse.relational.[SchemeUpliftTrans] as SUT
inner join MI.SchemeMarginsAndTargets SMT
	on SUT.PartnerID = SMT.PartnerID
inner join warehouse.relational.Partner as p
	on SUT.PartnerID = p.PartnerID
inner join Relational.SchemeUpliftTrans_Month SUTM
on SUT.addeddate between SUTM.startDate and SUTM.EndDate
inner join MI.[StagingCustomer] ST
	on ST.[FanID] = SUT.Fanid and SMT.PartnerID = ST.PartnerID 
	
Where	SUT.IsRetailReport = 1 and
		SUT.Amount > 0 and 
		SUTM.ID between @startID and @MonthID and 
		p.PartnerID = @PartnerID and
		st.[LabelID] = 104 and
		St.monthid = @MonthID

group by case when SUT.isonline = 1 then 105 else 106 end, ST.ClientServicesRef

END