-- =============================================
-- Author:		<Adam Scott>
-- Create date: <21/05/2014>
-- Description:	<Cumlative monthly Partner CumlitivePTNLE_fetch>
-- =============================================
CREATE PROCEDURE [MI].[MonthlyRetailerReportsCumlitivePTNLE_fetch] 
(@MonthID int, @PartnerID int)
AS
BEGIN
declare @startID int 
set @startID = (select StartMonthID from MI.SchemeMarginsAndTargets where PartnerID  = @PartnerID)
select	p.PartnerID as PartnerID,
		case c.Labelid when 27 then 27 when 28 then 28 when 29 then 29 else 0 end as labelid,
		Max(SUTM.ID) as MonthID,
		Sum(TransactionAmount)  as PostActivatedSales,
		Count(*) as [PostActivatedTrans],
		count(DISTINCT PT.FanID) as PostActivatedSpender
from warehouse.relational.PartnerTrans as pt
inner join [Warehouse].[MI].[StagingCustomer_NLE] as c	
	on pt.FanID = c.FanID and c.PartnerID = Pt.PartnerID
inner join warehouse.relational.Partner as p
	on pt.PartnerID = p.PartnerID and c.PartnerID = P.PartnerID
inner join Relational.SchemeUpliftTrans_Month SUTM
on PT.addeddate between SUTM.StartDate and SUTM.EndDate


Where	PT.TransactionAmount > 0 and 
		c.Labelid in (27,28,29) and
		pt.[EligibleForCashBack] = 1 and
		SUTM.ID between  @startID and @MonthID
and p.PartnerID = @PartnerID 
and c.Monthid = @MonthID	and	pt.matchid not in (145665307,
		145665308,
		145665309,
		145665310,
		145665311,
		145665312,
		145665313,
		145665314,
		145665315)

group by p.PartnerID,c.Labelid
END
