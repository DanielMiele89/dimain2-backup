-- =============================================
-- Author:		JEA
-- Create date: 20/11/2014
-- Description:	Retailer Reports - information for the last month
-- =============================================
CREATE PROCEDURE [MI].[Retailer_MIDSplitInfo] 
	(
		@PartnerID INT
		, @ClientServiceRef NVARCHAR(30)
		, @MonthID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

	SELECT SUTM.MonthDesc
		  ,s.StatusPosition AS StatusTypeID
		  ,S.StatusDescription AS StatusTypeDesc
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
		  ,RM.CumulativeTypeID
		  ,s.SplitPosition AS Use_For_Report
	FROM MI.RetailerReportMetric RM
	INNER JOIN Relational.SchemeUpliftTrans_Month SUTM on RM.DateID = SUTM.ID
	INNER JOIN MI.RetailerReportMID_Split s ON RM.Mid_SplitID = S.Mid_SplitID
	WHERE RM.PartnerID = @PartnerID 
		AND RM.ClientServiceRef = @ClientServiceRef 
		AND RM.PaymentTypeID = 0 
		AND RM.ChannelID = 0 
		AND RM.CustomerAttributeID = 0
		AND RM.PeriodTypeID = 1
		AND RM.DateID = @MonthID

END