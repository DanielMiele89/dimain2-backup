﻿
-- =============================================
-- Author:		Dorota
-- Create date:	28/11/2014
-- Description:	Corrections to Cumulative Sales and Transactions and Commission in MI.RetailerReportMetric
-- =============================================
CREATE PROCEDURE [MI].[RetailerReportMetricCumulativeFix_Sales]  (@DateID INT, @CumulativeTypeID INT, @PartnerID INT = NULL)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

--declare @DateID as INT;
--declare @CumulativeTypeID as INT;
--set @dateID=34;
--set @CumulativeTypeID=1;

	 Select 1 CumulativeTypeID, t.partnerid, m.Reporting_Start_MonthID StartMonthID, MAX(DateID) DateID 
	 into #OldPartners
	 from MI.RetailerReportMetric t 
	 left join Relational.Master_Retailer_Table m 
	 on m.PartnerID=t.PartnerID
	 where @CumulativeTypeID=1
	 and CumulativeTypeID=0
	 and t.DateID>=m.Reporting_Start_MonthID
	 AND (@PartnerID IS NULL OR t.PartnerID = @PartnerID)
	 group By t.partnerid, m.Reporting_Start_MonthID
	 UNION
	 Select 2 CumulativeTypeID, t.partnerid, 20 StartMonthID,  MAX(DateID) DateID 
	 from MI.RetailerReportMetric t 
	 left join Relational.Master_Retailer_Table m 
	 on m.PartnerID=t.PartnerID
	 where @CumulativeTypeID=2
	 and CumulativeTypeID=0
	 and t.DateID>=20
	 AND (@PartnerID IS NULL OR t.PartnerID = @PartnerID)
	 group By t.partnerid

 SELECT rm.ProgramID
      ,rm.PartnerGroupID
      ,rm.PartnerID
      ,rm.ClientServiceRef
      ,rm.PaymentTypeID
      ,rm.ChannelID
      ,rm.CustomerAttributeID
      ,rm.Mid_SplitID
      ,d.Cumlitivetype CumulativeTypeID
      ,rm.PeriodTypeID
      ,d.DateID
	 ,MAX(rm.CurrencyAdj) CurencyAdj 
	 ,MAX(rm.CurrencyID) CurencyID
	 ,SUM(Sales) Sales
      ,SUM(Transactions) Transactions
	-- ,SUM(Commission) Commission
	 ,COUNT(DISTINCT rm.DateID) Months
  INTO #NewValues
  FROM MI.RetailerReportMetric rm
  INNER JOIN MI.WorkingCumlDates d ON rm.PartnerID=d.PartnerID and rm.ClientServiceRef=d.ClientServicesRef 
  AND d.Cumlitivetype=@CumulativeTypeID AND d.DateID=@DateID
  WHERE rm.DateID BETWEEN d.StartMonthID AND d.DateID
  AND rm.CumulativeTypeID=0
  GROUP BY rm.ProgramID
      ,rm.PartnerGroupID
      ,rm.PartnerID
      ,rm.ClientServiceRef
      ,rm.PaymentTypeID
      ,rm.ChannelID
      ,rm.CustomerAttributeID
      ,rm.Mid_SplitID
      ,d.Cumlitivetype 
      ,rm.PeriodTypeID
      ,d.DateID   
UNION 
 SELECT rm.ProgramID
      ,rm.PartnerGroupID
      ,rm.PartnerID
      ,rm.ClientServiceRef
      ,rm.PaymentTypeID
      ,rm.ChannelID
      ,rm.CustomerAttributeID
      ,rm.Mid_SplitID
      ,d.CumulativeTypeID CumulativeTypeID
      ,rm.PeriodTypeID
      ,@DateID
	 ,MAX(rm.CurrencyAdj) CurencyAdj 
	 ,MAX(rm.CurrencyID) CurencyID
	 ,SUM(Sales) Sales
      ,SUM(Transactions) Transactions
	-- ,SUM(Commission) Commission
	 ,COUNT(DISTINCT rm.DateID) Months
  FROM MI.RetailerReportMetric rm
  INNER JOIN #OldPartners d ON rm.PartnerID=d.PartnerID AND d.CumulativeTypeID=@CumulativeTypeID AND d.DateID<@DateID
  WHERE rm.DateID BETWEEN d.StartMonthID AND d.DateID
  AND rm.CumulativeTypeID=0
  GROUP BY rm.ProgramID
      ,rm.PartnerGroupID
      ,rm.PartnerID
      ,rm.ClientServiceRef
      ,rm.PaymentTypeID
      ,rm.ChannelID
      ,rm.CustomerAttributeID
      ,rm.Mid_SplitID
      ,d.CumulativeTypeID 
      ,rm.PeriodTypeID
      ,d.DateID   

