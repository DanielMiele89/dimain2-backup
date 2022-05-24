
-- =============================================
-- Author:		<Adam Scott>
-- Create date: <24/11/2014>
-- Description:	<Loads 2nd stage calculations>
-- =============================================
CREATE PROCEDURE [MI].[RetailerReportMetric_Cal2] (@DateID int, @PeriodTypeID int)
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
--declare @DateID int, @PeriodTypeID int
--Set @DateID = 34
--Set @PeriodTypeID = 1
    -- Insert statements for procedure here
  SELECT * into #part2
from (

SELECT [ID]					
,Margin * IncrementalSales/1.0 as [IncrementalMargin]  ----2
  , (CASE when [Transactions] > 0 and ([Transactions] - [IncrementalTransactions])>0 and ([Sales]-[IncrementalSales])>0 then (1.0*[Sales]/[Transactions] )/
		(1.0*([Sales]-[IncrementalSales])/([Transactions]-[IncrementalTransactions]))-1 else 0 end) [ATVUplift] --2
      ,CASE when Spenders > 0 and (Spenders- [IncrementalSpenders])> 0 and ([Transactions]-[IncrementalTransactions])>0 then (1.0*[Transactions]/ Spenders) /
		(1.0*([Transactions]-[IncrementalTransactions])/ (Spenders-[IncrementalSpenders])) -1 else 0 end 
		as	  [ATFUplift]
      ,CASE when Spenders > 0 then Commission/Spenders else 0 end as [CostPerAcquisition] --2
      ,CASE when Commission > 0 then Sales/Commission/1.0 else 0 end as [TotalSalesROI] --2
      ,CASE when Commission > 0 then  IncrementalSales/Commission/1.0 else 0 end as [IncrementalSalesROI] --2
	 ,CASE when [Transactions] > 0 then 1.0*[Sales]/[Transactions] else 0 end as [ATV] -- 2
      ,CASE when Spenders > 0 then (1.0*[Transactions])/ Spenders else 0 end as [ATF] --2
      ,CASE when Cardholders > 0 then (1.0*[Spenders])/Cardholders else 0 end as RR --2

  FROM [MI].[RetailerReportMetric] rm
    where Rm.DateID = @DateID and RM.PeriodTypeID = @PeriodTypeID ) bb

update [MI].[RetailerReportMetric]
  set IncrementalMargin = P2.IncrementalMargin,
  ATVUplift = P2.ATVUplift,
  ATFUplift = P2.ATFUplift,
    CostPerAcquisition=P2.CostPerAcquisition,
  TotalSalesROI=P2.TotalSalesROI,
  IncrementalSalesROI = P2.IncrementalSalesROI,
  ATV=P2.ATV,
  ATF=p2.ATF,
  RR=P2.RR
    from [MI].[RetailerReportMetric] RRM
  inner join #part2 P2 on RRM.ID = P2.id

  drop table #part2

END