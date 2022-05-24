-- =============================================
-- Author:		<Adam Scott>
-- Create date: <05/01/2015>
-- Description:	<Mi.ReportMectricQAStage2>
-- =============================================
CREATE PROCEDURE [MI].[ReportMectricQAStage3] @dateid int
	-- Add the parameters for the stored procedure here
as
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here


--------------------------------------upliftsales related errors-----------------------------------

SELECT [PartnerID] as PartnerIDZeroCheckUPliftSalesRelatedCalculations
	  ,[ID]
      ,[ClientServiceRef]
      ,[PaymentTypeID]
      ,[ChannelID]
      ,[CustomerAttributeID]
      ,[Mid_SplitID]
      ,[CumulativeTypeID]
      ,[PeriodTypeID]
      ,[DateID]
      ,[CurencyID]
      ,[CurencyAdj]
      ,[Cardholders]
      ,[Sales]
      ,[Transactions]
      ,[Spenders]
      ,[Commission]
      ,[UpliftSales]
   --   ,[UpliftTransactions]
   --   ,[UpliftSpenders]
      ,[IncrementalSales]
   --   ,[IncrementalTransactions]
   --   ,[IncrementalSpenders]
      ,[IncrementalMargin]
      ,[ATVUplift]
      --,[ATFUplift]
      ,[DriverTreeATVIncremental]
   --   ,[DriverTreeATFIncremental]
   --   ,[DriverTreeRRIncremental]
      ,[ATV]
      ,[ATF]
      ,[RR]
      ,[CostPerAcquisition]
      ,[TotalSalesROI]
      ,[IncrementalSalesROI]
      ,[FinancialROI]
      --,[SPSUplift]
      ,[Margin]
      ,[ContractROI]
      ,[ContractTargetUplift]
      ,[RewardTargetUplift]
  FROM [Warehouse].[MI].[RetailerReportMetric]
  where --(([IncrementalTransactions] is null or [IncrementalTransactions] =0)  
       (
	   --([IncrementalSpenders] is null or [IncrementalSpenders] = 0)
       (partnerid not in (4447,3960) and ([IncrementalMargin] is null or [IncrementalMargin] = 0))
      --or ([ATVUplift] IS NULL or [ATVUplift] = 0)
      --or ([ATFUplift] is null or [ATFUplift] = 0)
      --or ([DriverTreeATVIncremental] is null or [DriverTreeATVIncremental] = 0)
      --or ([DriverTreeATFIncremental] is null or [DriverTreeATFIncremental] = 0)
      --or ([DriverTreeRRIncremental] is null or [DriverTreeRRIncremental] = 0)
      or ([ATV] is null or [ATV] = 0)
      or ([ATF] is null or [ATF]  = 0)
      or ([RR] is null or [RR] = 0)
      or ([CostPerAcquisition] is null or [CostPerAcquisition] = 0)
      or ([TotalSalesROI] is null or [TotalSalesROI] = 0)
      or ([IncrementalSalesROI] is null or [IncrementalSalesROI] = 0)
      or (partnerid not in (4447,3960) and ([FinancialROI] is null or [FinancialROI] = 0)))
      --or ([SPSUplift] is null or [SPSUplift] = 0))  do for sales and transations
     and DateID = @dateid and Sales >0 and Mid_SplitID =0 and UpliftSales <> 0
	 and not(PartnerID = 4494 and ChannelID = 2)
	 and PartnerID not in (4490, 4462, 4433, 4437)

------------------------------------------ 'upliftTrans related errors'---------------------------

