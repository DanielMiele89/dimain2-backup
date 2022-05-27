-- =============================================
-- Author:		JEA
-- Create date: 20/11/2014
-- Description:	Retailer Reports - information for the last month
-- =============================================
CREATE PROCEDURE [MI].[Retailer_MIDSplitChartInfo] 
	(
		@PartnerID INT
		, @ClientServiceRef NVARCHAR(30)
		, @MonthID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

	SELECT s.MonthID
		  ,s.MonthDesc
		  ,s.StatusTypeID
		  ,s.StatusTypeDesc
		  ,RM.UpliftSales
		  ,s.Use_For_Report
		  ,s.Colour
	FROM
	(
		SELECT RM.DateID
			  ,RM.Mid_SplitID
			  ,RM.UpliftSales
		FROM MI.RetailerReportMetric RM
		WHERE RM.PartnerID = @PartnerID 
			AND RM.ClientServiceRef = @ClientServiceRef 
			AND RM.PaymentTypeID = 0 
			AND RM.ChannelID = 0 
			AND RM.CustomerAttributeID = 0
			AND RM.PeriodTypeID = 1
			AND RM.CumulativeTypeID = 0
	) RM
	RIGHT OUTER JOIN ( --an entry must be returned for every mid split for the partner for the last six months, even if empty
				SELECT m.MonthID
				, m.MonthDesc
				, s.StatusTypeID
				, s.StatusTypeDesc
				, s.Use_For_Report
				, s.Colour
				, s.Mid_SplitID
			FROM
			( --mid splits for the partner
				SELECT s.MID_SplitID
					, s.StatusPosition AS StatusTypeID
					, s.StatusDescription AS StatusTypeDesc
					, s.SplitPosition AS Use_For_Report
					, c.Colour
				FROM MI.RetailerReportMID_Split s
				INNER JOIN MI.RetailerReportSplitMonthly_Colours c 
					ON s.StatusPosition = c.Status_Use_For_Report
					AND s.SplitPosition = c.Split_Use_For_Report
				WHERE s.PartnerID = @PartnerID
			) s
			CROSS JOIN
			( --the last six months
				SELECT ID AS MonthID
					, MonthDesc
				FROM Relational.SchemeUpliftTrans_Month
				WHERE ID BETWEEN @MonthID - 5 AND @MonthID
			) m
		) s ON RM.DateID = s.MonthID
			AND RM.Mid_SplitID = s.Mid_SplitID

END
