
-- =============================================
-- Author:		<Adam Scott>
-- Create date: <24/11/2014>
-- Description:	<Loads 4th stage calculations>
-- =============================================
CREATE PROCEDURE [MI].[RetailerReportMetric_Cal4] (@DateID int, @PeriodTypeID int)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   SELECT * into #part4
from (SELECT [ID]
  --    ,1.0*[UpliftSales]*[Sales]/(1+[UpliftSales]) as	  [IncrementalSales]							--1
  --    ,1.0*[UpliftTransactions]*[Transactions]/(1+[UpliftTransactions]) [IncrementalTransactions]		--1	
  --    ,1.0*[UpliftSpenders]*[Spenders]/(1+[UpliftSpenders]) [IncrementalSpenders]						--1
  --    ,(Select Margin from Relational.Master_Retailer_Table MR where MR.PartnerID = RM.PartnerID) * IncrementalSales/1.2 as [IncrementalMargin]  ----2
  --    ,1.0*(CASE when [Transactions] > 0 then [Sales]/[Transactions] else 0 end)/
		--(CASE when [Transactions] - [IncrementalTransactions]> 0 then ([Sales]-[IncrementalSales])/([Transactions]-[IncrementalTransactions]) else [Sales]/[Transactions] end)-1 [ATVUplift] --2
  --    ,CASE when Spenders > 0 then ([Transactions]*1.0000)/ Spenders else 0 end/
		--CASE when Spenders- [IncrementalSpenders]> 0 then (([Transactions]-[IncrementalTransactions])*1.0000)/ (Spenders-[IncrementalSpenders]) else ([Transactions]*1.0000)/ Spenders  end -1
		--as	  [ATFUplift] --2
	 -- , [ATFUplift]+[ATVUplift]+[ATVUplift]*[ATVUplift] as SPSUplift --3
      --, (IncrementalSales-[DriverTreeRRIncremental])*([ATVUplift]+[ATVUplift]*[ATVUplift]/2)/SPSUplift as [DriverTreeATVIncremental] -- 5
      --,(IncrementalSales-[DriverTreeRRIncremental])*([ATFUplift]+[ATVUplift]*[ATVUplift]/2)/SPSUplift as [DriverTreeATFIncremental]  -- 5
      ,case when IncrementalSpenders is null then NULL else Case when isnull(([UpliftSpenders]+[UpliftSpenders]*SPSUplift+SPSUplift),0) = 0 then 0 else  IncrementalSales*([UpliftSpenders]+[UpliftSpenders]*SPSUplift/2)/([UpliftSpenders]+[UpliftSpenders]*SPSUplift+SPSUplift) end end as [DriverTreeRRIncremental] -- 4
      --,CASE when [Transactions] > 0 then [Sales]/[Transactions] else 0 end as [ATV] -- 1
      --,CASE when Spenders > 0 then ([Transactions]*1.0000)/ Spenders else 0 end as [ATF] --1
      --,CASE when Cardholders > 0 then ([Spenders]*1.0000)/Cardholders else 0 end as RR --1
      --,CASE when Transactions > 0 then Commission/Spenders else 0 end as [CostPerAcquisition] --1
      --,CASE when Commission > 0 then Sales/Commission/1.2 else 0 end as [TotalSalesROI] --1
      --,CASE when Commission > 0 then IncrementalSales/Commission/1.2 else 0 end as [IncrementalSalesROI] --2
      --,CASE when Commission > 0 Then IncrementalMargin/Commission-1 else 0 end as [FinancialROI] --3
  FROM [MI].[RetailerReportMetric] rm
        where Rm.DateID = @DateID and RM.PeriodTypeID = @PeriodTypeID)dd

update [MI].[RetailerReportMetric]
  set-- DriverTreeATVIncremental = P4.DriverTreeATVIncremental,
  --DriverTreeATFIncremental = P4.DriverTreeATFIncremental,
  DriverTreeRRIncremental = P4.DriverTreeRRIncremental
    from [MI].[RetailerReportMetric] RRM
  inner join #part4 P4 on RRM.ID = P4.id

  drop table #part4
END