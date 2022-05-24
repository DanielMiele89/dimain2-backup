-- =============================================
-- Author:		<Adam Scott>
-- Create date: <05/01/2014>
-- Description:	<ReportMectricQAStage1>
-- =============================================
CREATE PROCEDURE [MI].[ReportMectricQAStage1] @dateid int
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
--Declare @dateid int
-- Set @dateid = 35 -- change for each month

 --------------------------------Chech all partners are present---------------------

 SELECT Distinct [PartnerID] as MissingPartner
      ,isnull([ClientServicesRef],0) as ClientServicesRef
  FROM [Warehouse].[Stratification].[ReportingBaseOffer]

  where FirstReportingMonth <= @dateid
  and(LastReportingMonth is null or LastReportingMonth >= @dateid)
  and PartnerID not in (Select PartnerID from MI.RetailerReportMetric where Dateid = @dateid)

  
 SELECT Distinct [PartnerID] 
      ,isnull([ClientServicesRef],0) as  MissingClientServicesRef
  FROM [Warehouse].[Stratification].[ReportingBaseOffer]

  where FirstReportingMonth <= @dateid
  and(LastReportingMonth is null or LastReportingMonth >= @dateid)
  and ClientServicesRef not in (Select ClientServicesRef from MI.RetailerReportMetric where Dateid = @dateid)

 --------------------------------cherch row count----------------------------

SELECT 
      RM.[PartnerID] as PartnerIDIncorrectRowCount 
	  ,Count(*) as Rowsfound
      ,[PartnerGroupID]
	  ,P.PartnerName
      ,[ClientServiceRef]
      
  FROM [Warehouse].[MI].[RetailerReportMetric] RM
  inner join Relational.Partner p on P.PartnerID = RM.PartnerID
  where Dateid = @dateid and Mid_splitID = 0 and CustomerAttributeID = 0
  and RM.PartnerID not in (4433, 4462, 4490) -------------------exclude Retailers that have left-------------------
  
  group by RM.PartnerID, ClientServiceRef, PartnerGroupID ,P.PartnerName
  having Count(*) <>27 -- 27 seems to be the correct number but my calculations say 27 will recheck on next dry run



    ---------------------------------------------------------Mid checks------------------------------------------
	
  Select PartnerID , COUNT(*) as CountSplits 
  into #Splits
  from [MI].[RetailerReportMID_Split] 
  Group by PartnerID

  Select RM.PartnerID as PartnerIDIncorrectMIDSplitCount, Count(*) as CountSplits, ClientServiceRef   
   FROM #Splits s
   inner join [Warehouse].[MI].[RetailerReportMetric] RM on RM.PartnerID = s.PartnerID
   Where Mid_SplitID <> 0 and DateID = @dateid and RM.PartnerID <> 4462
   group by rm.PartnerID ,CountSplits, ClientServiceRef 
   having Count(*)  <> CountSplits * 9				--set for number of rows expcted
   drop table #Splits


	--------------------------------------------------------Chech main uplifts are present-------------------------

	SELECT RM.[PartnerID] as PartnerIDMAinUpliftsMissing
      ,[ClientServiceRef]
      ,[CumulativeTypeID]
      ,[PeriodTypeID]
      ,RM.[DateID]
      ,[Cardholders]
      ,[Sales]
      ,[Transactions]
      ,[Spenders]
      ,[Commission]
      ,[UpliftSales]
      ,[UpliftTransactions]
      ,[UpliftSpenders]
  FROM [Warehouse].[MI].[RetailerReportMetric] RM
  inner join MI.WorkingofferDates WO ON WO.Partnerid = RM.PartnerID And RM.ClientServiceRef = WO.ClientServicesref
  where RM.DateID = @dateid and ChannelID = 0 and PaymentTypeID = 0 and Mid_SplitID = 0 AND CustomerAttributeID = 0 and (UpliftSales is null or UpliftSales = 0 or UpliftTransactions is null or UpliftTransactions =0 or UpliftTransactions is null or UpliftTransactions =0)

	--------------------------------------------------------Chech MID_SPLIT uplifts are present-------------------------
  SELECT RM.[PartnerID] as PartnerIDSplitSalesUPliftsMissing
      ,[ClientServiceRef]
      ,[CumulativeTypeID]
      ,[PeriodTypeID]
      ,RM.[DateID]
      ,[Cardholders]
      ,[Sales]
      ,[Transactions]
      ,[Spenders]
      ,[Commission]
      ,[UpliftSales]
      ,[UpliftTransactions]
      ,[UpliftTransactions]
  FROM [Warehouse].[MI].[RetailerReportMetric] RM
  inner join MI.WorkingofferDates WO ON WO.Partnerid = RM.PartnerID And RM.ClientServiceRef = WO.ClientServicesref
  where RM.DateID = @dateid and ChannelID = 0 and PaymentTypeID = 0 and Mid_SplitID > 0 and (UpliftSales is null or UpliftSales = 0)

