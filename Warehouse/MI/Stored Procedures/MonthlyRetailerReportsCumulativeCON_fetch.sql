-- =============================================
-- Author:		<Adam Scott>
-- Create date: <21/05/2014>
-- Description:	<Cumulative monthly SUT_fetch>
-- =============================================


CREATE PROCEDURE [MI].[MonthlyRetailerReportsCumulativeCON_fetch] 
(@MonthID int, @PartnerID int, @CONPartnerID int) 
AS
BEGIN
SET NOCOUNT ON
Truncate table MI.Staging_SUT
declare @startID int 
set @startID = (select StartMonthID from MI.SchemeMarginsAndTargets where PartnerID  = @PartnerID)

DROP INDEX FanID ON MI.Staging_SUT
DROP INDEX Amount ON MI.Staging_SUT

insert into MI.Staging_SUT 
select Partnerid, SUT1.FanID, sut1.Amount, SUT1.isonline, sut1.OutletID, SUTM1.EndDate

From [Warehouse].[Relational].[SchemeUpliftTrans] sut1
inner join Relational.SchemeUpliftTrans_Month SUTM1
	on SUT1.addeddate between SUTM1.StartDate and SUTM1.EndDate 
where SUT1.PartnerID = @PartnerID and SUTM1.ID between @startID and @MonthID and SUT1.IsRetailReport = 1 

CREATE INDEX FanID
ON MI.Staging_SUT(FanID)

CREATE INDEX Amount
ON MI.Staging_SUT(Amount)


select	isnull(max(p.PartnerID),0) as PartnerID,
		isnull(max(CON.MonthID),0) as MonthID,
		count(DISTINCT SUT.FanID) as CustomerNo
from MI.Staging_SUT as SUT
inner join MI.SchemeMarginsAndTargets SMT
	on SUT.PartnerID = SMT.PartnerID
inner join warehouse.relational.Partner as p
	on SUT.PartnerID = p.PartnerID
inner join Relational.Control_Stratified CON
--inner join Warehouse.MI.halfords_control_backup CON ----------------------------------******************************halfords commet out 
on CON.fanID = SUT.fanID 
--inner join Relational.SchemeUpliftTrans_Month SUTM
--	on SUT.addeddate between SUTM.StartDate and SUTM.EndDate and SUTM.ID between @startID and CON.MonthID
Where	CON.MonthID = @MonthID 
	and p.PartnerID = @PartnerID and CON.PartnerID = @CONPartnerID and
		SUT.Amount > 0




END