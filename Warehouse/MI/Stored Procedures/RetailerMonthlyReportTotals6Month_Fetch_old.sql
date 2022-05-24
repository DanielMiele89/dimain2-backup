-- =============================================
-- Author:		<Adam Scott>
-- Create date: <17/04/2014>
-- Description:	<Gets 6 Month>
-- =============================================
CREATE PROCEDURE MI.[RetailerMonthlyReportTotals6Month_Fetch_old]
	-- Add the parameters for the stored procedure here
(@MonthID int, @PartnerID int)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
Declare @LabelID as INT, @LowerMonth as int
set @LabelID = 1
set @LowerMonth = @MonthID-6

SELECT 

	monthID 
	,@PartnerID as PartnerID
	,[LabelID]
      ,SUM(RW.[NewActivatedCardholders]) as [NewActivatedCardholders]
      ,sum(RW.[DeactivatedCustomersInMonth]) as [DeactivatedCustomersInMonth]
      ,Sum(RW.[ActivatedSales]) as [ActivatedSales]
      ,sum(RW.[PostActivatedSales]) as [PostActivatedSales]
      ,Sum(RW.[PreActivationSales]) as [PreActivationSales]
      ,Sum(RW.[ActivatedTrans]) as [ActivatedTrans]
      ,sum(RW.[PostActivatedTrans]) as [PostActivatedTrans]
      ,sum(RW.[ActivatedCommission]) as [ActivatedCommission]
      ,sum(RW.[ControlCardholder]) as [ControlCardholder]
      ,sum(RW.[ControlSales]) as [ControlSales]
      ,sum(RW.[ControlTrans]) as [ControlTrans]
	  into #weektotals
  FROM [MI].[RetailerReportWeekly] RW
where [MonthID] <= @MonthID and [MonthID] >= 20 and [MonthID] > @LowerMonth
  and [LabelID] = @LabelID
  and [PartnerID] = @PartnerID
  group by [LabelID], monthID 

---- select * from #weektotals

SELECT 
 wt.[NewActivatedCardholders]
      ,wt.[DeactivatedCustomersInMonth]
      ,wt.[ActivatedSales]
      ,wt.[PostActivatedSales]
      ,wt.[PreActivationSales]
      ,wt.[ActivatedTrans]
      ,wt.[PostActivatedTrans]
      --,wt.[ActivatedCommission]
	  ,case when RM.PartnerID <> 3960 then wt.ActivatedCommission else (case when RM.IncrementalSales > 0 then RM.IncrementalSales * 0.025 else 0 end) end as ActivatedCommission
      --,wt.[ControlCardholder]
      ,wt.[ControlSales]
      ,wt.[ControlTrans]
	  ,RM.[ID]
      ,RM.[MonthID]
      ,RM.[LabelID]
      ,RM.[PartnerID]
      ,RM.[PartnerGroupID]
      ,RM.[ActivatedCardholders]
      ,RM.[ActivatedSpender]
      ,RM.[ControlCardholder]
      ,RM.[ControlSpender]
      ,RM.[AdjFactorSPC]
      ,RM.[AdjFactorRR]
      ,RM.[AdjFactorSPS]
      ,RM.[AdjFactorATV]
      ,RM.[AdjFactorATF]
      --,RM.[Label]
      --,RM.[MonthlyAVG]
      --,RM.[MonthlySTDEV]
      --,RM.[ActivatedTrans]
      --,RM.[ActivatedSales]
	,RM.[IncrementalSales]
	,SUTM.QuarterID
	,SUTQ.[QuarterName]
	,SUTM.[MonthDesc]
	  ,RM.[IncrementalTrans]
      ,RM.[IncrementalSpenders]
      ,RM.[CumulativeIncrementalSpenders]
	,RM.[PostActivatedSpender]
	,SMT.RewardTargetUplift
	,SMT.[ContractTargetUplift]
	,SMT.[ContractROI]
	,SMT.margin
	,SMT.[SchemeNotesCustomTargets]
  FROM [Warehouse].[MI].[RetailerReportMonthly] RM
  inner join #weektotals WT on WT.monthid = RM.MonthID and WT.PartnerID = RM.PartnerID and RM.[LabelID] = wt.[LabelID]
  inner join Relational.SchemeUpliftTrans_Month SUTM  on SUTM.id = RM.MonthID
  inner join Relational.SchemeUpliftTrans_Quarter SUTQ on SUTQ.ID = SUTM.QuarterID
  left join [Warehouse].[MI].[SchemeMarginsAndTargets] SMT on RM.PartnerID = SMT.PartnerID 
where RM.[MonthID] <= @MonthID and  RM.[MonthID] >= 20 and RM.[MonthID] > @LowerMonth and
   RM.[LabelID] = @LabelID
  and RM.[PartnerID] = @PartnerID
   drop table #weektotals
END