--  ------------------------------check totals Done---------------------------------

Select [PartnerGroupID]
      ,RM.[PartnerID]
      ,[ClientServiceRef]
	,CumulativeTypeID
	,PeriodTypeID
	,PaymentTypeID
 
,Sum(Sales) as Sales, Sum(Transactions) as Transactions , SUM(Spenders) as Spenders ,SUM(Commission) as Commission
  into #ChannelCheck
  FROM [Warehouse].[MI].[RetailerReportMetric] RM
  Where dateid = @dateid and Rm.CustomerAttributeID = 0 and Mid_SplitID =0 and RM.ChannelID <> 0 --and CumulativeTypeID = 0
  Group by RM.PartnerID, RM.ClientServiceRef,PartnerGroupID, CumulativeTypeID, PeriodTypeID, PaymentTypeID
 

 Select --RM.[PartnerGroupID]
      RM.[PartnerID] as IncorrectSumOfParts
      ,RM.[ClientServiceRef]
	,RM.CumulativeTypeID
	,RM.PeriodTypeID
	,RM.PaymentTypeID
	,CC.Sales As SumedSales
	 ,RM.Sales
	 ,cc.Transactions as SumedTransactions ,RM.Transactions
	 ,CC.Spenders As SumedSpenders ,RM.Spenders
	 ,cc.Commission As SummedCommission ,RM.Commission
	 FROM [Warehouse].[MI].[RetailerReportMetric] RM
	 inner join #ChannelCheck CC 
	  on   RM.[PartnerGroupID] = CC.[PartnerGroupID]
      and RM.[PartnerID]= CC.[PartnerID] 
      And RM.[ClientServiceRef] = CC.[ClientServiceRef]
      and RM.[PaymentTypeID] = CC.[PaymentTypeID]
      And Rm.[CumulativeTypeID] = CC.[CumulativeTypeID]
      And RM.[PeriodTypeID] = CC.[PeriodTypeID]
	 
	 Where  (CC.Sales <> RM.Sales
	 or CC.Transactions <> RM.Transactions
	 or cc.Commission <> RM.Commission
	 OR CC.Spenders < RM.Spenders
	 ) and  RM.dateid = @dateid and Rm.CustomerAttributeID = 0 and Mid_SplitID =0 and RM.ChannelID = 0 --and CumulativeTypeID = 0
	 and RM.PartnerID not in (3960) -------exclude retaiers that have custom commision -------
	 drop table #ChannelCheck 


--  ------------------------------check totals MIDSplit Will alwaws show BP Due to it being calculated later---------------------------------

Select [PartnerGroupID]
      ,RM.[PartnerID]
      ,[ClientServiceRef]
	,CumulativeTypeID
	,PeriodTypeID
	,PaymentTypeID
 
