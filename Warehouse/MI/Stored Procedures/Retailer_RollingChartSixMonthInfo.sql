
-- =============================================
-- Author:		JEA
-- Create date: 24/11/2014
-- Description:	Retailer Reports - information for the last six months by rolling new/lapsed/existing
-- =============================================
CREATE PROCEDURE [MI].[Retailer_RollingChartSixMonthInfo] 
	(
		@PartnerID INT
		, @ClientServiceRef NVARCHAR(30)
		, @MonthID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

	CREATE TABLE #Colours(CustomerAttributeID INT PRIMARY KEY, Colour VARCHAR(8) NOT NULL)

	INSERT INTO #Colours(CustomerAttributeID, Colour)
	VALUES(1, '#00D2DC')
		, (2, '#0055A0')
		, (3, '#0AB4F0')
		, (4, '#0055A0')

	SELECT SUTM.ID AS MonthID
		, SUTM.MonthDesc
		, isnull(RM.CustomerAttributeID,1) as CustomerAttributeID
		, isnull(RM.NLEStatus, 'New') as NLEStatus
		, isnull(RM.Colour,'#00D2DC') as Colour
		, RM.Spenders
	FROM
	(
		SELECT RM.DateID
			, c.CustomerAttributeID
			,c.ReportDescription AS NLEStatus
			,cc.Colour
			,RM.Spenders
		FROM MI.RetailerReportMetric RM
		INNER JOIN MI.RetailerMetricCustomerAttribute c ON RM.CustomerAttributeID = c.CustomerAttributeID
		INNER JOIN #Colours cc ON c.CustomerAttributeID = cc.CustomerAttributeID
		WHERE PartnerID = @PartnerID 
		AND ClientServiceRef = @ClientServiceRef 
		AND PaymentTypeID = 0 
		AND ChannelID = 0 
		AND Mid_SplitID = 0 
		AND CumulativeTypeID = 0  -- change for cumulative
		AND PeriodTypeID = 1
		AND c.[Description] LIKE '%rolling%'
		and NOT (RM.PartnerID = 3960 and ( RM.CustomerAttributeID between 2 and 3))
	) RM
	RIGHT OUTER JOIN Relational.SchemeUpliftTrans_Month SUTM on RM.DateID = SUTM.ID
	WHERE SUTM.ID BETWEEN @MonthID -5 AND @MonthID

END

