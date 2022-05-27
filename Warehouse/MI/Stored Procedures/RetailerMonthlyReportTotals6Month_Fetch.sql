-- =============================================
-- Author:		<Adam Scott>
-- Create date: <17/04/2014>
-- Description:	<Gets 6 Month>
-- Edited : 12/08/2014 BY AJS
-- =============================================
CREATE PROCEDURE [MI].[RetailerMonthlyReportTotals6Month_Fetch]
	-- Add the parameters for the stored procedure here
(@MonthID int, @PartnerID int)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
Declare @LabelID as INT, @LowerMonth as int--, @MonthID as int, @PartnerID as int
set @LabelID = 1
--Set @monthid =31
--set @PartnerID = 4478
set @LowerMonth = @MonthID-5


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
where [MonthID] <= @MonthID and [MonthID] >= 20 and [MonthID] >= @LowerMonth
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
	  into #Results
  FROM [Warehouse].[MI].[RetailerReportMonthly] RM
  inner join #weektotals WT on WT.monthid = RM.MonthID and WT.PartnerID = RM.PartnerID and RM.[LabelID] = wt.[LabelID]
  inner join Relational.SchemeUpliftTrans_Month SUTM  on SUTM.id = RM.MonthID
  inner join Relational.SchemeUpliftTrans_Quarter SUTQ on SUTQ.ID = SUTM.QuarterID
  left join [Warehouse].[MI].[SchemeMarginsAndTargets] SMT on RM.PartnerID = SMT.PartnerID 
where RM.[MonthID] <= @MonthID and  RM.[MonthID] >= 20 and RM.[MonthID] >= @LowerMonth and
   RM.[LabelID] = @LabelID
  and RM.[PartnerID] = @PartnerID


Select sutm.id AS MonthID,
SUTM.QuarterID AS QuarterID,
SUTQ.QuarterName AS QuarterName,
SUTM.MonthDesc AS MonthDesc,
R.NewActivatedCardholders AS NewActivatedCardholders,
ISNULL(R.DeactivatedCustomersInMonth,0 ) AS DeactivatedCustomersInMonth,
ISNULL(R.ActivatedSales,0 ) AS ActivatedSales,
R.PostActivatedSales AS PostActivatedSales,
ISNULL(R.PreActivationSales,0 ) AS PreActivationSales,
ActivatedTrans AS ActivatedTrans,
PostActivatedTrans AS PostActivatedTrans,
ActivatedCommission AS ActivatedCommission,
ControlSales AS ControlSales,
ISNULL(R.ControlTrans,0 ) AS ControlTrans,
ISNULL(R.LabelID,0 ) AS LabelID,
ISNULL(R.PartnerID,0 ) AS PartnerID,
ISNULL(R.PartnerGroupID,0 ) AS PartnerGroupID,
R.ActivatedCardholders AS ActivatedCardholders,
R.ActivatedSpender AS ActivatedSpender,
R.ControlCardholder  AS ControlCardholder,
R.ControlSpender  AS ControlSpender,
ISNULL(R.AdjFactorSPC,0 ) AS AdjFactorSPC,
ISNULL(R.AdjFactorRR,0 ) AS AdjFactorRR,
ISNULL(R.AdjFactorSPS,0 ) AS AdjFactorSPS,
ISNULL(R.AdjFactorATV,0 ) AS AdjFactorATV,
ISNULL(R.AdjFactorATF,0 ) AS AdjFactorATF,
IncrementalSales AS IncrementalSales,
R.IncrementalTrans AS IncrementalTrans,
R.IncrementalSpenders AS IncrementalSpenders,
R.CumulativeIncrementalSpenders AS CumulativeIncrementalSpenders,
R.PostActivatedSpender AS PostActivatedSpender,
ISNULL(R.RewardTargetUplift,0 ) AS RewardTargetUplift,
ISNULL(R.ContractTargetUplift,0 ) AS ContractTargetUplift,
ISNULL(R.ContractROI,0 ) AS ContractROI,
ISNULL(R.margin,0 ) AS margin,
ISNULL(R.SchemeNotesCustomTargets,0 ) AS SchemeNotesCustomTargets
from [Warehouse].[Relational].[SchemeUpliftTrans_Month] SUTM
inner join  [Warehouse].[Relational].[SchemeUpliftTrans_Quarter] SUTQ on SUTQ.ID = SUTM.QuarterID
Left join #Results r on R.MonthID = SUTM.ID
where Sutm.id between @LowerMonth and @MonthID

--Select * from #Results
--select * from  #weektotals
--  select * from tempdb.sys.columns where object_id =
--object_id('tempdb..#Results')
   drop table #weektotals
   DRop Table #Results
END