SELECT [ID]
      ,[PartnerID] as PartnerIDZeroCheckUPliftTransactionsRelatedCalculations
      ,[ClientServiceRef]
      ,[PaymentTypeID]
      ,[ChannelID]
      ,[CustomerAttributeID]
      ,[Mid_SplitID]
      ,[CumulativeTypeID]
      ,[PeriodTypeID]
      ,[DateID]
      ,[CurencyID]
      ,[CurencyAdj]
      ,[Cardholders]
      ,[Sales]
      ,[Transactions]
      ,[Spenders]
      ,[Commission]
      ,[UpliftSales]
      ,[UpliftTransactions]
      ,[UpliftSpenders]
      ,[IncrementalSales]
      ,[IncrementalTransactions]
      ,[IncrementalSpenders]
      ,[IncrementalMargin]
      ,[ATVUplift]
      ,[ATFUplift]
      ,[DriverTreeATVIncremental]
      ,[DriverTreeATFIncremental]
      ,[DriverTreeRRIncremental]
      ,[ATV]
      ,[ATF]
      ,[RR]
      ,[CostPerAcquisition]
      ,[TotalSalesROI]
      ,[IncrementalSalesROI]
      ,[FinancialROI]
      --,[SPSUplift]
      ,[Margin]
      ,[ContractROI]
      ,[ContractTargetUplift]
      ,[RewardTargetUplift]
  FROM [Warehouse].[MI].[RetailerReportMetric]
  where (([IncrementalTransactions] is null or [IncrementalTransactions] =0)  
      or ([ATVUplift] IS NULL or [ATVUplift] = 0)
      or ([DriverTreeATVIncremental] is null or [DriverTreeATVIncremental] = 0)
      or ([ATV] is null or [ATV] = 0)
      or ([ATF] is null or [ATF]  = 0)
      or ([RR] is null or [RR] = 0)
      or ([CostPerAcquisition] is null or [CostPerAcquisition] = 0)
      or ([TotalSalesROI] is null or [TotalSalesROI] = 0)
	  )
     and DateID = @dateid and Sales >0 and Mid_SplitID =0 and UpliftTransactions is not null and UpliftTransactions <> 0 
	 and not(PartnerID = 4494 and ChannelID = 2)
	 and PartnerID not in (4490, 4462, 4433, 4437)
	 and not(CustomerAttributeID between 2001 and 2004 and CumulativeTypeID =1)

-------------------------------------- 'upliftSpenders related errors'----------------------------------------------------
SELECT [ID]
      ,[PartnerID] as PartnerIDZeroCheckUpliftSpendersRelatedCalculations
      ,[ClientServiceRef]
      ,[PaymentTypeID]
      ,[ChannelID]
      ,[CustomerAttributeID]
      ,[Mid_SplitID]
      ,[CumulativeTypeID]
      ,[PeriodTypeID]
      ,[DateID]
      ,[CurencyID]
      ,[CurencyAdj]
      ,[Cardholders]
      ,[Sales]
      ,[Transactions]
      ,[Spenders]
      ,[Commission]
      ,[UpliftSales]
      ,[UpliftTransactions]
      ,[UpliftSpenders]
      ,[IncrementalSales]
      ,[IncrementalTransactions]
      ,[IncrementalSpenders]
      ,[IncrementalMargin]
      ,[ATVUplift]
      ,[ATFUplift]
      ,[DriverTreeATVIncremental]
      ,[DriverTreeATFIncremental]
      ,[DriverTreeRRIncremental]
      ,[ATV]
      ,[ATF]
      ,[RR]
      ,[CostPerAcquisition]
      ,[TotalSalesROI]
      ,[IncrementalSalesROI]
      ,[FinancialROI]
      ,[SPSUplift]
      ,[Margin]
      ,[ContractROI]
      ,[ContractTargetUplift]
      ,[RewardTargetUplift]
  FROM [Warehouse].[MI].[RetailerReportMetric]
  where 
       (
	   ([IncrementalSpenders] is null or [IncrementalSpenders] = 0)
      or ([DriverTreeRRIncremental] is null or [DriverTreeRRIncremental] = 0)
      or ([ATV] is null or [ATV] = 0)
      or ([ATF] is null or [ATF]  = 0)
      or ([RR] is null or [RR] = 0)
      or ([CostPerAcquisition] is null or [CostPerAcquisition] = 0))
     and DateID = @dateid and Sales >0 and Mid_SplitID =0 and UpliftSpenders <> 0
	 and not(PartnerID = 4494 and ChannelID = 2)
	 and PartnerID not in (4490, 4462, 4433, 4437)