,Sum(Sales) as Sales, Sum(Transactions) as Transactions , SUM(Spenders) as Spenders ,SUM(Commission) as Commission
  into #MIDCheck
  FROM [Warehouse].[MI].[RetailerReportMetric] RM
  Where dateid = @dateid and Rm.CustomerAttributeID = 0 and Mid_SplitID <>0 and RM.ChannelID = 0 --and CumulativeTypeID = 0
  Group by RM.PartnerID, RM.ClientServiceRef,PartnerGroupID, CumulativeTypeID, PeriodTypeID, PaymentTypeID
 

 Select --RM.[PartnerGroupID]
      RM.[PartnerID] as PartnerIDIncorrectMIDSplitSumOfparts
      ,RM.[ClientServiceRef]
	,RM.CumulativeTypeID
	,RM.PeriodTypeID
	,RM.PaymentTypeID
	,CC.Sales as CALSales
	 ,RM.Sales
	 ,cc.Transactions as calTransactions ,RM.Transactions
	 ,CC.Spenders as CALSpenders,RM.Spenders
	 ,cc.Commission CALCommission,RM.Commission
	 FROM [Warehouse].[MI].[RetailerReportMetric] RM
	 inner join #MIDCheck CC 
	  on   RM.[PartnerGroupID] = CC.[PartnerGroupID]
      and RM.[PartnerID]= CC.[PartnerID] 
      And RM.[ClientServiceRef] = CC.[ClientServiceRef]
      and RM.[PaymentTypeID] = CC.[PaymentTypeID]
      And Rm.[CumulativeTypeID] = CC.[CumulativeTypeID]
      And RM.[PeriodTypeID] = CC.[PeriodTypeID]

	 
	 Where  (CC.Sales <> RM.Sales
	 or cc.Commission <> RM.Commission
	 or CC.Transactions <> RM.Transactions
	 OR CC.Spenders < RM.Spenders
	 ) and  RM.dateid = @dateid and Rm.CustomerAttributeID = 0 and Mid_SplitID =0 and RM.ChannelID = 0 --and CumulativeTypeID = 0

	 drop table #MIDCheck 

--  ------------------------------check totals nle---------------------------------

Select [PartnerGroupID]
      ,RM.[PartnerID]
      ,[ClientServiceRef]
	,CumulativeTypeID
	,PeriodTypeID
	,PaymentTypeID
 
,Sum(Sales) as Sales, Sum(Transactions) as Transactions , SUM(Spenders) as Spenders ,SUM(Commission) as Commission
  into #ChannelChecknle
  FROM [Warehouse].[MI].[RetailerReportMetric] RM
  Where dateid = @dateid and Rm.CustomerAttributeID between 1 and 4 and Mid_SplitID =0 and RM.ChannelID = 0 --and CumulativeTypeID = 0
  Group by RM.PartnerID, RM.ClientServiceRef,PartnerGroupID, CumulativeTypeID, PeriodTypeID, PaymentTypeID
 

 Select --RM.[PartnerGroupID]
      RM.[PartnerID] as IncorrectSumOfPartsNLE_Rolling
      ,RM.[ClientServiceRef]
	,RM.CumulativeTypeID
	,RM.PeriodTypeID
	,RM.PaymentTypeID
	,CC.Sales As SumedSales
	 ,RM.Sales
	 ,cc.Transactions as SumedTransactions ,RM.Transactions
	 ,CC.Spenders As SumedSpenders ,RM.Spenders
	 ,cc.Commission As SummedCommission ,RM.Commission
	 FROM [Warehouse].[MI].[RetailerReportMetric] RM
	 inner join #ChannelChecknle CC 
	  on   RM.[PartnerGroupID] = CC.[PartnerGroupID]
      and RM.[PartnerID]= CC.[PartnerID] 
      And RM.[ClientServiceRef] = CC.[ClientServiceRef]
      and RM.[PaymentTypeID] = CC.[PaymentTypeID]
      And Rm.[CumulativeTypeID] = CC.[CumulativeTypeID]
      And RM.[PeriodTypeID] = CC.[PeriodTypeID]
	 
	 Where  (CC.Sales <> RM.Sales
	 or CC.Transactions <> RM.Transactions
	 or cc.Commission <> RM.Commission
	 OR CC.Spenders < RM.Spenders
	 ) and  RM.dateid = @dateid and Rm.CustomerAttributeID = 0 and Mid_SplitID =0 and RM.ChannelID = 0 and rm.CumulativeTypeID = 0
	 and RM.PartnerID not in (3960) -------exclude retaiers that have custom commision -------
	 drop table #ChannelChecknle 




Select [PartnerGroupID]
      ,RM.[PartnerID]
      ,[ClientServiceRef]
	,CumulativeTypeID
	,PeriodTypeID
	,PaymentTypeID
 
