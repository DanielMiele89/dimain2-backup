-- =============================================
-- Author:		JEA
-- Create date: 18/11/2014
-- Description:	Retailer Reports - totals for last six months
-- =============================================
CREATE PROCEDURE [MI].[Retailer_TotalSixMonthsInfo] 
	(
		@PartnerID INT
		, @ClientServiceRef NVARCHAR(30)
		, @MonthID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

	SELECT SUTM.ID AS MonthID 
		, SUTM.MonthDesc
		,RM.Cardholders
		,RM.Sales
		,RM.Transactions
		,RM.Spenders
		,RM.Commission
		,RM.ATV
		,RM.ATF
		,RM.RR
		,RM.CostPerAcquisition
		,RM.TotalSalesROI
		,RM.IncrementalSales
		,RM.IncrementalSalesROI
		,RM.FinancialROI
		,RM.UpliftSales
		,RM.UpliftTransactions
		,RM.UpliftSpenders
		,RM.ATVUplift
		,RM.ATFUplift
	FROM (SELECT RM.Cardholders
			,RM.Sales
			,RM.Transactions
			,RM.Spenders
			,RM.Commission
			,RM.ATV
			,RM.ATF
			,RM.RR
			,RM.CostPerAcquisition
			,RM.TotalSalesROI
			,RM.IncrementalSales
			,RM.IncrementalSalesROI
			,RM.FinancialROI
			,RM.UpliftSales
			,RM.UpliftTransactions
			,RM.UpliftSpenders
			,RM.ATVUplift
			,RM.ATFUplift
			,RM.DateID
			FROM MI.RetailerReportMetric RM
			WHERE PartnerID = @PartnerID 
			AND ClientServiceRef = @ClientServiceRef 
			AND PaymentTypeID = 0 
			AND ChannelID = 0 
			AND CustomerAttributeID = 0
			AND Mid_SplitID = 0 
			AND CumulativeTypeID = 0  -- change for cumulative
			AND PeriodTypeID = 1) RM
	RIGHT OUTER JOIN Relational.SchemeUpliftTrans_Month SUTM on RM.DateID = SUTM.ID
	WHERE SUTM.ID BETWEEN  @MonthID -5 and @MonthID

END
