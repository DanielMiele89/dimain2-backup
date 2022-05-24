-- =============================================
-- Author:		<Adam Scott>
-- Create date: <15/07/2014>
-- Description:	<Cumlative monthly Partner trans_fetch for virtual partners>
-- =============================================
Create PROCEDURE [MI].[MonthlyRetailerReportsCumlitiveVPT_fetch] 
(@MonthID int, @PartnerID int)
AS
BEGIN
declare @startID int 
--, @MonthID int, @PartnerID int
--set @PartnerID = 3960 
--set @MonthID = 30
set @startID = (select StartMonthID from MI.SchemeMarginsAndTargets where  VirtualPartnerID = @PartnerID)
select	max(VP.DisplayPartnerid) as PartnerID,
		isnull(max(SUTM.ID),0) as MonthID,
		--Sum(TransactionAmount)  as TranAmount,
		--Count(*) as TranCount,
		--Sum(CASE WHEN EligibleForCashBack = 1 THEN CommissionChargable ELSE 0 END) AS Commission,
		count(DISTINCT PT.FanID) as CustomerNo,
		--,((Fields!PostActivatedSales.Value/Fields!ActivatedCardholders.Value)-((Fields!ControlSales.Value*(Fields!AdjFactorSPC.Value))/Fields!ControlCardholder.Value))*Fields!ActivatedCardholders.Value
		MAX(VP.PartnerGroupID) as PartnerGroupID,
		MAX(VP.VirtualPartnerID) as VirtualPartnerID
from warehouse.relational.PartnerTrans as pt
inner join MI.SchemeMarginsAndTargets SMT
	on PT.PartnerID = SMT.VirtualPartnerID
inner join warehouse.relational.Partner as p
	on pt.PartnerID = p.PartnerID
inner join Relational.SchemeUpliftTrans_Month SUTM
	on pt.addeddate between SUTM.StartDate  and  SUTM.EndDate  
inner join MI.[StagingCustomer_Cuml] ST
	on ST.[FanID] = PT.Fanid and SMT.PartnerID = ST.PartnerID
inner join Mi.VirtualPartner VP
	on P.PartnerID = VP.PartnerID



Where	pt.[EligibleForCashBack] = 1 and		
		TransactionAmount > 0 and 
		SUTM.ID between @startID and @MonthID and 
		VP.VirtualPartnerID  =  @PartnerID and
		st.[LabelID] = 4 and
		St.monthid = @MonthID and 
		P.PartnerID is not null
END
