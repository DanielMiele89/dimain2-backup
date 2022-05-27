-- =============================================
-- Author:		JEA
-- Create date: 21/11/2014
-- Description:	Partner summary information for Retailer Summary Report
-- =============================================
CREATE PROCEDURE [MI].[Retailer_PartnerSummaryCoreInfo] 
	(
		@MonthID INT
		, @CumulativeTypeID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

	SELECT SUTM.MonthDesc
		  ,p.PartnerID
		  ,p.PartnerName
		  ,RM.UpliftSales
		  ,RM.Sales
		  ,RM.IncrementalSales
		  ,RM.IncrementalSalesROI
		  ,RM.FinancialROI
		  ,RM.Commission
		  ,RM.ClientServiceRef
		  ,RM.IncrementalMargin
		  ,cum.UpliftSales AS UpliftSalesCumul
		  ,cum.Sales AS SalesCumul
		  ,cum.IncrementalSales AS IncrementalSalesCumul
		  ,cum.IncrementalSalesROI AS IncrementalSalesROICumul
		  ,cum.Commission AS CommissionCumul
		  ,cum.IncrementalMargin AS IncrementalMarginCumul
	  FROM MI.RetailerReportMetric RM
	  INNER JOIN Relational.[Partner] p ON RM.PartnerID = p.PartnerID
	  INNER JOIN Relational.SchemeUpliftTrans_Month SUTM on RM.DateID = SUTM.ID
	  INNER JOIN (SELECT RM.PartnerID
						,RM.UpliftSales
						,RM.Sales
						,RM.IncrementalSales
						,RM.IncrementalSalesROI
						,RM.Commission
						,RM.IncrementalMargin
					FROM MI.RetailerReportMetric RM
					WHERE PaymentTypeID = 0 
					  AND ChannelID = 0 
					  AND CustomerAttributeID = 0
					  AND Mid_SplitID = 0 
					  AND CumulativeTypeID = @CumulativeTypeID
					  AND PeriodTypeID = 1
					  AND ClientServiceRef = '0' --CORE
					  AND DateID = @MonthID) cum ON rm.PartnerID = cum.PartnerID
	  WHERE PaymentTypeID = 0 
	  AND ChannelID = 0 
	  AND CustomerAttributeID = 0
	  AND Mid_SplitID = 0 
	  AND CumulativeTypeID = 0
	  AND PeriodTypeID = 1
	  AND ClientServiceRef = '0' --CORE
	  AND DateID = @MonthID
	  AND RM.UpliftSales IS NOT  NULL

END