,Sum(Sales) as Sales, Sum(Transactions) as Transactions , SUM(Spenders) as Spenders ,SUM(Commission) as Commission
  into #ChannelCheck1
  FROM [Warehouse].[MI].[RetailerReportMetric] RM
  Where dateid = @dateid and Rm.CustomerAttributeID between 2001 and 2003 and Mid_SplitID =0 and RM.ChannelID = 0 --and CumulativeTypeID = 0
  Group by RM.PartnerID, RM.ClientServiceRef,PartnerGroupID, CumulativeTypeID, PeriodTypeID, PaymentTypeID
 

 Select --RM.[PartnerGroupID]
      RM.[PartnerID] as IncorrectSumOfPartsNLE_fixedYTD
      ,RM.[ClientServiceRef]
	,RM.CumulativeTypeID
	,RM.PeriodTypeID
	,RM.PaymentTypeID
	,CC.Sales As SumedSales
	 ,RM.Sales
	 ,cc.Transactions as SumedTransactions ,RM.Transactions
	 ,CC.Spenders As SumedSpenders ,RM.Spenders
	 ,cc.Commission As SummedCommission ,RM.Commission
	 FROM [Warehouse].[MI].[RetailerReportMetric] RM
	 inner join #ChannelCheck1 CC 
	  on   RM.[PartnerGroupID] = CC.[PartnerGroupID]
      and RM.[PartnerID]= CC.[PartnerID] 
      And RM.[ClientServiceRef] = CC.[ClientServiceRef]
      and RM.[PaymentTypeID] = CC.[PaymentTypeID]
      And Rm.[CumulativeTypeID] = CC.[CumulativeTypeID]
      And RM.[PeriodTypeID] = CC.[PeriodTypeID]
	 
	 Where  (CC.Sales <> RM.Sales
	 or CC.Transactions <> RM.Transactions
	 or cc.Commission <> RM.Commission
	 OR CC.Spenders < RM.Spenders
	 ) and  RM.dateid = @dateid and Rm.CustomerAttributeID = 0 and Mid_SplitID =0 and RM.ChannelID = 0 and rm.CumulativeTypeID = 0
	 and RM.PartnerID not in (3960) -------exclude retaiers that have custom commision -------
	 drop table #ChannelCheck1



Select [PartnerGroupID]
      ,RM.[PartnerID]
      ,[ClientServiceRef]
	,CumulativeTypeID
	,PeriodTypeID
	,PaymentTypeID
 
,Sum(Sales) as Sales, Sum(Transactions) as Transactions , SUM(Spenders) as Spenders ,SUM(Commission) as Commission
  into #ChannelCheck2
  FROM [Warehouse].[MI].[RetailerReportMetric] RM
  Where dateid = @dateid and Rm.CustomerAttributeID between 1001 and 1003 and Mid_SplitID =0 and RM.ChannelID = 0 --and CumulativeTypeID = 0
  Group by RM.PartnerID, RM.ClientServiceRef,PartnerGroupID, CumulativeTypeID, PeriodTypeID, PaymentTypeID
 

 Select --RM.[PartnerGroupID]
      RM.[PartnerID] as IncorrectSumOfPartsNLE_fixedallTime
      ,RM.[ClientServiceRef]
	,RM.CumulativeTypeID
	,RM.PeriodTypeID
	,RM.PaymentTypeID
	,CC.Sales As SumedSales
	 ,RM.Sales
	 ,cc.Transactions as SumedTransactions ,RM.Transactions
	 ,CC.Spenders As SumedSpenders ,RM.Spenders
	 ,cc.Commission As SummedCommission ,RM.Commission
	 FROM [Warehouse].[MI].[RetailerReportMetric] RM
	 inner join #ChannelCheck2 CC 
	  on   RM.[PartnerGroupID] = CC.[PartnerGroupID]
      and RM.[PartnerID]= CC.[PartnerID] 
      And RM.[ClientServiceRef] = CC.[ClientServiceRef]
      and RM.[PaymentTypeID] = CC.[PaymentTypeID]
      And Rm.[CumulativeTypeID] = CC.[CumulativeTypeID]
      And RM.[PeriodTypeID] = CC.[PeriodTypeID]
	 
	 Where  (CC.Sales <> RM.Sales
	 or CC.Transactions <> RM.Transactions
	 or cc.Commission <> RM.Commission
	 OR CC.Spenders < RM.Spenders
	 ) and  RM.dateid = @dateid and Rm.CustomerAttributeID = 0 and Mid_SplitID =0 and RM.ChannelID = 0 and rm.CumulativeTypeID = 0
	 and RM.PartnerID not in (3960) -------exclude retaiers that have custom commision -------
	 drop table #ChannelCheck2
 --------------------------------- chech for odvious nulls and 0-------------

 Select PartnerID as PartnerIDOdviousnulls
 ,[PaymentTypeID]
      ,[ChannelID]
      ,[CustomerAttributeID]
      ,[Mid_SplitID],  [CumulativeTypeID]
      ,[PeriodTypeID] , RM.PartnerID, RM.Sales, RM.Transactions, RM.Cardholders,Rm.Spenders 
  FROM [Warehouse].[MI].[RetailerReportMetric] RM
  where (RM.Sales is null or RM.Transactions is null or Rm.Spenders is null or RM.Cardholders is null or RM.Cardholders = 0)
  and DateID = @dateid and PartnerID  in (select distinct PartnerID from mi.WorkingofferDates)
  order by PartnerID


