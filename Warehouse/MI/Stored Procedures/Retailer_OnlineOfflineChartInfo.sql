-- =============================================
-- Author:		JEA
-- Create date: 19/11/2014
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[Retailer_OnlineOfflineChartInfo]
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
		, RM.InStoreUpliftSales
		, RM.OnlineUpliftSales
	FROM
	(
		SELECT RM.DateID
			, SUM(CASE WHEN RM.ChannelID = 1 THEN RM.UpliftSales ELSE 0 END) AS InStoreUpliftSales
			, SUM(CASE WHEN RM.ChannelID = 2 THEN RM.UpliftSales ELSE 0 END) AS OnlineUpliftSales
		FROM MI.RetailerReportMetric RM
		INNER JOIN MI.RetailerMetricChannelTypes c ON RM.ChannelID = c.ChannelID AND RM.ProgramID = c.ProgramID
		WHERE PartnerID = @PartnerID 
		AND ClientServiceRef = @ClientServiceRef 
		AND PaymentTypeID = 0  
		AND CustomerAttributeID = 0
		AND Mid_SplitID = 0 
		AND CumulativeTypeID = 0  -- change for cumulative
		AND PeriodTypeID = 1
		AND RM.ChannelID > 0
		GROUP BY RM.DateID
	) RM
	RIGHT OUTER JOIN Relational.SchemeUpliftTrans_Month SUTM on RM.DateID = SUTM.ID
	WHERE SUTM.ID BETWEEN  @MonthID -5 and @MonthID

END