-- =============================================
-- Author:		JEA
-- Create date: 28/11/2014
-- Description:	Returns significance values for partner measures
-- =============================================
CREATE PROCEDURE [MI].[Retailer_PartnerSummarySignificance]
	(
		@MonthID INT
		, @CumulativeTypeID INT
	)
AS
BEGIN
	
	SET NOCOUNT ON;

    CREATE TABLE #MultiPartner(PartnerID INT PRIMARY KEY)

	INSERT INTO #MultiPartner(PartnerID)
	SELECT PartnerID
	FROM
	(
		SELECT PartnerID, COUNT(DISTINCT ClientServiceRef) AS RefCount
		FROM MI.RetailerReportSignificance 
		WHERE PaymentTypeID = 0 
		  AND ChannelID = 0 
		  AND CustomerAttributeID = 0
		  AND Mid_SplitID = 0 
		  AND CumulativeTypeID = 0
		  AND PeriodTypeID = 1
		  AND DateID = @MonthID
		GROUP BY PartnerID
		HAVING COUNT(DISTINCT ClientServiceRef) > 1
	) P

	SELECT p.PartnerName + CASE WHEN mp.PartnerID IS NULL THEN '' ELSE ' ' + m.ClientServiceRef END AS PartnerName
		, p.PartnerID
		, m.ClientServiceRef
		, m.UpliftSales
		, m.UpliftSales_Significance
		, m.UpliftSales_LowerBond80 AS UpliftSales_LowerBond
		, m.UpliftSales_UpperBond80 AS UpliftSales_UpperBond
		, m.UpliftRR
		, m.UpliftSpenders_Significance
		, m.UpliftSPS
		, m.UpliftSPS_Significance
		, c.UpliftSales AS UpliftSalesCumul
		, c.UpliftSales_Significance AS UpliftSales_SignificanceCumul
		, c.UpliftSales_LowerBond80 AS UpliftSales_LowerBondCumul
		, c.UpliftSales_UpperBond80 AS UpliftSales_UpperBondCumul
		, c.UpliftRR AS UpliftRRCumul
		, c.UpliftSpenders_Significance AS UpliftSpenders_SignificanceCumul
		, c.UpliftSPS AS UpliftSPSCumul
		, c.UpliftSPS_Significance AS UpliftSPS_SignificanceCumul
	FROM
	(
	SELECT UpliftSales
		, UpliftSales_Significance
		, UpliftSales_LowerBond80
		, UpliftSales_UpperBond80
		, UpliftSpenders AS UpliftRR
		, UpliftSpenders_Significance
		, UpliftSPS
		, UpliftSPS_Significance
		, PartnerID
		, ClientServiceRef
	FROM MI.RetailerReportSignificance
	WHERE PaymentTypeID = 0
		AND ChannelID = 0
		AND CustomerAttributeID = 0
		AND MID_SplitID = 0
		AND CumulativeTypeID = 0
		AND PeriodTypeID = 1
		AND DateID = @MonthID
	) m
	INNER JOIN
	(
	SELECT UpliftSales
		, UpliftSales_Significance
		, UpliftSales_LowerBond80
		, UpliftSales_UpperBond80
		, UpliftSpenders AS UpliftRR
		, UpliftSpenders_Significance
		, UpliftSPS
		, UpliftSPS_Significance
		, PartnerID
		, ClientServiceRef
	FROM MI.RetailerReportSignificance
	WHERE PaymentTypeID = 0
		AND ChannelID = 0
		AND CustomerAttributeID = 0
		AND MID_SplitID = 0
		AND CumulativeTypeID = @CumulativeTypeID
		AND PeriodTypeID = 1
		AND DateID = @MonthID
		AND ClientServiceRef != 'PH003'
	) c ON m.PartnerID = c.PartnerID
		AND m.ClientServiceRef = c.ClientServiceRef
	INNER JOIN Relational.[Partner] p ON m.PartnerID = p.PartnerID
	LEFT OUTER JOIN #MultiPartner mp ON p.PartnerID = mp.PartnerID

END