------------------------------Check Against PT MONYHLY-----------------------------------------------------


 select * into #SalesCalc from(
SELECT pt.[PartnerID]
	  ,'0' as ClientServiceRef
	  ,0 as CustomerAttributeID
	  ,0 as CumulativeTypeID
	  ,1 as PeriodTypeID
	  ,C.DateID as DateID 
      ,SUM([TransactionAmount]) as INSchemeSales
	  ,Count(*) as INSchemeTransactions
      ,Count(distinct PT.[FanID]) as INSchemeSpenders
	  ,SUM(CommissionChargable) as Commission 
	  ,(select Count(*) from MI.Staging_Customer_Temp where Dateid = @dateid and [PaymentRegisteredWithid] = 0)as Cardholders	 
--into #SalesCalc	
FROM [Relational].[PartnerTrans] PT
inner join Mi.Staging_Customer_Temp c on
		C.FanID = PT.FanID
inner join Relational.SchemeUpliftTrans_Month SUTM
		on pt.addeddate between SUTM.StartDate and SUTM.EndDate and c.DateID = SUTM.id 
Left Join Relational.Master_Retailer_Table MRT 
		on MRT.PartnerID = PT.PartnerID
Inner JOIN MI.WorkingofferDates WO 
		ON WO.Partnerid = pt.PartnerID and WO.ClientServicesref = '0'
left join MI.RetailerMetricPaymentypes RMP 
		on PT.PaymentMethodID = RMP.SourcePaymentID and C.ProgramID = RMP.ProgramID 
where  pt.[EligibleForCashBack] = 1 and
		PT.TransactionAmount > 0 and 
		C.CumulativeTypeID = 0 and 
		C.DateID = @DateID and
		c.PaymentRegisteredWithid = 0 and
		(MRT.core is null or MRT.core = 'y') and 
		PT.TransactionDate Between Wo.StartDate and WO.EndDate
Group BY pt.[PartnerID], C.DateID

union all

SELECT pt.[PartnerID]
	  ,BOM.ClientServicesRef as ClientServiceRef
	  ,0 as CustomerAttributeID
	  ,0 as CumulativeTypeID
	  ,1 as PeriodTypeID
	  ,C.DateID as DateID 
      ,SUM([TransactionAmount]) as INSchemeSales
	  ,Count(*) as INSchemeTransactions
      ,Count(distinct PT.[FanID]) as INSchemeSpenders
	  ,SUM(CommissionChargable) as Commission 
	  ,(select Count(*) from MI.Staging_Customer_Temp c1 inner join [Stratification].[BaseOfferMembers_NonCore] BOM1
	on PT.PartnerID = BOM1.PartnerID and BOM1.FanID = C1.FanID and BOM1.MonthID = c1.DateID where c1.Dateid = @dateid and c1.[PaymentRegisteredWithid] = 0 and BOM1.ClientServicesRef = Bom.ClientServicesRef)as Cardholders
