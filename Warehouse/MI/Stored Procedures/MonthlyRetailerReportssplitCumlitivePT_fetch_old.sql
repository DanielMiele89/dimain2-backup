-- =============================================
-- Author:		<Adam Scott>
-- Create date: <21/05/2014>
-- Description:	<Cumlative monthly Partner trans_fetch>
-- =============================================
Create PROCEDURE [MI].[MonthlyRetailerReportssplitCumlitivePT_fetch_old] 
(@MonthID int, @PartnerID int)
AS
BEGIN
declare @startID int --, @MonthID int, @PartnerID int
--set @MonthID = 29
--set @PartnerID =3960 
set @startID = (select StartMonthID from MI.SchemeMarginsAndTargets where PartnerID  = @PartnerID)
select	max(pt.PartnerID) as PartnerID,
		MID.SplitID,
				Case when pt.PartnerID =3960 then case when MID.StatusTypeID =1 then 1 else 2 end else  MID.StatusTypeID end as StatusTypeID,

		@MonthID as MonthID,
		--max(SUTM.ID) as MonthID,
		Sum(TransactionAmount)  as TranAmount,
		Count(*) as TranCount,
		Sum(CASE WHEN EligibleForCashBack = 1 THEN CommissionChargable ELSE 0 END) AS Commission,
		count(DISTINCT PT.FanID) as CustomerNo
from warehouse.relational.PartnerTrans as pt
inner join MI.SchemeMarginsAndTargets SMT
	on PT.PartnerID = SMT.PartnerID
inner join warehouse.relational.Partner as p
	on pt.PartnerID = p.PartnerID
inner join Relational.SchemeUpliftTrans_Month SUTM
	on pt.addeddate between SUTM.StartDate  and  SUTM.EndDate  
inner join MI.[StagingCustomer_Cuml] ST
	on ST.[FanID] = PT.Fanid and SMT.PartnerID = ST.PartnerID 
inner join [MI].[ReportMID] MID
	on MID.OutletID = PT.OutletID and (MID.EndDate is null or MID.EndDate >= SUTM.EndDate) and (MID.StartDate <= SUTM.EndDate)
and p.PartnerID = mid.PartnerID 




Where	pt.[EligibleForCashBack] = 1 and		
		TransactionAmount > 0 and 
		SUTM.ID between @startID and @MonthID and 
		SMT.PartnerID = @PartnerID and
		st.[LabelID] = 4 and
		St.monthid = @MonthID and 
		Pt.PartnerID is not null
		group by MID.SplitID,
	Case when pt.PartnerID =3960 then case when MID.StatusTypeID =1 then 1 else 2 end else  MID.StatusTypeID end,
		pt.PartnerID
END
