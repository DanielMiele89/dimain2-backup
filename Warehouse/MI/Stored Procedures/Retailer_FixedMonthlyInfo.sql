
-- =============================================
-- Author:		JEA
-- Create date: 24/11/2014
-- Description:	Retailer Reports - information for the last month by fixed new/lapsed/existing
-- =============================================
CREATE PROCEDURE [MI].[Retailer_FixedMonthlyInfo] 
	(
		@PartnerID INT
		, @ClientServiceRef NVARCHAR(30)
		, @MonthID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

	--RETURNS MONTHLY AND CUMULATIVE - FILTERS USED IN .rdl

	SELECT SUTM.MonthDesc
		, c.CustomerAttributeID
		,c.ReportDescription AS NLEStatus
		,RM.Cardholders
		,RM.Spenders
		,RM.Transactions
		,RM.Sales
		,RM.IncrementalSales
		,RM.TotalSalesROI
		,RM.IncrementalSalesROI
		,RM.Commission
		,RM.CumulativeTypeID
		,RM.UpliftSales
		,RM.UpliftSpenders
		,RM.ATFUplift
		,Rm.ATVUplift
	FROM MI.RetailerReportMetric RM
	INNER JOIN Relational.SchemeUpliftTrans_Month SUTM on RM.DateID = SUTM.ID
	INNER JOIN MI.RetailerMetricCustomerAttribute c ON RM.CustomerAttributeID = c.CustomerAttributeID
	WHERE PartnerID = @PartnerID 
	AND ClientServiceRef = @ClientServiceRef 
	AND PaymentTypeID = 0 
	AND ChannelID = 0 
	AND Mid_SplitID = 0 
	AND PeriodTypeID = 1
	AND DateID = @MonthID
	AND c.[Description] LIKE '%fixed%'
	and NOT (PartnerID = 3960 and (RM.CustomerAttributeID between 2002 and 2003 or RM.CustomerAttributeID between 1002 and 1003))

END

