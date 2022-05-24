-- =============================================
-- Author:		<Adam J Scott>
-- Create date: <10/04/2014>
-- Description:	<Fetches data from month and week tables for monthly reports by retailer>
-- =============================================
CREATE PROCEDURE [MI].[RetailerMonthlyReport_Fetch]
	-- Add the parameters for the stored procedure here
(@MonthID int, @PartnerID int)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
--Declare --@LabelID AS INT 
--@MonthID AS int, @partnerID AS int
--set @partnerID = 4433
--set @MonthID =27
--set @LabelID = 2




SELECT 

	@MonthID AS monthid
	,@PartnerID AS PartnerID
	,[LabelID]
      ,SUM(RW.[NewActivatedCardholders]) AS [NewActivatedCardholders]
      ,SUM(RW.[DeactivatedCustomersInMonth]) AS [DeactivatedCustomersInMonth]
      ,SUM(RW.[ActivatedSales]) AS [ActivatedSales]
      ,SUM(RW.[PostActivatedSales]) AS [PostActivatedSales]
      ,SUM(RW.[PreActivationSales]) AS [PreActivationSales]
      ,SUM(RW.[ActivatedTrans]) AS [ActivatedTrans]
      ,SUM(RW.[PostActivatedTrans]) AS [PostActivatedTrans]
      ,SUM(RW.[ActivatedCommission]) AS [ActivatedCommission]
      ,SUM(RW.[ControlCardholder]) AS [ControlCardholder]
      ,SUM(RW.[ControlSales]) AS [ControlSales]
      ,SUM(RW.[ControlTrans]) AS [ControlTrans]
	  INTO #weektotals
  FROM [MI].[RetailerReportWeekly] RW
WHERE [MonthID] = @MonthID
 -- AND [LabelID] = @LabelID
  AND [PartnerID] = @PartnerID
  GROUP BY    [LabelID] 

 -- select * from #weektotals

SELECT 
 wt.[NewActivatedCardholders]
      ,wt.[DeactivatedCustomersInMonth]
      ,wt.[ActivatedSales]
      ,wt.[PostActivatedSales]
      ,wt.[PreActivationSales]
      ,wt.[ActivatedTrans]
      ,wt.[PostActivatedTrans]
      --,wt.[ActivatedCommission]
	  ,CASE WHEN WT.PartnerID <> 3960 THEN wt.[ActivatedCommission] ELSE (CASE WHEN RM.IncrementalSales > 0 THEN RM.IncrementalSales * 0.025 ELSE 0 END) END AS ActivatedCommission
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
      ,RM.[MonthlyAVG]
      ,RM.[MonthlySTDEV]
      --,RM.[ActivatedTrans]
      --,RM.[ActivatedSales]
	,RM.[IncrementalSales]
	    ,RM.[IncrementalSpenders]
	    ,RM.[CumulativeIncrementalSpenders]
	,RM.[PostActivatedSpender]
	,SMT.RewardTargetUplift
	,SMT.[ContractTargetUplift]
	,SMT.[ContractROI]
	,SMT.margin
	,SMT.[SchemeNotesCustomTargets]
	,rm.Label

  FROM [Warehouse].[MI].[RetailerReportMonthly] RM
  inner join #weektotals WT ON WT.monthid = RM.MonthID AND WT.PartnerID = RM.PartnerID AND RM.[LabelID] = wt.[LabelID]
   left join [Warehouse].[MI].[SchemeMarginsAndTargets] SMT ON RM.PartnerID = SMT.PartnerID 
WHERE RM.[MonthID] = @MonthID
  --AND RM.[LabelID] = @LabelID
  AND RM.[PartnerID] = @PartnerID

   drop table #weektotals
END