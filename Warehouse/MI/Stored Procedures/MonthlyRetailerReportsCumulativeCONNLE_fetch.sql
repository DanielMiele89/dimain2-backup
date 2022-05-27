-- =============================================
-- Author:		<Adam Scott>
-- Create date: <21/05/2014>
-- Description:	<Cumulative monthly SUT_fetch>
-- =============================================

CREATE PROCEDURE [MI].[MonthlyRetailerReportsCumulativeCONNLE_fetch] 
(@MonthID int, @PartnerID int, @CONPartnerID int) 
AS
BEGIN
SET NOCOUNT ON
Truncate table MI.Staging_SUT
--declare @MonthID int, @PartnerID int, @CONPartnerID int
--set @MonthID = 28 
--set @PartnerID = 3960
--set @CONPartnerID = 3960

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


select	p.PartnerID as PartnerID,
		case c.Labelid when 21 then 27 when 22 then 28 when 23 then 29 else 0 end as labelid,
		max(C.MonthID) as MonthID,
		Sum(SUT.Amount)  as ControlSales,
		Count(*) as ControlTrans,
		count(DISTINCT SUT.FanID) as ControlSpender
from MI.Staging_SUT as SUT
inner join [Warehouse].[MI].[StagingControl_NLE] as c	
	on SUT.FanID = c.FanID and c.PartnerID = sut.PartnerID
inner join warehouse.relational.Partner as p
	on SUT.PartnerID = p.PartnerID
--inner join Relational.SchemeUpliftTrans_Month SUTM
--on SUT.addeddate between SUTM.StartDate and SUTM.EndDate
Where	C.MonthID = @MonthID 
	and p.PartnerID = @PartnerID and C.PartnerID = @CONPartnerID and c.Labelid in (21,22,23) and
		SUT.Amount > 0
group by p.PartnerID, c.Labelid
END