-----------------------------------------'upliftSpendersTrans related errors'-----------------------------------------------
SELECT [ID]
      ,[ProgramID] as PartnerIDZeroCheckUpliftSpendersUpliftTransactionsRelatedCalculations
      ,[PartnerGroupID]
      ,[PartnerID]
      ,[ClientServiceRef]
      ,[PaymentTypeID]
      ,[ChannelID]
      ,[CustomerAttributeID]
      ,[Mid_SplitID]
      ,[CumulativeTypeID]
      ,[PeriodTypeID]
      ,[DateID]
      ,[CurencyID]
      ,[CurencyAdj]
      ,[Cardholders]
      ,[Sales]
      ,[Transactions]
      ,[Spenders]
      ,[Commission]
      ,[UpliftSales]
      ,[UpliftTransactions]
      ,[UpliftSpenders]
      ,[IncrementalSales]
      ,[IncrementalTransactions]
      ,[IncrementalSpenders]
      ,[IncrementalMargin]
      ,[ATVUplift]
      ,[ATFUplift]
      ,[DriverTreeATVIncremental]
      ,[DriverTreeATFIncremental]
      ,[DriverTreeRRIncremental]
      ,[ATV]
      ,[ATF]
      ,[RR]
      ,[CostPerAcquisition]
      ,[TotalSalesROI]
      ,[IncrementalSalesROI]
      ,[FinancialROI]
      ,[SPSUplift]
      ,[Margin]
      ,[ContractROI]
      ,[ContractTargetUplift]
      ,[RewardTargetUplift]
  FROM [Warehouse].[MI].[RetailerReportMetric]
  where --(([IncrementalTransactions] is null or [IncrementalTransactions] =0)  
       --(([IncrementalSpenders] is null or [IncrementalSpenders] = 0)
       --([IncrementalMargin] is null or [IncrementalMargin] = 0)
      --or ([ATVUplift] IS NULL or [ATVUplift] = 0)
      ( ([ATFUplift] is null or [ATFUplift] = 0)
      --or ([DriverTreeATVIncremental] is null or [DriverTreeATVIncremental] = 0)
      or ([DriverTreeATFIncremental] is null or [DriverTreeATFIncremental] = 0)
      --or ([DriverTreeRRIncremental] is null or [DriverTreeRRIncremental] = 0)
      or ([ATV] is null or [ATV] = 0)
      or ([ATF] is null or [ATF]  = 0)
      or ([RR] is null or [RR] = 0)
      or ([CostPerAcquisition] is null or [CostPerAcquisition] = 0))
      --or ([TotalSalesROI] is null or [TotalSalesROI] = 0)
      --or ([IncrementalSalesROI] is null or [IncrementalSalesROI] = 0))
      --or ([FinancialROI] is null or [FinancialROI] = 0))
      --or ([SPSUplift] is null or [SPSUplift] = 0))  do for sales and transations
     and DateID = @dateid and Sales >0 and Mid_SplitID = 0 and UpliftSpenders <> 0 and UpliftTransactions <> 0
	 and not(PartnerID = 4494 and ChannelID = 2)
	 and PartnerID not in (4490, 4462, 4433, 4437)
	
    -------------------------------Seclct Ave uplift how many Faulse +++ ---------------------------------
  Select PartnerID, PartnerGroupID, ClientServiceRef, RM.CumulativeTypeID
  ,AVG(RM.UpliftSales) as AVEUpliftSales, Case when AVG(RM.UpliftSales) >.2 then AVG(RM.UpliftSales)/2 else AVG(RM.UpliftSales)-.1 end as AVEUpliftSalesLowerband , Case when AVG(RM.UpliftSales) >.2 then AVG(RM.UpliftSales)*2 else AVG(RM.UpliftSales)+.1 end  as AVEUpliftSalesUpperband
  ,AVG(RM.UpliftSpenders) as AVEUpliftSpenders, AVG(RM.UpliftSpenders)/2 as AVEUpliftSpendersLowerband , AVG(UpliftSpenders)*2 as AVEUpliftSpendersUpperband
  ,AVG(RM.UpliftTransactions) as AVEUpliftTransactions, AVG(RM.UpliftTransactions)/2 as AVEUpliftTransactionsLowerband , AVG(UpliftTransactions)*2 as AVEUpliftTransactionsUpperband
   into #UpliftCheck
   FROM [Warehouse].[MI].[RetailerReportMetric] RM
  where DateID between @Dateid - 7 and @dateid -1 -- Get range
  And  Rm.CustomerAttributeID = 0 and Mid_SplitID =0 and RM.[PaymentTypeID] =0 and RM.ChannelID = 0
  Group by RM.[PaymentTypeID], RM.CumulativeTypeID, PartnerID, PartnerGroupID, ClientServiceRef


  Select RM.PartnerID as PartnerIDUpliftOutsideAvg, RM.PartnerGroupID, RM.ClientServiceRef, RM.CumulativeTypeID,RM.UpliftSales, TC.AVEUpliftSales, RM.UpliftSpenders,TC.AVEUpliftSpenders, RM.UpliftTransactions ,TC.AVEUpliftTransactions
  FROM [Warehouse].[MI].[RetailerReportMetric] RM
  Inner join #UpliftCheck TC
  ON TC.PartnerID = RM.PartnerID and TC.PartnerGroupID = RM.PartnerGroupID and TC.ClientServiceRef = RM.ClientServiceRef and TC.CumulativeTypeID = RM.CumulativeTypeID
   where DateID = @Dateid 
  And  Rm.CustomerAttributeID = 0 and Mid_SplitID =0 and RM.[PaymentTypeID] =0 and RM.ChannelID = 0
  And RM.CumulativeTypeID = 0
  and (RM.UpliftSales not between TC.AVEUpliftSalesLowerband and TC.AVEUpliftSalesUpperband 
  --or RM.UpliftTransactions not between TC.AVEUpliftTransactionsLowerband and TC.AVEUpliftTransactionsUpperband
  --OR RM.UpliftSpenders not between TC.AVEUpliftSpendersLowerband and TC.AVEUpliftSpendersUpperband
  )
  And RM.PartnerID not in (2766,4487,4434,4448) -- ecclude HIgh varence retailers
  drop table #UpliftCheck

      -------------------------------Seclct total uplift <10% ---------------------------------

  Select PartnerID as PartnerWithLowUplift,ClientServiceRef , UpliftSales, UpliftTransactions, UpliftSpenders
  FROM [Warehouse].[MI].[RetailerReportMetric] RM
  where DateID = @Dateid 
  And Rm.CustomerAttributeID = 0 and Mid_SplitID = 0 and RM.[PaymentTypeID] =0 and RM.ChannelID = 0
  And RM.CumulativeTypeID = 0 and (UpliftSales < 0.10 )--or UpliftTransactions < 0.10 or UpliftSpenders < 0.10)
  order by UpliftSales


  ---------------------------------------------------------------- better  Sales compaire-----------------------------------------------------
  Select Monthid, Count(*) as weeks
