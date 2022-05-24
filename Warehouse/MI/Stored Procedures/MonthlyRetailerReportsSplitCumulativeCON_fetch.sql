-- =============================================
-- Author:		<Adam Scott>
-- Create date: <21/05/2014>
-- Description:	<Cumulative monthly SUT_fetch>
-- =============================================


Create PROCEDURE [MI].[MonthlyRetailerReportsSplitCumulativeCON_fetch] 
(@MonthID int, @PartnerID int, @CONPartnerID int) 
AS
BEGIN
SET NOCOUNT ON
Truncate table MI.Staging_SUT
declare @startID int --,@MonthID int, @PartnerID int, @CONPartnerID int
--set @MonthID = 29
--set @PartnerID =3960 
--set @CONPartnerID =3960
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



select	max(p.PartnerID) as PartnerID,
		MID.SplitID,
		Case when p.PartnerID =3960 then case when MID.StatusTypeID =1 then 1 else 2 end else  MID.StatusTypeID end as StatusTypeID,
		max(CON.MonthID) as MonthID,
		Sum(SUT.Amount) as TranAmount,
		Count(*) as TranCount,
		count(DISTINCT SUT.FanID) as CustomerNo
from MI.Staging_SUT as SUT 
inner join warehouse.relational.Partner as p
	on SUT.PartnerID = p.PartnerID
inner join Relational.Control_Stratified CON 
on CON.fanID = SUT.fanID 
inner join [MI].[ReportMID] MID
on MID.OutletID = SUT.OutletID and (MID.EndDate is null or MID.EndDate >= SUT.SUTMEndDate) and (MID.StartDate <= SUT.SUTMEndDate)
and p.PartnerID = mid.PartnerID 
inner join MI.SchemeMarginsAndTargets SMT
	on SUT.PartnerID = SMT.PartnerID
Where	CON.MonthID = @MonthID 
	and p.PartnerID = @PartnerID and CON.PartnerID = @CONPartnerID and 
		SUT.Amount > 0
group by MID.SplitID,
		Case when p.PartnerID =3960 then case when MID.StatusTypeID =1 then 1 else 2 end else  MID.StatusTypeID end,
		p.PartnerID
END