FROM [Relational].[PartnerTrans] PT
inner join Mi.Staging_Customer_Temp c on
		C.FanID = PT.FanID 
inner join Relational.SchemeUpliftTrans_Month SUTM
		on pt.addeddate between SUTM.StartDate and SUTM.EndDate and c.DateID = SUTM.id 
Inner Join Relational.Master_Retailer_Table MRT 
		on MRT.PartnerID = PT.PartnerID
inner join [Stratification].[BaseOfferMembers_NonCore] BOM
		on PT.PartnerID = BOM.PartnerID and BOM.FanID = C.FanID and BOM.MonthID = c.DateID --and C.ClientServicesRef = bom.ClientServicesRef
Inner JOIN MI.WorkingofferDates WO 
		ON WO.Partnerid = pt.PartnerID and WO.ClientServicesref = BOM.ClientServicesRef and c.dateid=wo.Dateid
left join MI.RetailerMetricPaymentypes RMP 
		on PT.PaymentMethodID = RMP.SourcePaymentID and C.ProgramID = RMP.ProgramID 
where  pt.[EligibleForCashBack] = 1 and
		PT.TransactionAmount > 0 and 
		C.CumulativeTypeID = 0 and 
		C.DateID = @DateID and
		c.PaymentRegisteredWithid = 0 and
		MRT.core = 'n' and
		BOM.ClientServicesRef is not null and 
		PT.TransactionDate Between Wo.StartDate and WO.EndDate
Group BY pt.[PartnerID], C.DateID, BOM.ClientServicesRef

)aa


select rm.PartnerID as PartnerIDPTMONTHDiffrent, rm.ClientServiceRef, rm.CumulativeTypeID, RM.Sales, sc.INSchemeSales, 
RM.Transactions, SC.INSchemeTransactions, RM.Spenders, SC.INSchemeSpenders, 
RM.Cardholders , SC.Cardholders 
from #SalesCalc sc
inner join mi.[RetailerReportMetric] RM on sc.DateID = RM.DateID 
and SC.PartnerID = rm.PartnerID 
and sc.ClientServiceRef= rm.ClientServiceRef 
and sc.CumulativeTypeID = rm.CumulativeTypeID
and rm.PaymentTypeID =0 
and rm.CustomerAttributeID =0
and RM.Mid_SplitID = 0
and rm.ChannelID = 0
and (RM.Sales <> sc.INSchemeSales or RM.Transactions <> SC.INSchemeTransactions or RM.Spenders <> SC.INSchemeSpenders or RM.Cardholders <> SC.Cardholders
)


--select * from #SalesCalc

drop table #SalesCalc

-------------------------------checking ATVuplift and ATFUplift Check Adjustment factures if wroung---------------------------------------
SELECT [ID]
      ,[PartnerID] as ABSATVUpliftGraterthan50per
      ,[ClientServiceRef]
      ,[CumulativeTypeID]
      ,[PeriodTypeID]
      ,[DateID]
      ,[Cardholders]
      ,[Sales]
      ,[Transactions]
      ,[Spenders]
      ,[Commission]
      ,[UpliftSales]
      ,[UpliftTransactions]
      ,[UpliftSpenders]
      ,[ATVUplift]
      ,[ATV]
  FROM [Warehouse].[MI].[RetailerReportMetric]
  where DateID = @dateid  and (ABS(ATVUplift)>0.5 and [ProgramID]=1 AND [PaymentTypeID]=0 AND [ChannelID]=0 AND [Mid_SplitID]=0)

SELECT [ID]
      ,[PartnerID] as ABSATFUpliftGraterthan50per
      ,[ClientServiceRef]
      ,[CumulativeTypeID]
      ,[PeriodTypeID]
      ,[DateID]
      ,[Cardholders]
      ,[Sales]
      ,[Transactions]
      ,[Spenders]
      ,[Commission]
      ,[UpliftSales]
      ,[UpliftTransactions]
      ,[UpliftSpenders]
      ,[ATFUplift]
      ,[ATF]
  FROM [Warehouse].[MI].[RetailerReportMetric]
  where DateID = @dateid and (ABS(ATFUplift)>0.5 and [ProgramID]=1 AND [PaymentTypeID]=0 AND [ChannelID]=0 AND [Mid_SplitID]=0)

