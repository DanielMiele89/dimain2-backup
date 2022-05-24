-- =============================================
-- Author:		<Adam Scott>
-- Create date: <29/07/2014>
-- Description:	<Gets totals for scheme period for cumlitive calculations>
-- =============================================
CREATE PROCEDURE [MI].[RetailerMonthlyReportSPLITNONCORETotalsSinceLaunch_Fetch]
	-- Add the parameters for the stored procedure here
(@MonthID int, @PartnerID int, @ClientServicesRef nchar(20))
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
----set @LabelID = 2

--SELECT [monthid]                             AS monthID, 
--       @PartnerID                            AS PartnerID, 
--       [labelid], 
--       Sum(RW.[newactivatedcardholders])     AS [NewActivatedCardholders], 
--       Sum(RW.[deactivatedcustomersinmonth]) AS [DeactivatedCustomersInMonth], 
--       Sum(RW.[activatedsales])              AS [ActivatedSales], 
--       Sum(RW.[postactivatedsales])          AS [PostActivatedSales], 
--       Sum(RW.[preactivationsales])          AS [PreActivationSales], 
--       Sum(RW.[activatedtrans])              AS [ActivatedTrans], 
--       Sum(RW.[postactivatedtrans])          AS [PostActivatedTrans], 
--       Sum(RW.[activatedcommission])         AS [ActivatedCommission], 
--       Sum(RW.[controlcardholder])           AS [ControlCardholder], 
--       Sum(RW.[controlsales])                AS [ControlSales], 
--       Sum(RW.[controltrans])                AS [ControlTrans] 
--INTO   #weektotals 
--FROM   [MI].[RetailerReportSplitMonthly] RM
--WHERE  [monthid] <= @MonthID 
--       AND [monthid] >= 20 
--       AND [partnerid] = @PartnerID 
--GROUP  BY [labelid], 
--          [monthid] 
SELECT Sum(RM.[activatedsales])       AS [ActivatedSales], 
       Sum(RM.[postactivatedsales])   AS [PostActivatedSales], 
       Sum(RM.[activatedtrans])       AS ActivatedTrans, 
       Sum(RM.[postactivatedtrans])   AS PostActivatedTrans, 
       Sum(RM.[activatedcommission])  AS ActivatedCommission, 
       Sum(RM.[ControlCardholderSales])         AS ControlSales, 
       Sum(RM.[controltrans])         AS ControlTrans, 
       Max(RM.[monthid])              AS Monthid, 
       RM.[partnerid], 
       Max(RM.[partnergroupid])       AS [PartnerGroupID], 
       Sum(RM.[activatedcardholders]) AS [ActivatedCardholders], 
       Sum (RM.[incrementalsales])    AS IncrementalSales, 
       Max(RM.label)                  AS Label
	   ,RM.StatusTypeID
	   ,RM.SplitID  
	   into #MonthTotals
FROM   [Warehouse].[MI].[RetailerReportSplitMonthly_OLD] RM 



WHERE  RM.[monthid] <= @MonthID 
       AND RM.[monthid] >= 20 
       AND RM.[partnerid] = @PartnerID 
	   And RM.ClientServicesRef = @ClientServicesRef 
	     AND RM.Cumulative = 0
  and RM.Split_Use_For_Report <>0 
  AND RM.Status_Use_For_Report <>0
  and RM.Split_Use_For_Report <=6 
  AND RM.Status_Use_For_Report <=6
GROUP  BY RM.StatusTypeID
	,RM.SplitID 
          ,RM.[partnerid] 

SELECT RM.[ActivatedSales]
      ,RM.[PostActivatedSales]
      ,RM.[ActivatedTrans]
      ,RM.[PostActivatedTrans]
      ,RM.[ActivatedCommission]
      ,RM.[ControlSales]
      ,RM.[ControlTrans]
      ,RM.[MonthID]
      ,RM.[PartnerID]
      ,RM.[PartnerGroupID]
      ,RMc.[ActivatedCardholders]
	,RM.[IncrementalSales]
	,SMT.RewardTargetUplift
	,SMT.[ContractTargetUplift]
	,SMT.[ContractROI]
	,SMT.margin
	,SMT.[SchemeNotesCustomTargets]
	,rm.Label
	,RMC.[ActivatedSpender]
    ,ISNULL(RMC.[PostActivatedSpender],0) as [PostActivatedSpender]
    ,RMC.[IncrementalSpenders]
	,RM.StatusTypeID
	,RMC.StatusTypeDesc
	,RMC.SplitID
	,RMC.SplitDesc
	,RMC.Split_Use_For_Report
	,RMC.Status_Use_For_Report
FROM #MonthTotals RM
   LEFT JOIN [Warehouse].[MI].[SchemeMarginsAndTargets_OLD] SMT ON RM.partnerID = SMT.PartnerID 
  -- INNER JOIN [Warehouse].[MI].retailerreportmonthlylabels ML on RM.[LabelID] = ML.[LabelID]
   INNER JOIN [Warehouse].[MI].[RetailerReportSplitMonthly_OLD] RMC ON RM.partnerID = RMC.partnerID AND RMC.monthid = RM.Monthid And RM.SplitID = RMC.SplitID And RM.StatusTypeID = RMC.StatusTypeID
WHERE  RM.[monthid] = @MonthID 
       AND RMC.[partnerid] = @PartnerID 
	   And RMC.ClientServicesRef = @ClientServicesRef
	     AND RMC.Cumulative = 1
  and RMC.Split_Use_For_Report <>0 
  AND RMC.Status_Use_For_Report <>0
  and RMC.Split_Use_For_Report <=6 
  AND RMC.Status_Use_For_Report <=6
DROP TABLE #MonthTotals

END
