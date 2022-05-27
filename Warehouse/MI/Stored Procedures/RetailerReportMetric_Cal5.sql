
-- =============================================
-- Author:		<Adam Scott>
-- Create date: <24/11/2014>
-- Description:	<Loads 4th stage calculations>
-- =============================================
CREATE PROCEDURE [MI].[RetailerReportMetric_Cal5] (@DateID int, @PeriodTypeID int)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

   SELECT * into #part5
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
	 , case when IncrementalTransactions is null then null else Case when isnull(SPSUplift,0) =0 then 0 
	 else (IncrementalSales-[DriverTreeRRIncremental])*([ATVUplift]+[ATVUplift]*[ATFUplift]/2)/SPSUplift end end as [DriverTreeATVIncremental] -- 5 -- corrected on 03/06/2015
      , case when IncrementalTransactions is null then null else Case when isnull(SPSUplift,0) =0 then (IncrementalSales-[DriverTreeRRIncremental]) 
	 else (IncrementalSales-[DriverTreeRRIncremental])*([ATFUplift]+[ATVUplift]*[ATFUplift]/2)/SPSUplift end end as [DriverTreeATFIncremental]  -- 5 -- corrected on 03/06/2015
      --,IncrementalSales*([UpliftSpenders]+[UpliftSpenders]*SPSUplift/2)/([UpliftSpenders]+[UpliftSpenders]*SPSUplift+SPSUplift) as [DriverTreeRRIncremental] -- 4
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
  set DriverTreeATVIncremental = P5.DriverTreeATVIncremental,
 DriverTreeATFIncremental = P5.DriverTreeATFIncremental
 -- DriverTreeRRIncremental = P4.DriverTreeRRIncremental
    from [MI].[RetailerReportMetric] RRM
  inner join #part5 P5 on RRM.ID = P5.id

  drop table #part5
END

