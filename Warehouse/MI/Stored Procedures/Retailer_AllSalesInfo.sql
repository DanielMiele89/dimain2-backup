
-- =============================================
-- Author:		JEA
-- Create date: 19/11/2014
-- Description:	Retailer Reports - information for the last month
-- =============================================
CREATE PROCEDURE [MI].[Retailer_AllSalesInfo] 
	(
		@PartnerID INT
		, @ClientServiceRef NVARCHAR(30)
		, @MonthID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

	SELECT SUTM.MonthDesc
		,RM.Cardholders
		,RM.Sales
		,RM.Transactions
		,RM.Spenders
		,RM.Commission
		,RM.UpliftSales
		,RM.UpliftTransactions
		,RM.UpliftSpenders
		,RM.IncrementalSales
		,RM.ATVUplift
		,RM.ATFUplift
		,RM.CostPerAcquisition
		,RM.TotalSalesROI
		,RM.IncrementalSalesROI
		,RM.FinancialROI
		,RM.ATV
		,RM.ATF
		,RM.DriverTreeRRIncremental
		,RM.DriverTreeATVIncremental
		,RM.DriverTreeATFIncremental
		,RM.IncrementalMargin
		,RM.IncrementalSpenders
	FROM MI.RetailerReportMetric RM
	INNER JOIN Relational.SchemeUpliftTrans_Month SUTM on RM.DateID = SUTM.ID
	WHERE PartnerID = @PartnerID 
	AND ClientServiceRef = @ClientServiceRef 
	AND PaymentTypeID = 0 
	AND ChannelID = 0 
	AND CustomerAttributeID = 0
	AND Mid_SplitID = 0 
	AND CumulativeTypeID = 0  -- change for cumulative
	AND PeriodTypeID = 1
	AND DateID = @MonthID

END

