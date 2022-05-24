-- =============================================
-- Author:		<Adam Scott>
-- Create date: <21/05/2014>
-- Description:	<Cumulative monthly SUT_fetch>
-- Edited by AJS on 16/07/2014
-- =============================================


CReate PROCEDURE [MI].[MonthlyRetailerReportsCumulativeVCONOO_fetch] 
(@MonthID int, @PartnerID int, @CONPartnerID int) 
AS
BEGIN
SET NOCOUNT ON -- needed so ssis does not get confused
Truncate table MI.Staging_SUT

declare @startID int 
--, @MonthID as int, @PartnerID as int, @CONPartnerID as int
--set @MonthID =29
--set @PartnerID =3996
--set @CONPartnerID =0
set @startID = (select StartMonthID from MI.SchemeMarginsAndTargets where PartnerID  = @PartnerID)

DROP INDEX FanID ON MI.Staging_SUT
DROP INDEX Amount ON MI.Staging_SUT

insert into MI.Staging_SUT 
select Partnerid, SUT1.FanID, sut1.Amount, isonline, [OutletID]
      ,'01-01-2030' as [sutmEndDate]

From [Warehouse].[Relational].[SchemeUpliftTrans] sut1
inner join Relational.SchemeUpliftTrans_Month SUTM1
	on SUT1.addeddate between SUTM1.StartDate and SUTM1.EndDate 
where SUT1.PartnerID = @PartnerID and SUTM1.ID between @startID and @MonthID and SUT1.IsRetailReport = 1 

CREATE INDEX FanID
ON MI.Staging_SUT(FanID)

CREATE INDEX Amount
ON MI.Staging_SUT(Amount)



select	isnull(max(VP.DisplayPartnerid),0) as PartnerID,
		case when SUT.isonline = 1 then 5 else 6 end as lableid,
		isnull(max(CON.MonthID),0) as MonthID,
		--Max(CON.PartnerID) as p, 
		--Sum(SUT.Amount) as TranAmount,
		--Count(*) as TranCount,
		count(DISTINCT SUT.FanID) as CustomerNo,
		MAX(VP.PartnerGroupID) as PartnerGroupID,
		MAX(VP.VirtualPartnerID) as VirtualPartnerID
from MI.Staging_SUT as SUT

inner join MI.SchemeMarginsAndTargets SMT
	on SUT.PartnerID = SMT.PartnerID
inner join warehouse.relational.Partner as p
	on SUT.PartnerID = p.PartnerID
inner join Relational.Control_Stratified CON 
on CON.fanID = SUT.fanID 
--inner join Relational.SchemeUpliftTrans_Month SUTM
--	on SUT.addeddate between SUTM.StartDate and SUTM.EndDate and SUTM.ID between @startID and CON.MonthID
inner join Mi.VirtualPartner VP 
	on P.PartnerID = VP.PartnerID
Where	CON.MonthID = @MonthID and VP.VirtualPartnerID = @PartnerID and CON.PartnerID = @CONPartnerID and
		SUT.Amount > 0
group by case when SUT.isonline = 1 then 5 else 6 end

END