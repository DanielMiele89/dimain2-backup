-- =============================================
-- Author:		JEA
-- Create date: 19/11/2014
-- Description:	Retailer Reports - totals for online/offline
-- =============================================
CREATE PROCEDURE [MI].[Retailer_OnlineOfflineInfo] 
	(
		@PartnerID INT
		, @ClientServiceRef NVARCHAR(30)
		, @MonthID INT
		, @CumulativeTypeID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

	SELECT SUTM.ID AS MonthID 
		, SUTM.MonthDesc
		,C.[Description] AS ChannelDesc
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
		,RM.ChannelID
	FROM MI.RetailerReportMetric RM
	INNER JOIN Relational.SchemeUpliftTrans_Month SUTM on RM.DateID = SUTM.ID
	INNER JOIN MI.RetailerMetricChannelTypes c ON RM.ChannelID = c.ChannelID  AND RM.ProgramID = c.ProgramID
	WHERE PartnerID = @PartnerID 
	AND ClientServiceRef = @ClientServiceRef 
	AND PaymentTypeID = 0 
	AND CustomerAttributeID = 0
	AND Mid_SplitID = 0 
	AND CumulativeTypeID = @CumulativeTypeID
	AND PeriodTypeID = 1
	AND DateID = @MonthID
	AND RM.ChannelID > 0

END
