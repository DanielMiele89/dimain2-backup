-- =============================================
-- Author:		<Adam Scott>
-- Create date: <14/04/2014>
-- Description:	<Description,,>
-- =============================================
Create PROCEDURE [MI].[RetailerMonthlyReportOnlineOfflineChartcuml_Fetch]

(@MonthID int, @partnerID int) 


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--Declare --@LabelID AS INT 
	--@MonthID AS INT, @partnerID AS INT, 

--@FirstMonth AS INT


--SET @partnerID = 4433
--SET @MonthID = 26
--SET @FirstMonth = @MonthID -5

SELECT 

	[MonthID] AS monthid
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
WHERE [MonthID] between 20 and @MonthID
 -- AND [LabelID] = @LabelID
  AND [PartnerID] = @PartnerID and RW.LabelID in (2, 3)
  GROUP BY    [LabelID], [MonthID] 

 -- select * from #weektotals

SELECT 
    RM.[MonthID]
    ,RM.[LabelID]
    ,RM.[PartnerID]
	,rm.Label
	,M.[MonthDesc]
    ,M.[StartDate]
    ,M.[EndDate]
    ,M.[QuarterID]
	,RM.[PostActivatedSales]
	,CASE WHEN RM.[LabelID] = 2 THEN CASE WHEN(RM.IncrementalSales) > WT.PostActivatedSales THEN RM.PostActivatedSales ELSE RM.IncrementalSales end / (WT.PostActivatedSales - Case when RM.IncrementalSales >= WT.PostActivatedSales then WT.PostActivatedSales - 0.01 else RM.IncrementalSales end)else 0 end as OnlineUpLift
	,CASE WHEN RM.[LabelID] = 3 THEN CASE WHEN(RM.IncrementalSales) > WT.PostActivatedSales THEN RM.PostActivatedSales ELSE RM.IncrementalSales end / (WT.PostActivatedSales - Case when RM.IncrementalSales >= WT.PostActivatedSales then WT.PostActivatedSales - 0.01 else RM.IncrementalSales end)else 0 end as OfflineUpLift
	--,CASE WHEN(RM.IncrementalSales) > WT.PostActivatedSales THEN RM.PostActivatedSales ELSE RM.IncrementalSales end / (WT.PostActivatedSales - Case when RM.IncrementalSales >= WT.PostActivatedSales then WT.PostActivatedSales - 0.01 else RM.IncrementalSales end) as UpLift
  FROM [Warehouse].[MI].[RetailerReportMonthly] RM
  INNER JOIN #weektotals WT ON WT.monthid = RM.MonthID AND WT.PartnerID = RM.PartnerID AND RM.[LabelID] = wt.[LabelID]
  INNER JOIN [Warehouse].[Relational].[SchemeUpliftTrans_Month] M on RM.MonthID = M.ID
  LEFT JOIN [Warehouse].[MI].[SchemeMarginsAndTargets] SMT ON RM.PartnerID = SMT.PartnerID 
WHERE RM.[MonthID] between 20 and @MonthID
  AND RM.[PartnerID] = @PartnerID and RM.LabelID in (2, 3)

   DROP TABLE #weektotals

END
