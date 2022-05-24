
-- =============================================
-- Author:		<Adam Scott>
-- Create date: <24/11/2014>
-- Description:	<Loads 1st stage calculations>
-- =============================================
CREATE PROCEDURE [MI].[RetailerReportMetric_Cal1] (@DateID int, @PeriodTypeID int)
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

SELECT * into #part1
from (SELECT ID, CASE WHEN UpliftSales = -1 THEN 0 ELSE 1.0*[UpliftSales]*[Sales]/(1+[UpliftSales]) END AS [IncrementalSales]							--1
      ,CASE WHEN UpliftTransactions = -1 THEN 0 ELSE 1.0*[UpliftTransactions]*[Transactions]/(1+[UpliftTransactions]) END AS [IncrementalTransactions]		--1	
      ,CASE WHEN UpliftSpenders = -1 THEN 0 ELSE 1.0*[UpliftSpenders]*[Spenders]/(1+[UpliftSpenders]) END AS [IncrementalSpenders]						--1

  FROM [MI].[RetailerReportMetric] rm
  where Rm.DateID = @DateID and RM.PeriodTypeID = @PeriodTypeID)aa

  update [MI].[RetailerReportMetric]
  set IncrementalSales = P1.IncrementalSales,
  IncrementalTransactions = P1.IncrementalTransactions,
  IncrementalSpenders = P1.IncrementalSpenders

  from [MI].[RetailerReportMetric] RRM
  inner join #part1 P1 on RRM.ID = P1.id
  drop table #part1
END