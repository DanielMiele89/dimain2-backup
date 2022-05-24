-- =============================================
-- Author:		JEA
-- Create date: 21/11/2014
-- Description:	Partner summary information for Retailer Summary Report
-- =============================================
CREATE PROCEDURE [MI].[Retailer_PartnerSummaryInfo] 
	(
		@MonthID INT
		, @CumulativeTypeID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

	CREATE TABLE #MultiPartner(PartnerID INT PRIMARY KEY)

	INSERT INTO #MultiPartner(PartnerID)
	SELECT PartnerID
	FROM
	(
		SELECT PartnerID, COUNT(DISTINCT ClientServiceRef) AS RefCount
		FROM MI.RetailerReportMetric 
		WHERE PaymentTypeID = 0 
		  AND ChannelID = 0 
		  AND CustomerAttributeID = 0
		  AND Mid_SplitID = 0 
		  AND CumulativeTypeID = 0
		  AND PeriodTypeID = 1
		  AND DateID = @MonthID
		GROUP BY PartnerID
		HAVING COUNT(DISTINCT ClientServiceRef) > 1
	) P

	SELECT SUTM.MonthDesc
		  ,p.PartnerID
		  ,p.PartnerName + CASE WHEN mp.PartnerID IS NULL THEN '' ELSE ' ' + cum.ClientServiceRef END AS PartnerName
		  ,RM.UpliftSales
		  ,RM.Sales
		  ,RM.IncrementalSpenders
		  ,RM.Spenders
		  ,RM.IncrementalSales
		  ,RM.IncrementalSalesROI
		  ,RM.FinancialROI
		  ,RM.Commission
		  ,cum.Margin
		  ,cum.ClientServiceRef
		  ,RM.IncrementalMargin
		  ,cum.UpliftSales AS UpliftSalesCumul
		  ,cum.Sales AS SalesCumul
		  ,cum.IncrementalSpenders AS IncrementalSpendersCumul
		  ,cum.Spenders AS SpendersCumul
		  ,cum.IncrementalSales AS IncrementalSalesCumul
		  ,cum.IncrementalSalesROI AS IncrementalSalesROICumul
		  ,cum.FinancialROI AS FinancialROICumul
		  ,cum.Commission AS CommissionCumul
		  ,cum.IncrementalMargin AS IncrementalMarginCumul
		  ,cum.ContractROI
		  ,cum.ContractTargetUplift
		  ,cum.RewardTargetUplift
	  FROM MI.RetailerReportMetric cum
	  INNER JOIN Relational.[Partner] p ON cum.PartnerID = p.PartnerID
	  INNER JOIN Relational.SchemeUpliftTrans_Month SUTM on cum.DateID = SUTM.ID
	  LEFT OUTER JOIN #MultiPartner mp ON cum.PartnerID = mp.PartnerID
	  LEFT OUTER JOIN (SELECT RM.PartnerID
						,RM.UpliftSales
						,RM.Sales
						,RM.IncrementalSpenders
						,RM.Spenders
						,RM.IncrementalSales
						,RM.IncrementalSalesROI
						,RM.FinancialROI
						,RM.Commission
						,RM.ClientServiceRef
						,RM.IncrementalMargin
					FROM MI.RetailerReportMetric RM
					WHERE PaymentTypeID = 0 
					  AND ChannelID = 0 
					  AND CustomerAttributeID = 0
					  AND Mid_SplitID = 0 
					  AND CumulativeTypeID = 0
					  AND PeriodTypeID = 1
					  AND DateID = @MonthID) RM ON rm.PartnerID = cum.PartnerID AND rm.ClientServiceRef = cum.ClientServiceRef
	  WHERE PaymentTypeID = 0 
	  AND ChannelID = 0 
	  AND CustomerAttributeID = 0
	  AND Mid_SplitID = 0 
	  AND CumulativeTypeID = @CumulativeTypeID
	  AND PeriodTypeID = 1
	  AND DateID = @MonthID
	  AND RM.UpliftSales IS NOT NULL

END