--------------------------------Check Against PT CUML-------------------------------------------------
select * into #SalesCalcc from(

SELECT pt.[PartnerID]
	  ,C.ClientServicesRef as ClientServiceRef
	  ,0 as CustomerAttributeID
	  ,CD.Cumlitivetype as CumulativeTypeID
	  ,1 as PeriodTypeID
	  ,C.DateID as DateID 
      ,SUM([TransactionAmount]) as INSchemeSales
	  ,Count(*) as INSchemeTransactions
      ,Count(distinct PT.[FanID]) as INSchemeSpenders
	  ,SUM(CommissionChargable) as Commission 
	  ,(select Count(*) from MI.Staging_Customer_TempCUMLandNonCore c1 where  c1.Dateid = @dateid and c1.PaymentRegisteredWithid = 0 and c1.ClientServicesRef = c.ClientServicesRef and c1.PartnerID = pt.PartnerID  and C1.CumulativeTypeID = CD.Cumlitivetype) as Cardholders	  
--into #Sales	
FROM [Relational].[PartnerTrans] PT
inner join Mi.Staging_Customer_TempCUMLandNonCore c on
		C.FanID = PT.FanID and C.PartnerID = pt.PartnerID
inner join Relational.SchemeUpliftTrans_Month SUTM
		on c.DateID = SUTM.id 
Left Join Relational.Master_Retailer_Table MRT 
		on MRT.PartnerID = PT.PartnerID
inner join MI.WorkingCumlDates CD 
		on CD.PartnerID = PT.PartnerID and CD.ClientServicesRef = c.ClientServicesRef and C.CumulativeTypeID = CD.Cumlitivetype and CD.Dateid = c.DateID
Inner JOIN MI.WorkingofferDates WO 
		ON WO.Partnerid = pt.PartnerID and WO.ClientServicesref = c.ClientServicesRef and c.dateid=wo.Dateid
left Join MI.OutletAttribute OA 
		on OA.OutletID = PT.OutletID AND PT.AddedDate between OA.StartDate and OA.EndDate
left join MI.RetailerMetricPaymentypes RMP 
		on PT.PaymentMethodID = RMP.SourcePaymentID and C.ProgramID = RMP.ProgramID 
where  pt.[EligibleForCashBack] = 1 and
		PT.TransactionAmount > 0 and 
		--C.CumulativeTypeID = 0 and 
		C.DateID = @DateID and
		c.PaymentRegisteredWithid = 0 and
		PT.addeddate between CD.StartDate and SUTM.EndDate  and 
		PT.TransactionDate Between Wo.StartDate and WO.EndDate
Group BY pt.[PartnerID], C.DateID, c.ClientServicesRef, CD.Cumlitivetype
--order by pt.PartnerID
)aa


select rm.PartnerID  as PartnerIDPTCUMLDiffrent,
rm.ClientServiceRef, rm.CumulativeTypeID, RM.Sales, sc.INSchemeSales, RM.Transactions, SC.INSchemeTransactions, RM.Spenders, SC.INSchemeSpenders, RM.Cardholders , SC.Cardholders As CalCardholders
from #SalesCalcc sc
inner join mi.RetailerReportMetric RM on sc.DateID = RM.DateID 
and sc.PartnerID = rm.PartnerID 
and sc.ClientServiceRef= rm.ClientServiceRef 
and sc.CumulativeTypeID = rm.CumulativeTypeID
and rm.PaymentTypeID =0 
and rm.CustomerAttributeID =0
and RM.Mid_SplitID = 0
and rm.ChannelID = 0
and (RM.Sales > sc.INSchemeSales or RM.Transactions > SC.INSchemeTransactions or RM.Spenders > SC.INSchemeSpenders-- or RM.Cardholders <> SC.Cardholders
)


--select * from #SalesCalc

drop table #SalesCalcc


END
