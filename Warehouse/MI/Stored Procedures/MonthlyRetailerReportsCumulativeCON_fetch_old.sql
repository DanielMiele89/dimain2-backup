-- =============================================
-- Author:		<Adam Scott>
-- Create date: <21/05/2014>
-- Description:	<Cumulative monthly SUT_fetch>
-- =============================================


CREATE PROCEDURE [MI].[MonthlyRetailerReportsCumulativeCON_fetch_old] 
(@MonthID int, @PartnerID int, @CONPartnerID int) 
AS
BEGIN
declare @startID int 
set @startID = (select StartMonthID from MI.SchemeMarginsAndTargets where PartnerID  = @PartnerID)

select	isnull(max(p.PartnerID),0) as PartnerID,
		isnull(max(SUTM.ID),0) as MonthID,
		count(DISTINCT SUT.FanID) as CustomerNo
from[Warehouse].[Relational].[SchemeUpliftTrans] as SUT
inner join MI.SchemeMarginsAndTargets SMT
	on SUT.PartnerID = SMT.PartnerID
inner join warehouse.relational.Partner as p
	on SUT.PartnerID = p.PartnerID
inner join Relational.Control_Stratified CON 
on CON.fanID = SUT.fanID 
inner join Relational.SchemeUpliftTrans_Month SUTM
	on SUT.addeddate between SUTM.StartDate and SUTM.EndDate and SUTM.ID between @startID and CON.MonthID
Where	CON.MonthID = @MonthID 
	and p.PartnerID = @PartnerID and CON.PartnerID = @CONPartnerID and SUT.IsRetailReport = 1 and
		SUT.Amount > 0

END