
-- =============================================
-- Author:		<Adam Scott>
-- Create date: <13/11/2014>
-- Description:	<Loads weights>
-- =============================================
CREATE PROCEDURE [MI].[Uplift_ResultsWeights_load] (@DateID INT, @PeriodID INT, @PartnerID INT = NULL)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--declare @DateID INT, @PeriodID INT
	--set @DateID = 34
	--set @PeriodID = 1
    -- Insert statements for procedure here
	

  select * into #Weight from (
  select UR.ID, Case when ((1+URT.UpliftSales)*sum(case when URT.UpliftSales<>-1 THEN 1.0*rm.Sales/(1+URT.UpliftSales) end) over (partition by ur.ResultsRowID)) > 0
	 then 1.0*RM.Sales/((1+URT.UpliftSales)*sum(case when URT.UpliftSales<>-1 THEN 1.0*rm.Sales/(1+URT.UpliftSales) end) over (partition by ur.ResultsRowID))
	 else 0 end as Weight
  from [MI].[Uplift_RetailerReport] UR 
  inner join MI.Uplift_Results_Table URT ON UR.UpliftRowID=URT.ID
  inner join MI.RetailerReportMetric RM ON
  	  URT.[Programid] = RM.[Programid]
      and URT.[PartnerGroupID] = RM.[PartnerGroupID]
      and URT.[PartnerID] = RM.[PartnerID]
      and URT.[ClientServiceRef] = RM.[ClientServiceRef]
      and URT.[PaymentTypeID] = RM.[PaymentTypeID]
      and URT.[ChannelID] = RM.[ChannelID] 
      And URT.CustomerAttributeID = RM.[CustomerAttributeID]
      And URT.Mid_SplitID = RM.[Mid_SplitID]
      And URT.[CumulativeTypeID] = RM.[CumulativeTypeID]
      And URT.[PeriodTypeID] = RM.[PeriodTypeID]
	  And URT.DateID = RM.DateID 
	  -- 1=Sales, 2=Spenders, 3=Transactions
  where ur.metricid=1 and RM.DateID = @DateID And RM.PeriodTypeID = @PeriodID
  AND (@PartnerID IS NULL OR rm.PartnerID = @PartnerID)
  union
    select UR.ID, Case when ((1+URT.UpliftSpenders)*sum(case when URT.UpliftSpenders<>-1 THEN 1.0*rm.Spenders/(1+URT.UpliftSpenders) END) over (partition by ur.ResultsRowID)) > 0 
    then 1.0*RM.Spenders/((1+URT.UpliftSpenders)*sum(case when URT.UpliftSpenders<>-1 THEN 1.0*rm.Spenders/(1+URT.UpliftSpenders) END) over (partition by ur.ResultsRowID))
    else 0 end 
  from [MI].[Uplift_RetailerReport] UR 
  inner join MI.Uplift_Results_Table URT ON UR.UpliftRowID=URT.ID
  inner join MI.RetailerReportMetric RM ON
  	  URT.[Programid] = RM.[Programid]
      and URT.[PartnerGroupID] = RM.[PartnerGroupID]
      and URT.[PartnerID] = RM.[PartnerID]
      and URT.[ClientServiceRef] = RM.[ClientServiceRef]
      and URT.[PaymentTypeID] = RM.[PaymentTypeID]
      and URT.[ChannelID] = RM.[ChannelID] 
      And URT.CustomerAttributeID = RM.[CustomerAttributeID]
      And URT.Mid_SplitID = RM.[Mid_SplitID]
      And URT.[CumulativeTypeID] = RM.[CumulativeTypeID]
      And URT.[PeriodTypeID] = RM.[PeriodTypeID]
	  And URT.DateID = RM.DateID 
	    -- 1=Sales, 2=Spenders, 3=Transactions
  where ur.metricid=2 and RM.DateID = @DateID And RM.PeriodTypeID = @PeriodID
  AND (@PartnerID IS NULL OR rm.PartnerID = @PartnerID)
  union
  select UR.ID, Case when ((1+URT.UpliftTransactions)*sum(case when URT.UpliftTransactions<>-1 THEN 1.0*rm.Transactions/(1+URT.UpliftTransactions)end) over (partition by ur.ResultsRowID)) >0 
  then 1.0*RM.Transactions/((1+URT.UpliftTransactions)*sum(case when URT.UpliftTransactions<>-1 THEN 1.0*rm.Transactions/(1+URT.UpliftTransactions)end) over (partition by ur.ResultsRowID))
  else 0 end
  from [MI].[Uplift_RetailerReport] UR 
  inner join MI.Uplift_Results_Table URT ON UR.UpliftRowID=URT.ID
  inner join MI.RetailerReportMetric RM ON
  	  URT.[Programid] = RM.[Programid]
      and URT.[PartnerGroupID] = RM.[PartnerGroupID]
      and URT.[PartnerID] = RM.[PartnerID]
      and URT.[ClientServiceRef] = RM.[ClientServiceRef]
      and URT.[PaymentTypeID] = RM.[PaymentTypeID]
      and URT.[ChannelID] = RM.[ChannelID] 
      And URT.CustomerAttributeID = RM.[CustomerAttributeID]
      And URT.Mid_SplitID = RM.[Mid_SplitID]
      And URT.[CumulativeTypeID] = RM.[CumulativeTypeID]
      And URT.[PeriodTypeID] = RM.[PeriodTypeID]
	  And URT.DateID = RM.DateID 
	    -- 1=Sales, 2=Spenders, 3=Transactions
  where ur.metricid=3 and RM.DateID = @DateID And RM.PeriodTypeID = @PeriodID
  AND (@PartnerID IS NULL OR rm.PartnerID = @PartnerID))aa


  update [MI].[Uplift_RetailerReport]
  set Weight = CAST(w.Weight as decimal(11,10))
  from   [MI].[Uplift_RetailerReport] URR
  inner join #Weight w on W.ID = URR.ID


drop table #Weight
END