into #Monthlenth
from Relational.SchemeUpliftTrans_Week
where monthid >=20
group by MonthID

Declare @Monthlengh int
set @Monthlengh = (select weeks from #Monthlenth where MonthID = @dateid)
declare @isXmas as int
set @isXmas =(select Case when @dateid % 12 = 0 then 1 when (@dateid +1) % 12 = 0 then 1 else 0 end)

  Select PartnerID, PartnerGroupID, ClientServiceRef, RM.CumulativeTypeID
  ,(AVG(sales)/26) *24 as AVESales, ((AVG(sales)/26) *24)/1.2 as AVESalesLowerband , ((AVG(sales)/26) *24)*(case @isXmas when 1 then 1.6 else 1.2 end)  as AVESalesupperband
  ,(AVG(RM.Transactions)/26) *24 as AVGtrans, ((AVG(Transactions)/26) *24) / 1.2 as AVETransLowerband , ((AVG(Transactions)/26) *24) *(case @isXmas when 1 then 1.6 else 1.2 end) as AVETransupperband
  ,(AVG(RM.Spenders)/26) *24 as AVGSpenders, ((AVG(Spenders)/26) *24) / 1.2 as AVESpendersLowerband , ((AVG(Spenders)/26) *24) * (case @isXmas when 1 then 1.6 else 1.2 end) as AVESpendersupperband
   into #TotalstoCUML1
   FROM [Warehouse].[MI].[RetailerReportMetric] RM
  where DateID between @Dateid - 2 and @dateid -1 -- Get range
  And  Rm.CustomerAttributeID = 0 and Mid_SplitID =0 and RM.[PaymentTypeID] =0 and RM.ChannelID = 0
  Group by RM.[PaymentTypeID], RM.CumulativeTypeID, PartnerID, PartnerGroupID, ClientServiceRef


  Select RM.PartnerID as PartnerIDAvgSalesWayDiffrent, 
  RM.PartnerGroupID, 
  RM.ClientServiceRef, 
  RM.CumulativeTypeID,RM.Sales, 
  TC.AVESales, 
  (RM.Sales/@Monthlengh)*4 as adjustedSales, 
  RM.Transactions,
  (RM.Transactions/@Monthlengh)*4 as AdjustedTransactions, 
  TC.AVGtrans, 
  RM.Spenders, 
  TC.AVGSpenders
  FROM [Warehouse].[MI].[RetailerReportMetric] RM
  Inner join #TotalstoCUML1 TC
  ON TC.PartnerID = RM.PartnerID and TC.PartnerGroupID = RM.PartnerGroupID and TC.ClientServiceRef = RM.ClientServiceRef and TC.CumulativeTypeID = RM.CumulativeTypeID
   where DateID = @Dateid 
  And  Rm.CustomerAttributeID = 0 and Mid_SplitID =0 and RM.[PaymentTypeID] =0 and RM.ChannelID = 0
  And RM.CumulativeTypeID = 0
  and ((RM.Sales/@Monthlengh)*4 not between TC.AVESalesLowerband and TC.AVESalesupperband 
  or (RM.Transactions/@Monthlengh)*4 not between TC.AVETransLowerband and TC.AVETransupperband 
  OR (RM.Spenders/@Monthlengh)*4 not between TC.AVESpendersLowerband and TC.AVESpendersupperband)
  And RM.PartnerID not in (4434,4448) -- ecclude HIgh varence retailers
  drop table #TotalstoCUML1
 -- Drop table #Monthlenth


------------------------------------ Check if INC Sales add up to withen 10 %----------------------------------------------

Select [PartnerGroupID]
      ,RM.[PartnerID]
      ,[ClientServiceRef]
	,CumulativeTypeID
	,PeriodTypeID
	,PaymentTypeID
 
,Sum(isnull(IncrementalSales,0)) as IncrementalSales, Sum(isnull(IncrementalTransactions,0)) as IncrementalTransactions
  into #ChannelCheck
  FROM [Warehouse].[MI].[RetailerReportMetric] RM
  Where dateid = @dateid 
  and Rm.CustomerAttributeID = 0 and Mid_SplitID =0 and RM.ChannelID <> 0 --and CumulativeTypeID = 0
  Group by RM.PartnerID, RM.ClientServiceRef,PartnerGroupID, CumulativeTypeID, PeriodTypeID, PaymentTypeID
 

 Select --RM.[PartnerGroupID]
      RM.[PartnerID] as CheckIncrementalSumofParts
      ,RM.[ClientServiceRef]
	,RM.CumulativeTypeID
	,RM.PeriodTypeID
	,RM.PaymentTypeID
	,CC.IncrementalSales as SUMIncrementalSales
	 ,RM.IncrementalSales
	 --,cc.IncrementalTransactions ,RM.IncrementalTransactions
	 FROM [Warehouse].[MI].[RetailerReportMetric] RM
	 inner join #ChannelCheck CC 
	  on   RM.[PartnerGroupID] = CC.[PartnerGroupID]
      and RM.[PartnerID]= CC.[PartnerID] 
      And RM.[ClientServiceRef] = CC.[ClientServiceRef]
      and RM.[PaymentTypeID] = CC.[PaymentTypeID]
      And Rm.[CumulativeTypeID] = CC.[CumulativeTypeID]
      And RM.[PeriodTypeID] = CC.[PeriodTypeID]
	 
	 Where  (RM.IncrementalSales NOT between (CC.IncrementalSales/1.1) and (CC.IncrementalSales*1.1)
	 --or RM.IncrementalTransactions NOT between (CC.IncrementalTransactions/1.2) and (CC.IncrementalTransactions*1.2)
	 ) 
	 and RM.dateid = @dateid and Rm.CustomerAttributeID = 0 and Mid_SplitID =0 and RM.ChannelID = 0 And RM.PaymentTypeID = 0 --and CumulativeTypeID = 0

	drop table #ChannelCheck 

------------------------------------ Check if INC Sales add up to withen 10 % MID Splits----------------------------------------------

Select [PartnerGroupID]
      ,RM.[PartnerID]
      ,[ClientServiceRef]
	,CumulativeTypeID
	,PeriodTypeID
	,PaymentTypeID
	,Sum(isnull(IncrementalSales,0)) as IncrementalSales, Sum(isnull(IncrementalTransactions,0)) as IncrementalTransactions
--,Sum(Sales) as Sales, Sum(Transactions) as Transactions , SUM(Spenders) as Spenders ,SUM(Commission) as Commission
  into #MIDCheck
  FROM [Warehouse].[MI].[RetailerReportMetric] RM
  Where dateid = @dateid and Rm.CustomerAttributeID = 0 and Mid_SplitID <>0 and RM.ChannelID = 0 --and CumulativeTypeID = 0
  Group by RM.PartnerID, RM.ClientServiceRef,PartnerGroupID, CumulativeTypeID, PeriodTypeID, PaymentTypeID
 

 Select --RM.[PartnerGroupID]
      RM.[PartnerID] as CheckIncrementalSumofPartsMID_SPLIT
      ,RM.[ClientServiceRef]
	,RM.CumulativeTypeID
	,RM.PeriodTypeID
	,RM.PaymentTypeID
	,RM.IncrementalSales
	,CC.IncrementalSales As CIIncrementalSales
	--,CC.Sales
	-- ,RM.Sales
	-- ,cc.Transactions ,RM.Transactions
	-- ,CC.Spenders ,RM.Spenders
	-- ,cc.Commission ,RM.Commission
	 FROM [Warehouse].[MI].[RetailerReportMetric] RM
	 inner join #MIDCheck CC 
	  on   RM.[PartnerGroupID] = CC.[PartnerGroupID]
      and RM.[PartnerID]= CC.[PartnerID] 
      And RM.[ClientServiceRef] = CC.[ClientServiceRef]
      and RM.[PaymentTypeID] = CC.[PaymentTypeID]
      And Rm.[CumulativeTypeID] = CC.[CumulativeTypeID]
      And RM.[PeriodTypeID] = CC.[PeriodTypeID]

	 
	 Where   (RM.IncrementalSales NOT between (CC.IncrementalSales/1.1) and (CC.IncrementalSales*1.1))
	  and  RM.dateid = @dateid and Rm.CustomerAttributeID = 0 and Mid_SplitID =0 and RM.ChannelID = 0 And RM.PaymentTypeID = 0 --and CumulativeTypeID = 0

	 drop table #MIDCheck 

------------------------------------ Check if SPC withen range----------------------------------------------
--Select Monthid, Count(*) as weeks
--into #Monthlenth
--from Relational.SchemeUpliftTrans_Week
--where monthid >=20
--group by MonthID

--Declare @Monthlengh int
set @Monthlengh = (select weeks from #Monthlenth where MonthID = @dateid)
--declare @isXmas as int
set @isXmas =(select Case when @dateid % 12 = 0 then 1 when (@dateid +1) % 12 = 0 then 1 else 0 end)

  Select PartnerID, PartnerGroupID, ClientServiceRef, RM.CumulativeTypeID
	  --,(AVG(Sales/Cardholders)/26) *24 as AVESPC, ((AVG(Sales/Cardholders)/26) *24)/1.33 as AVESPCLowerband , ((AVG(Sales/Cardholders)/26) *24)*(case @isXmas when 1 then 300 else 300 end)  as AVESPCUpperband
	  ,(AVG(Sales/Cardholders))  as AVESPC, ((AVG(Sales/Cardholders))/1.33) as AVESPCLowerband , (AVG(Sales/Cardholders)*(3.0)) as AVESPCUpperband
	  --,(AVG(RM.Transactions)/26) *24 as AVGtrans, ((AVG(Transactions)/26) *24) / 1.2 as AVETransLowerband , ((AVG(Transactions)/26) *24) *(case @isXmas when 1 then 1.6 else 1.2 end) as AVETransupperband
	  --,(AVG(RM.Spenders)/26) *24 as AVGSpenders, ((AVG(Spenders)/26) *24) / 1.2 as AVESpendersLowerband , ((AVG(Spenders)/26) *24) * (case @isXmas when 1 then 1.6 else 1.2 end) as AVESpendersupperband
	   into #TotalstoCUML2
	   FROM [Warehouse].[MI].[RetailerReportMetric] RM
  where DateID between @Dateid - 2 and @dateid -1 -- Get range
	  And  Rm.CustomerAttributeID = 0 and Mid_SplitID =0 and RM.[PaymentTypeID] =0 and RM.ChannelID = 0
  Group by RM.[PaymentTypeID], RM.CumulativeTypeID, PartnerID, PartnerGroupID, ClientServiceRef


  Select RM.PartnerID as PartnerIDAvgSPCWayDiffrent, 
	  RM.PartnerGroupID, 
	  RM.ClientServiceRef, 
	  RM.CumulativeTypeID,rm.Sales/RM.Cardholders as SPC, 
	  TC.AVESPC, 
	  ((rm.Sales/RM.Cardholders)/@Monthlengh)*4 as adjustedSalesSPC--, 
	  --RM.Transactions,
	  --(RM.Transactions/@Monthlengh)*4 as AdjustedTransactions, 
	  --TC.AVGtrans, 
	  ----RM.Spenders--, 
	  --TC.AVGSpenders
  FROM [Warehouse].[MI].[RetailerReportMetric] RM
  Inner join #TotalstoCUML2 TC
  ON TC.PartnerID = RM.PartnerID and TC.PartnerGroupID = RM.PartnerGroupID and TC.ClientServiceRef = RM.ClientServiceRef and TC.CumulativeTypeID = RM.CumulativeTypeID
  where DateID = @Dateid 
	  And  Rm.CustomerAttributeID = 0 and Mid_SplitID =0 and RM.[PaymentTypeID] =0 and RM.ChannelID = 0
	  And RM.CumulativeTypeID = 0
	  --and ((RM.Sales/@Monthlengh)*4 not between TC.AVESPCLowerband and TC.AVESPCUpperband 
	  and ((rm.Sales/RM.Cardholders) not between TC.AVESPCLowerband and TC.AVESPCUpperband 
	  )
	  --or (RM.Transactions/@Monthlengh)*4 not between TC.AVETransLowerband and TC.AVETransupperband 
	  --OR (RM.Spenders/@Monthlengh)*4 not between TC.AVESpendersLowerband and TC.AVESpendersupperband)
	  And RM.PartnerID not in (4434,4448) -- ecclude HIgh varence retailers
  drop table #TotalstoCUML2
  Drop table #Monthlenth



------------------------------------ Check if ONLINE offline porportion withen Avg +-6.5 PP----------------------------------------------



SELECT 
		[PartnerID]
      ,[ClientServiceRef]
	  ,ChannelID
      ,sum(Sales) as TotalSales
	  INTO #Totalsales
  FROM [Warehouse].[MI].[RetailerReportMetric]
  where dateid = @dateid and ChannelID = 0 and PaymentTypeID =0 and CumulativeTypeID =0 and Mid_SplitID = 0 and CustomerAttributeID = 0  
  group by ChannelID,PartnerID,ClientServiceRef

  order by PartnerID




SELECT 
		[PartnerID]
      ,[ClientServiceRef]
	  ,ChannelID
      ,sum(Sales) as Sales
	  INTO #Sales
  FROM [Warehouse].[MI].[RetailerReportMetric]
  where dateid = @dateid and ChannelID in (1,2) and PaymentTypeID =0 and CumulativeTypeID =0 and Mid_SplitID = 0 and CustomerAttributeID = 0 
  group by ChannelID,PartnerID,ClientServiceRef
  order by PartnerID


  Select TS.Partnerid
	,TS.[ClientServiceRef]
	,sales/TS.TotalSales as proportion 
	,s.ChannelID
	INTO #Proportion
  from #Totalsales TS
  inner join #Sales S on TS.PartnerID = s.PartnerID and TS.ClientServiceRef = S.ClientServiceRef 
  Order by ts.PartnerID, ts.ClientServiceRef, ChannelID
 
 drop table #Sales
 drop table #TotalSales
 


 SELECT 
	  [PartnerID]
      ,[ClientServiceRef]
	  ,ChannelID
      ,sum(Sales)/6 as AvgTotalSales
	  INTO #AVGTotalsales
  FROM [Warehouse].[MI].[RetailerReportMetric]
  where dateid Between @dateid-7 and @dateid-1 and ChannelID = 0 and PaymentTypeID = 0 and CumulativeTypeID = 0 and Mid_SplitID = 0 and CustomerAttributeID = 0
  group by ChannelID,PartnerID,ClientServiceRef
  order by PartnerID




SELECT 
		[PartnerID]
      ,[ClientServiceRef]
	  ,ChannelID
      ,sum(Sales)/6 as AvgSales
	  INTO #AvgSales
  FROM [Warehouse].[MI].[RetailerReportMetric]
  where dateid Between @dateid-7 and @dateid-1 
  and ChannelID in (1,2) 
  and PaymentTypeID = 0 
  and CumulativeTypeID = 0 
  and Mid_SplitID = 0 
  and CustomerAttributeID = 0 
  and Transactions >50 ---------------------------------exclude low volume Splits 
  group by ChannelID,PartnerID,ClientServiceRef
  order by PartnerID


  Select TS.Partnerid as PartnerIDWithVeryDiffrentOnlineSplit
	,S.ClientServiceRef 
	,Avgsales/TS.AVGTotalSales as AVGProportion 
	,P.proportion
	,s.ChannelID
  from #AvgTotalsales TS
  inner join #AvgSales S on TS.PartnerID = s.PartnerID and TS.ClientServiceRef = S.ClientServiceRef 
  inner join #Proportion P on TS.PartnerID = P.PartnerID and TS.ClientServiceRef = p.ClientServiceRef and P.ChannelID = S.ChannelID 
  where not((Avgsales/TS.AVGTotalSales < 0.01 or Avgsales/TS.AVGTotalSales > 0.99) and (P.proportion < 0.01 and P.proportion > 0.99))
  and P.proportion not between (Avgsales/TS.AVGTotalSales)-0.065 and (Avgsales/TS.AVGTotalSales)+.065
  Order by ts.PartnerID, ts.ClientServiceRef, ChannelID

  drop table #AVGTotalsales
  drop table #AvgSales
  drop table #Proportion


END