Update MI.RetailerReportMetric
SET Sales=n.Sales,
Transactions=n.Transactions
--Commission=n.Commission
FROM MI.RetailerReportMetric rm
INNER JOIN #NewValues n 
ON rm.ProgramID=n.ProgramID
AND rm.PartnerGroupID=n.PartnerGroupID
AND rm.PartnerID=n.PartnerID
AND rm.ClientServiceRef=n.ClientServiceRef
AND rm.PaymentTypeID=n.PaymentTypeID
AND rm.ChannelID=n.ChannelID
AND rm.CustomerAttributeID=n.CustomerAttributeID
AND rm.Mid_SplitID=n.Mid_SplitID
AND rm.CumulativeTypeID=n.CumulativeTypeID
AND rm.PeriodTypeID=n.PeriodTypeID
AND rm.DateID=n.DateID


INSERT INTO  MI.RetailerReportMetric (ProgramID
,PartnerGroupID
,PartnerID
,ClientServiceRef
,PaymentTypeID
,ChannelID
,CustomerAttributeID
,Mid_SplitID
,CumulativeTypeID
,PeriodTypeID
,DateID
,CurrencyAdj 
,CurrencyID
,Sales
,Transactions)
SELECT ProgramID
,PartnerGroupID
,PartnerID
,ClientServiceRef
,PaymentTypeID
,ChannelID
,CustomerAttributeID
,Mid_SplitID
,CumulativeTypeID
,PeriodTypeID
,DateID
,CurencyAdj 
,CurencyID
,Sales
,Transactions
FROM #NewValues n
WHERE not exists 
(SELECT 1 FROM MI.RetailerReportMetric rm 
WHERE rm.ProgramID=n.ProgramID
AND rm.PartnerGroupID=n.PartnerGroupID
AND rm.PartnerID=n.PartnerID
AND rm.ClientServiceRef=n.ClientServiceRef
AND rm.PaymentTypeID=n.PaymentTypeID
AND rm.ChannelID=n.ChannelID
AND rm.CustomerAttributeID=n.CustomerAttributeID
AND rm.Mid_SplitID=n.Mid_SplitID
AND rm.CumulativeTypeID=n.CumulativeTypeID
AND rm.PeriodTypeID=n.PeriodTypeID
AND rm.DateID=n.DateID) and n.CustomerAttributeID not in (1,2,3,4,1004,2004)

DROP TABLE #NewValues
DROP TABLE #OldPartners


-- Added on 05/08/2015 DW, as CustomerTemp table created incorrectly and ww insert rubish rows.
-- It removes rows we don't need to stroe
DELETE FROM  Warehouse.MI.RetailerReportMetric
WHERE CustomerAttributeID between 1 and 999
ANd CumulativeTypeID NOT IN (0)

DELETE FROM  Warehouse.MI.RetailerReportMetric
WHERE CustomerAttributeID between 1001 and 1999
ANd CumulativeTypeID NOT IN (0,1)

DELETE FROM Warehouse.MI.RetailerReportMetric
WHERE CustomerAttributeID between 2001 and 2999
ANd CumulativeTypeID NOT IN (0,2)

DELETE FROM Warehouse.MI.RetailerReportMetric
WHERE CustomerAttributeID between 3001 and 3999
ANd CumulativeTypeID NOT IN (0,2)

END