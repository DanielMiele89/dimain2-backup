-- =============================================
-- Author:		JEA
-- Create date: 18/11/2014
-- Description:	Retailer Reports - cumulative totals
-- =============================================
CREATE PROCEDURE [MI].[Retailer_TotalCumulativeInfo] 
	(
		@PartnerID INT
		, @ClientServiceRef NVARCHAR(30)
		, @MonthID INT
		, @CumulativeTypeID INT
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
		,RM.ATV
		,RM.ATF
		,RM.RR
		,RM.CostPerAcquisition
		,RM.TotalSalesROI
		,RM.UpliftSales
		,RM.UpliftTransactions
		,RM.UpliftSpenders
		,RM.IncrementalSales
		,RM.ATVUplift
		,RM.ATFUplift
		,RM.IncrementalSalesROI
		,RM.FinancialROI
		,RM.IncrementalSpenders
		,RM.DriverTreeRRIncremental
		,RM.DriverTreeATVIncremental
		,RM.DriverTreeATFIncremental
		,RM.IncrementalMargin
	FROM MI.RetailerReportMetric RM
	INNER JOIN Relational.SchemeUpliftTrans_Month SUTM on RM.DateID = SUTM.ID
	WHERE PartnerID = @PartnerID 
	AND ClientServiceRef = @ClientServiceRef 
	AND PaymentTypeID = 0 
	AND ChannelID = 0 
	AND CustomerAttributeID = 0
	AND Mid_SplitID = 0 
	AND CumulativeTypeID = @CumulativeTypeID
	AND PeriodTypeID = 1
	AND DateID = @MonthID

END