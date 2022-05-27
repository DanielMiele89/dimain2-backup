-- =============================================
-- Author:		JEA
-- Create date: 20/11/2014
-- Description:	Retailer Reports - information for the last month
-- =============================================
CREATE PROCEDURE [MI].[Retailer_MIDSplitChartCumulativeInfo] 
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
		  ,SUTM.MonthDesc
		  ,s.StatusPosition AS StatusTypeID
		  ,S.StatusDescription AS StatusTypeDesc
		  ,RM.UpliftSales
		  ,RM.Sales
		  ,s.SplitPosition AS Use_For_Report
		  ,c.Colour
	FROM MI.RetailerReportMetric RM
	INNER JOIN Relational.SchemeUpliftTrans_Month SUTM on RM.DateID = SUTM.ID
	INNER JOIN MI.RetailerReportMID_Split s ON RM.Mid_SplitID = S.Mid_SplitID
	INNER JOIN MI.RetailerReportSplitMonthly_Colours c ON s.StatusPosition = c.Status_Use_For_Report
		AND s.SplitPosition = c.Split_Use_For_Report
	WHERE RM.PartnerID = @PartnerID 
		AND RM.ClientServiceRef = @ClientServiceRef 
		AND RM.PaymentTypeID = 0 
		AND RM.ChannelID = 0 
		AND RM.CustomerAttributeID = 0
		AND RM.PeriodTypeID = 1
		AND RM.CumulativeTypeID = @CumulativeTypeID
		AND RM.DateID = @MonthID

END
