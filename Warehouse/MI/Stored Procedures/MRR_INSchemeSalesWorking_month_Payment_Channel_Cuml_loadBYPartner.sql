
-- =============================================
-- Author:		<Adam Scott>
-- Create date: <22/10/2014>
-- Description:	<loads INSchemeSalesWorking with monthly totals, monthly Payment totals, monthly Channel totals>
-- =============================================
CREATE PROCEDURE [MI].[MRR_INSchemeSalesWorking_month_Payment_Channel_Cuml_loadBYPartner]
	(
		@DateID INT, @PartnerID INT
	)
AS
BEGIN
	SET NOCOUNT ON;

SELECT DISTINCT 1 as Programid
	  ,0 as PartnerGroupID 
	  ,pt.[PartnerID]
	  ,pt.ClientServiceRef
	  ,CASE WHEN GROUPING(pt.PaymentTypeID)=1 THEN 0 ELSE pt.PaymentTypeID END as PaymentTypeID
	  ,CASE WHEN GROUPING(pt.ChannelID)=1 THEN 0 ELSE pt.ChannelID END as ChannelID
	  ,CASE WHEN GROUPING(pt.CustomerAttributeID_0)=1 THEN 0 ELSE pt.CustomerAttributeID_0 END as CustomerAttributeID_0
	  ,CASE WHEN GROUPING(pt.CustomerAttributeID_0BP)=1 THEN 0 ELSE pt.CustomerAttributeID_0BP END as CustomerAttributeID_0BP
	  ,CASE WHEN GROUPING(pt.CustomerAttributeID_1)=1 THEN 0 ELSE pt.CustomerAttributeID_1 END as CustomerAttributeID_1
	  ,CASE WHEN GROUPING(pt.CustomerAttributeID_1BP)=1 THEN 0 ELSE pt.CustomerAttributeID_1BP END as CustomerAttributeID_1BP
	  ,CASE WHEN GROUPING(pt.CustomerAttributeID_2)=1 THEN 0 ELSE pt.CustomerAttributeID_2 END as CustomerAttributeID_2
	  ,CASE WHEN GROUPING(pt.CustomerAttributeID_2BP)=1 THEN 0 ELSE pt.CustomerAttributeID_2BP END as CustomerAttributeID_2BP
	  ,CASE WHEN GROUPING(pt.CustomerAttributeID_3)=1 THEN 0 ELSE pt.CustomerAttributeID_3 END as CustomerAttributeID_3
	  ,CASE WHEN GROUPING(pt.Mid_SplitID)=1 THEN 0 ELSE pt.Mid_SplitID END as Mid_SplitID
	  ,pt.CumulativeTypeID
	  ,CAST(1 AS INT) AS PeriodTypeID
	  ,pt.DateID 
      ,SUM(pt.InSchemeSales) AS InSchemeSales
	  ,SUM(pt.InSchemeTransactions) as INSchemeTransactions
      ,Count(distinct PT.[FanID]) as InSchemeSpenders
	  ,SUM(pt.Commission) as Commission 
	  ,0 as Cardholders	 
INTO #Sales	
FROM MI.MRR_InSchemeSales_Working PT
GROUP BY pt.[PartnerID], pt.DateID,pt.ClientServiceRef,pt.CumulativeTypeID,
GROUPING SETS( 
(pt.PaymentTypeID,pt.ChannelID),
(pt.PaymentTypeID,pt.Mid_SplitID),
(pt.PaymentTypeID,pt.CustomerAttributeID_0),
(pt.PaymentTypeID,pt.CustomerAttributeID_0BP),
(pt.PaymentTypeID,pt.CustomerAttributeID_1),
(pt.PaymentTypeID,pt.CustomerAttributeID_1BP),
(pt.PaymentTypeID,pt.CustomerAttributeID_2),
(pt.PaymentTypeID,pt.CustomerAttributeID_2BP),
(pt.PaymentTypeID,pt.CustomerAttributeID_3),
(pt.PaymentTypeID),
(pt.ChannelID),
(pt.Mid_SplitID),
(pt.CustomerAttributeID_0),
(pt.CustomerAttributeID_0BP),
(pt.CustomerAttributeID_1),
(pt.CustomerAttributeID_1BP),
(pt.CustomerAttributeID_2),
(pt.CustomerAttributeID_2BP),
(pt.CustomerAttributeID_3),
())

