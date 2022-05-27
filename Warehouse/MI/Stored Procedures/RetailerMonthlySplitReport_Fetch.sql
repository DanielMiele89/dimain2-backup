-- =============================================
-- Author:		<Adam J Scott>
-- Create date: <10/04/2014>
-- Description:	<Fetches data from month and week tables for monthly reports by retailer>
-- =============================================
Create PROCEDURE [MI].[RetailerMonthlySplitReport_Fetch]
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
--set @partnerID = 3960
--set @MonthID =29
--set @LabelID = 2

SELECT 
      RM.[ActivatedSales]
      ,RM.[PostActivatedSales]

      ,RM.[ActivatedTrans]
      ,RM.[PostActivatedTrans]
      --,RM.[ActivatedCommission]
	  ,CASE WHEN RM.PartnerID <> 3960 THEN RM.[ActivatedCommission] ELSE (CASE WHEN RM.IncrementalSales > 0 THEN RM.IncrementalSales * 0.025 ELSE 0 END) END AS ActivatedCommission
      --,RM.[ControlCardholder]
      ,RM.[ControlCardholderSales] as ControlSales
      ,RM.[ControlTrans]
	  ,RM.[ID]
      ,RM.[MonthID]
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

      --,RM.[ActivatedTrans]
      --,RM.[ActivatedSales]
	,RM.[IncrementalSales]
	    ,RM.[IncrementalSpenders]

	,RM.[PostActivatedSpender]
	,SMT.RewardTargetUplift
	,SMT.[ContractTargetUplift]
	,SMT.[ContractROI]
	,SMT.margin
	,SMT.[SchemeNotesCustomTargets]
	,RM.StatusTypeID
	,RM.StatusTypeDesc
	,RM.SplitID
	,RM.SplitDesc
	,RM.Split_Use_For_Report
	,RM.Status_Use_For_Report
  FROM [Warehouse].[MI].[RetailerReportSplitMonthly] RM
  --inner join #weektotals WT ON WT.monthid = RM.MonthID AND WT.PartnerID = RM.PartnerID AND RM.[LabelID] = wt.[LabelID]
   left join [Warehouse].[MI].[SchemeMarginsAndTargets] SMT ON RM.PartnerID = SMT.PartnerID 
WHERE RM.[MonthID] = @MonthID
  --AND RM.[LabelID] = @LabelID
  AND RM.[PartnerID] = @PartnerID
  AND RM.Cumulative = 0
  and RM.Split_Use_For_Report <>0 
  AND RM.Status_Use_For_Report <>0
  and RM.Split_Use_For_Report <=6 
  AND RM.Status_Use_For_Report <=6


END
