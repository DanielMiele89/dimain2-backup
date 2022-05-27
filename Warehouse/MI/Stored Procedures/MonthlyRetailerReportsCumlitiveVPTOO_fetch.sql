-- =============================================
-- Author:		<Adam Scott>
-- Create date: <22/05/2014>
-- Description:	<Cumlative monthly Partner trans OnlineOffline_fetch>
-- =============================================
Create PROCEDURE [MI].[MonthlyRetailerReportsCumlitiveVPTOO_fetch] 
(@MonthID int, @PartnerID int)
AS
BEGIN
--declare @MonthID int, @PartnerID int
--set @MonthID = 30
--set @PartnerID =3996

declare @startID int 
set @startID = (select StartMonthID from MI.SchemeMarginsAndTargets where PartnerID  = @PartnerID)

select	isnull(max(VP.DisplayPartnerid),0) as PartnerID,
		case when pt.isonline = 1 then 5 else 6 end as lableid,
		isnull(max(SUTM.ID),0) as MonthID,
		Sum(CASE WHEN EligibleForCashBack = 1 THEN CommissionChargable ELSE 0 END) AS Commission,
		Count(distinct PT.fanid) Customerno,
		MAX(VP.PartnerGroupID) as PartnerGroupID,
		MAX(VP.VirtualPartnerID) as VirtualPartnerID

from warehouse.relational.PartnerTrans as pt
inner join MI.SchemeMarginsAndTargets SMT
	on PT.PartnerID = SMT.PartnerID
inner join warehouse.relational.Partner as p
	on pt.PartnerID = p.PartnerID

inner join Relational.SchemeUpliftTrans_Month SUTM
	on pt.addeddate between SUTM.StartDate and SUTM.EndDate
inner join MI.[StagingCustomer_Cuml] ST
	on ST.[FanID] = PT.Fanid  and P.PartnerID = ST.PartnerID 
inner join Mi.VirtualPartner VP 
	on P.PartnerID = VP.PartnerID

Where	pt.[EligibleForCashBack] = 1 and		
		TransactionAmount > 0 and 
		SUTM.ID between @startID and @MonthID and 
		st.[LabelID] = 4 and
		St.monthid = @MonthID and
		VP.VirtualPartnerID = @Partnerid
group by  case when pt.isonline = 1 then 5 else 6 end



END
