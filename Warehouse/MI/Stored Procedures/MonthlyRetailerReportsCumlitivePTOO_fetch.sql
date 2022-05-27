-- =============================================
-- Author:		<Adam Scott>
-- Create date: <22/05/2014>
-- Description:	<Cumlative monthly Partner trans OnlineOffline_fetch>
-- =============================================
CREATE PROCEDURE [MI].[MonthlyRetailerReportsCumlitivePTOO_fetch] 
(@MonthID int, @PartnerID int)
AS
BEGIN

declare @startID int 
set @startID = (select StartMonthID from MI.SchemeMarginsAndTargets where PartnerID  = @PartnerID)

select	isnull(max(p.PartnerID),0) as PartnerID,
		case when pt.isonline = 1 then 5 else 6 end as lableid,
		isnull(max(SUTM.ID),0) as MonthID,
		Sum(CASE WHEN EligibleForCashBack = 1 THEN CommissionChargable ELSE 0 END) AS Commission,
		Count(distinct PT.fanid) Customerno

from warehouse.relational.PartnerTrans as pt
inner join MI.SchemeMarginsAndTargets SMT
	on PT.PartnerID = SMT.PartnerID
inner join warehouse.relational.Partner as p
	on pt.PartnerID = p.PartnerID

inner join Relational.SchemeUpliftTrans_Month SUTM
	on pt.addeddate between SUTM.StartDate and SUTM.EndDate
inner join MI.[StagingCustomer_Cuml] ST
	on ST.[FanID] = PT.Fanid  and P.PartnerID = ST.PartnerID 

Where	pt.[EligibleForCashBack] = 1 and		
		TransactionAmount > 0 and 
		SUTM.ID between @startID and @MonthID and 
		p.PartnerID = @PartnerID and
		st.[LabelID] = 4 and
		St.monthid = @MonthID and 
		pt.matchid not in (145665307,
		145665308,
		145665309,
		145665310,
		145665311,
		145665312,
		145665313,
		145665314,
		145665315)
group by  case when pt.isonline = 1 then 5 else 6 end

END
