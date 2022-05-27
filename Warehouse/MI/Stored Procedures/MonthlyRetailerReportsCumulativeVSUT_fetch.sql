-- =============================================
-- Author:		<Adam Scott>
-- Create date: <21/05/2014>
-- Description:	<Cumulative monthly SUT_fetch>
-- =============================================


Create PROCEDURE [MI].[MonthlyRetailerReportsCumulativeVSUT_fetch] 
(@MonthID int, @PartnerID int)
AS
BEGIN
declare @startID int 
--, @MonthID int, @PartnerID int
--set @PartnerID = 3960 
--set @MonthID = 30
set @startID = (select StartMonthID from MI.SchemeMarginsAndTargets where PartnerID  = @PartnerID)




select	isnull(max(VP.DisplayPartnerid),0) as PartnerID,
		isnull(max(SUTM.ID),0) as MonthID,
		--Sum(SUT.Amount)  as TranAmount,
		--Count(*) as TranCount,
		count(DISTINCT SUT.FanID) as CustomerNo,
		MAX(VP.PartnerGroupID) as PartnerGroupID,
		MAX(VP.VirtualPartnerID) as VirtualPartnerID
from warehouse.relational.[SchemeUpliftTrans] as SUT
inner join MI.SchemeMarginsAndTargets SMT
	on SUT.PartnerID = SMT.PartnerID
inner join warehouse.relational.Partner as p
	on SUT.PartnerID = p.PartnerID
inner join Relational.SchemeUpliftTrans_Month SUTM
on SUT.addeddate between SUTM.startDate and SUTM.EndDate 
inner join MI.[StagingCustomer_Cuml] ST
	on ST.[FanID] = SUT.Fanid and SMT.PartnerID = ST.PartnerID 
inner join Mi.VirtualPartner VP
	on P.PartnerID = VP.PartnerID
Where	SUT.IsRetailReport = 1 and
		SUT.Amount > 0 and 
		SUTM.ID between @startID and @MonthID and 
		VP.VirtualPartnerID = @PartnerID and
		st.[LabelID] = 4 and
		St.monthid = @MonthID
END