INSERT INTO MI.INSchemeSalesWorking
SELECT DISTINCT p.[Programid]
      ,0 [PartnerGroupID]
      ,w.[PartnerID]
      ,w.[ClientServicesRef] [ClientServiceRef]
      ,p.PaymentID as  [PaymentTypeID]
      ,ch.[ChannelID]
      ,ca.[CustomerAttributeID]
      ,m.[Mid_SplitID]
      ,w.Cumlitivetype [CumulativeTypeID]
      ,1 [PeriodTypeID]
      ,w.[DateID]
      ,ISNULL(s.[INSchemeSales],0) [INSchemeSales]
      ,ISNULL(s.[INSchemeTransactions],0) [INSchemeTransactions]
      ,ISNULL(s.[INSchemeSpenders],0) [INSchemeSpenders]
      ,ISNULL(s.[Commission],0) [Commission]
      ,ISNULL(s.[Cardholders],0) [Cardholders]
FROM MI.WorkingCumlDates w 
CROSS JOIN MI.RetailerMetricPaymentypes p 
INNER JOIN MI.RetailerMetricCustomerAttribute ca ON (ca.CustomerAttributeID BETWEEN 3000 AND 3000+@Dateid)
OR (ca.CustomerAttributeID<3000 AND (w.Partnerid=3960 OR RIGHT(ca.CustomerAttributeID,1)<>4))
INNER JOIN MI.RetailerMetricChanneltypes ch ON p.ProgramID=ch.ProgramID
INNER JOIN (SELECT DISTINCT Mid_SplitID, PartnerID FROM Warehouse.MI.RetailerReportMID_Split
UNION SELECT DISTINCT 0 Mid_SplitID, PartnerID FROM MI.WorkingofferDates) m ON m.PartnerID=w.PartnerID
LEFT JOIN #Sales s ON s.Programid=p.Programid
			    AND s.PartnerGroupID=0
			    AND s.PartnerID=w.PartnerID
			    AND s.ClientServiceRef=w.ClientServicesRef
			    AND s.PaymentTypeID=p.PaymentID
			    AND s.ChannelID=ch.ChannelID
			    AND CASE WHEN s.CustomerAttributeID_0<>0 THEN CustomerAttributeID_0
			    WHEN s.CustomerAttributeID_0BP<>0 THEN CustomerAttributeID_0BP
			    WHEN s.CustomerAttributeID_1<>0 THEN CustomerAttributeID_1
			    WHEN s.CustomerAttributeID_1BP<>0 THEN CustomerAttributeID_1BP
			    WHEN s.CustomerAttributeID_2<>0 THEN CustomerAttributeID_2
			    WHEN s.CustomerAttributeID_2BP<>0 THEN CustomerAttributeID_2BP
			    ELSE s.CustomerAttributeID_3 END	=ca.CustomerAttributeID
			    AND s.Mid_SplitID=m.Mid_SplitID
			    AND s.PeriodTypeID=1
			    AND s.DateID=w.DateID
			    AND S.CumulativeTypeID=w.Cumlitivetype
WHERE (CASE WHEN ch.ChannelID=0 THEN 0 ELSE 1 END)+ (CASE WHEN m.Mid_SplitID=0 THEN 0 ELSE 1 END)+ 
(CASE WHEN ca.[CustomerAttributeID]=0 THEN 0 ELSE 1 END)<=1 
AND w.PartnerID=@partnerid
AND w.DateID = @DateID 
--and (MRT.core is null or MRT.core = 'y') 

DELETE FROM MI.INSchemeSalesWorking
WHERE CustomerAttributeID between 1 and 4 and CumulativeTypeID>0

DELETE FROM MI.INSchemeSalesWorking
WHERE CustomerAttributeID between 2001 and 2004 and CumulativeTypeID=1

DELETE FROM MI.INSchemeSalesWorking
WHERE CustomerAttributeID between 1001 and 1004 and CumulativeTypeID=2

DROP TABLE #Sales

END

