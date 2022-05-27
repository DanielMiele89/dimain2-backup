-- =============================================
-- Author:		<Adam Scott>
-- Create date: <19/06/2014>
-- Description:	<Cumulative monthly split SUT_fetch>
-- =============================================

CREATE PROCEDURE [MI].[MonthlyRetailerSplitReportsCumulativeSUT_fetch] 
(@MonthID int, @PartnerID int)
AS
BEGIN
declare @startID int--, @MonthID int, @PartnerID int
--set @MonthID = 29
--set @PartnerID =3960
set @startID = (select StartMonthID from MI.SchemeMarginsAndTargets where PartnerID  = @PartnerID)


select	max(p.PartnerID) as PartnerID,
		MID.SplitID,
				Case when p.PartnerID =3960 then case when MID.StatusTypeID =1 then 1 else 2 end else  MID.StatusTypeID end as StatusTypeID,
		--BP.[StatusID],
		max(SUTM.ID) as MonthID,
		Sum(SUT.Amount)  as TranAmount,
		Count(*) as TranCount,
		count(DISTINCT SUT.FanID) as CustomerNo
		INTO #SUT
from warehouse.relational.[SchemeUpliftTrans] as SUT
inner join MI.[StagingCustomer_Cuml] as c	
	on SUT.FanID = c.FanID and Sut.PartnerID = C.PartnerID 
inner join warehouse.relational.Partner as p
	on SUT.PartnerID = p.PartnerID
inner join Relational.SchemeUpliftTrans_Month SUTM
on SUT.addeddate between SUTM.StartDate and SUTM.EndDate 
left join [MI].[ReportMID] MID 
on MID.OutletID = SUT.OutletID and (MID.EndDate is null or MID.EndDate >= SUTM.EndDate) and (MID.StartDate <= SUTM.EndDate)
and p.PartnerID = mid.PartnerID 

	
Where	SUT.IsRetailReport = 1 and
		SUT.Amount > 0 and 
		c.Labelid = 4 and
		p.PartnerID = mid.PartnerID and
		SUTM.ID between @startID and @MonthID and 
		p.PartnerID = @PartnerID and
		C.monthid = @MonthID
group by MID.SplitID,
				Case when p.PartnerID =3960 then case when MID.StatusTypeID =1 then 1 else 2 end else  MID.StatusTypeID end ,
		p.PartnerID


UPDATE   [Warehouse].[MI].[RetailerReportSplitMonthly]
SET      [ActivatedSpender] = SUT.CustomerNo,
		[ActivatedTrans] =SUT.TranCount,
		[ActivatedSales] = SUT.TranAmount
FROM [Warehouse].[MI].[RetailerReportSplitMonthly] SM
	inner join #SUT SUT on 
	SM.PartnerID = SUT.partnerid 
	and SM.Monthid = SUT.Monthid
	and SM.[Cumulative] = 1  
	And SM.SplitID = SUT.SplitID 
	and SM.StatusTypeID = SUT.StatusTypeID


Drop table #SUT


END


