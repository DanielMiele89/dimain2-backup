-- =============================================
-- Author:		<Adam Scott>
-- Create date: <23/06/2014>
-- Description:	<Cumlative monthly Partner trans OnlineOffline_fetch>
-- =============================================
CREATE PROCEDURE [MI].[MonthlyRetailerReportsCumlitivenoCorePTOO_fetch] 
(@MonthID int, @PartnerID int)
AS
BEGIN

declare @startID int --,@MonthID int, @PartnerID int
--set @MonthID = 29
--set @PartnerID = 2396
set @startID = (select StartMonthID from MI.SchemeMarginsAndTargets where PartnerID  = @PartnerID)

select	isnull(max(p.PartnerID),0) as PartnerID,
		case when pt.isonline = 1 then 105 else 106 end as lableid,
		isnull(max(SUTM.ID),0) as MonthID,
		Sum(CASE WHEN EligibleForCashBack = 1 THEN CommissionChargable ELSE 0 END) AS Commission,
		Count(distinct PT.fanid) Customerno,
		ST.ClientServicesRef

from warehouse.relational.PartnerTrans as pt
inner join MI.SchemeMarginsAndTargets SMT
	on PT.PartnerID = SMT.PartnerID
inner join warehouse.relational.Partner as p
	on pt.PartnerID = p.PartnerID

inner join Relational.SchemeUpliftTrans_Month SUTM
	on pt.addeddate between SUTM.StartDate and SUTM.EndDate
inner join MI.[StagingCustomer] ST
	on ST.[FanID] = PT.Fanid  and P.PartnerID = ST.PartnerID 

Where	pt.[EligibleForCashBack] = 1 and
		TransactionAmount > 0 and 
		SUTM.ID between @startID and @MonthID and 
		p.PartnerID = @PartnerID and
		st.[LabelID] = 104 and
		ST.monthID = @MonthID
		and pt.addeddate between ST.StartDate and ST.EndDate
                                     and ((pt.TransactionDate >= ST.StartDate and ST.EndDate is null) or pt.TransactionDate between ST.StartDate and ST.EndDate)
group by  case when pt.isonline = 1 then 105 else 106 end, ST.monthID, p.PartnerID, ST.ClientServicesRef

END
