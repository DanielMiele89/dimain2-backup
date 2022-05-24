-- =============================================
-- Author:		<Adam Scott>
-- Create date: <04/07/2014>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[RetailerMonthlyReportOnlineOfflineChartNONCORE_Fetch]

(@MonthID int, @partnerID int, @ClientServicesRef nvarchar(20)) 


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	Declare --@LabelID AS INT 
	--@MonthID AS INT, @partnerID AS INT, @ClientServicesRef nvarchar(20),

@FirstMonth AS INT


--SET @partnerID = 3730
--SET @MonthID = 31
--SEt @ClientServicesRef = 'TL009'


SET @FirstMonth = @MonthID -5


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
WHERE [MonthID] between @FirstMonth and @MonthID
 -- AND [LabelID] = @LabelID
  AND [PartnerID] = @PartnerID and RW.LabelID in (102,103) 
  AND RW.ClientServicesRef = @ClientServicesRef
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
	,CASE WHEN RM.[LabelID] = 102 THEN CASE WHEN(RM.IncrementalSales) > WT.PostActivatedSales THEN RM.PostActivatedSales ELSE RM.IncrementalSales end / (WT.PostActivatedSales - Case when RM.IncrementalSales >= WT.PostActivatedSales then WT.PostActivatedSales - 0.01 else RM.IncrementalSales end)else 0 end as OnlineUpLift
	,CASE WHEN RM.[LabelID] = 103 THEN CASE WHEN(RM.IncrementalSales) > WT.PostActivatedSales THEN RM.PostActivatedSales ELSE RM.IncrementalSales end / (WT.PostActivatedSales - Case when RM.IncrementalSales >= WT.PostActivatedSales then WT.PostActivatedSales - 0.01 else RM.IncrementalSales end)else 0 end as InstoreUpLift
	--,CASE WHEN(RM.IncrementalSales) > WT.PostActivatedSales THEN RM.PostActivatedSales ELSE RM.IncrementalSales end / (WT.PostActivatedSales - Case when RM.IncrementalSales >= WT.PostActivatedSales then WT.PostActivatedSales - 0.01 else RM.IncrementalSales end) as UpLift
  into #Results
  FROM [Warehouse].[MI].[RetailerReportMonthly] RM
  INNER JOIN #weektotals WT ON WT.monthid = RM.MonthID AND WT.PartnerID = RM.PartnerID AND RM.[LabelID] = wt.[LabelID]
  INNER JOIN [Warehouse].[Relational].[SchemeUpliftTrans_Month] M on RM.MonthID = M.ID
  LEFT JOIN [Warehouse].[MI].[SchemeMarginsAndTargets] SMT ON RM.PartnerID = SMT.PartnerID 
WHERE RM.[MonthID] between @FirstMonth and @MonthID
  AND RM.[PartnerID] = @PartnerID and RM.LabelID in (102, 103)
  And RM.ClientServicesRef = @ClientServicesRef


select SUTM.ID AS MonthID,
ISNULL(R.LabelID,0 ) AS LabelID,
ISNULL(R.PartnerID,0 ) AS PartnerID,
ISNULL(R.Label,0 ) AS Label,
SUTM.MonthDesc AS MonthDesc,
R.StartDate AS StartDate,
R.EndDate AS EndDate,
ISNULL(R.QuarterID,0 ) AS QuarterID,
ISNULL(R.PostActivatedSales,0 ) AS PostActivatedSales,
ISNULL(R.OnlineUpLift,0 ) AS OnlineUpLift,
ISNULL(R.InstoreUpLift,0 ) AS InstoreUpLift
from [Warehouse].[Relational].[SchemeUpliftTrans_Month] SUTM 
Left join #Results r on R.MonthID = SUTM.ID
where Sutm.id between @FirstMonth and @MonthID


   DROP TABLE #weektotals
   Drop Table #Results

END