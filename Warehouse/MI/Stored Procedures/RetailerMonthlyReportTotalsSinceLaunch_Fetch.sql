-- =============================================
-- Author:		<Adam Scott>
-- Create date: <11/04/2014>
-- Description:	<Gets totals for scheme period for cumlitive calculations>
-- =============================================
CREATE PROCEDURE [MI].[RetailerMonthlyReportTotalsSinceLaunch_Fetch]
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
--set @MonthID =27
----set @LabelID = 2

SELECT [monthid]                             AS monthID, 
       @PartnerID                            AS PartnerID, 
       [labelid], 
       Sum(RW.[newactivatedcardholders])     AS [NewActivatedCardholders], 
       Sum(RW.[deactivatedcustomersinmonth]) AS [DeactivatedCustomersInMonth], 
       Sum(RW.[activatedsales])              AS [ActivatedSales], 
       Sum(RW.[postactivatedsales])          AS [PostActivatedSales], 
       Sum(RW.[preactivationsales])          AS [PreActivationSales], 
       Sum(RW.[activatedtrans])              AS [ActivatedTrans], 
       Sum(RW.[postactivatedtrans])          AS [PostActivatedTrans], 
       Sum(RW.[activatedcommission])         AS [ActivatedCommission], 
       Sum(RW.[controlcardholder])           AS [ControlCardholder], 
       Sum(RW.[controlsales])                AS [ControlSales], 
       Sum(RW.[controltrans])                AS [ControlTrans] 
INTO   #weektotals 
FROM   [MI].[retailerreportweekly] RW 
WHERE  [monthid] <= @MonthID 
       AND [monthid] >= 20 
       AND [partnerid] = @PartnerID 
GROUP  BY [labelid], 
          [monthid] 
SELECT Sum(wt.[activatedsales])       AS [ActivatedSales], 
       Sum(wt.[postactivatedsales])   AS [PostActivatedSales], 
       Sum(wt.[activatedtrans])       AS ActivatedTrans, 
       Sum(wt.[postactivatedtrans])   AS PostActivatedTrans, 
       Sum(wt.[activatedcommission])  AS ActivatedCommission, 
       Sum(wt.[controlsales])         AS ControlSales, 
       Sum(wt.[controltrans])         AS ControlTrans, 
       Max(RM.[monthid])              AS Monthid, 
	   RM.[labelid], 
       RM.[partnerid], 
       Max(RM.[partnergroupid])       AS [PartnerGroupID], 
       Sum(RM.[activatedcardholders]) AS [ActivatedCardholders], 
       Sum (RM.[incrementalsales])    AS IncrementalSales, 
       Max(RM.label)                  AS Label 
	   into #MonthTotals
FROM   [Warehouse].[MI].[retailerreportmonthly] RM 
       INNER JOIN #weektotals WT 
               ON WT.monthid = RM.monthid 
                  AND WT.partnerid = RM.partnerid 
                  AND RM.[labelid] = wt.[labelid] 
WHERE  RM.[monthid] <= @MonthID 
       AND RM.[monthid] >= 20 
       AND RM.[partnerid] = @PartnerID 
GROUP  BY RM.[labelid], 
          RM.[partnerid] 

SELECT RM.[ActivatedSales]
      ,RM.[PostActivatedSales]
      ,RM.[ActivatedTrans]
      ,RM.[PostActivatedTrans]
      ,RM.[ActivatedCommission]
      ,RM.[ControlSales]
      ,RM.[ControlTrans]
      ,RM.[MonthID]
	  ,RMC.labelID as LabelIDCumulative
      ,RM.[LabelID]
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
FROM #MonthTotals RM
   LEFT JOIN [Warehouse].[MI].[SchemeMarginsAndTargets] SMT ON RM.partnerID = SMT.PartnerID 
   INNER JOIN [Warehouse].[MI].retailerreportmonthlylabels ML on RM.[LabelID] = ML.[LabelID]
   INNER JOIN [Warehouse].[MI].[retailerreportmonthly] RMC ON RM.partnerID = RMC.partnerID AND RMC.monthid = RM.Monthid and RMC.LabelID = ML.CumulativeLabelID


DROP TABLE #MonthTotals
DROP TABLE #weektotals 

END