-- =============================================
-- Author:		Jason Shipp
-- Create date: 08/02/2018
-- Description:	Extract data from MI.Weekly_Card_Redemptions table for eVoucher Usage Report

-- Alteration History:
-- =============================================

CREATE PROCEDURE MI.Card_Redemptions_Report_Extract
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @MaxReportDate DATE = (SELECT MAX(ReportDate) FROM MI.ElectronicRedemptions_And_Stock);

	SELECT 
		complete.ReportDate
		, complete.WeekStart
		, complete.WeekEnd
		, complete.WeekID
		, complete.PartnerID
		, p.PartnerName
		, partner_colours.ColourHexCode
		, complete.RedemptionDescription
		, CASE WHEN -- Check if result is numeric, to avoid conversion error is SSRS
			ISNUMERIC(
				LEFT( -- Fetch first float in description column, for ordering rows in SSRS report
					SUBSTRING(complete.RedemptionDescription, PATINDEX('%[0-9.-]%', complete.RedemptionDescription), 8000)
					, PATINDEX('%[^0-9.-]%', SUBSTRING(
						complete.RedemptionDescription, PATINDEX('%[0-9.-]%', complete.RedemptionDescription), 8000
					)+'X')-1
				)
			) =1
		THEN 
			CAST(
				LEFT( -- Fetch first float in description column, for ordering rows in SSRS report
						SUBSTRING(complete.RedemptionDescription, PATINDEX('%[0-9.-]%', complete.RedemptionDescription), 8000)
						, PATINDEX('%[^0-9.-]%', SUBSTRING(
							complete.RedemptionDescription, PATINDEX('%[0-9.-]%', complete.RedemptionDescription), 8000
						)+'X')-1
				)
			AS FLOAT
			)
		ELSE 0.0 END AS SubRetailerOrder
		, d.Redemptions
		, COALESCE(
			d.CurrentStockLevel
			, MAX(d.CurrentStockLevel) OVER(PARTITION BY complete.PartnerID, complete.RedemptionDescription ORDER BY complete.PartnerID, complete.RedemptionDescription)
		) AS CurrentStockLevel
	FROM 
		(SELECT
		DISTINCT
		d.ReportDate
		, d.WeekStart
		, d.WeekEnd
		, WeekID
		, descripts.PartnerID
		, descripts.RedemptionDescription
		FROM MI.Weekly_Card_Redemptions d
		CROSS JOIN
			(SELECT DISTINCT 
			d.PartnerID
			, d.RedemptionDescription
			FROM MI.Weekly_Card_Redemptions d
			) descripts
		WHERE d.ReportDate = @MaxReportDate
		) complete
	LEFT JOIN MI.Weekly_Card_Redemptions d
	ON d.ReportDate = complete.ReportDate
		AND d.WeekStart = complete.WeekStart
		AND d.WeekEnd = complete.WeekEnd
		AND d.WeekID = complete.WeekID
		AND d.PartnerID = complete.PartnerID
		AND d.RedemptionDescription = complete.RedemptionDescription
	LEFT JOIN Relational.Partner p
		ON complete.PartnerID = p.PartnerID
	LEFT JOIN 
			(SELECT 
			partner_fake_id.*
			, cl.ColourHexCode
			FROM
				(SELECT
				p.PartnerID
				, PartnerName
				, ROW_NUMBER() OVER (ORDER BY p.PartnerName) AS Fake_ID
				FROM 
					(SELECT DISTINCT	 
					PartnerID
					FROM MI.Weekly_Card_Redemptions					
					) UniquePartners
				INNER JOIN Relational.Partner p on UniquePartners.PartnerID = p.PartnerID
				) partner_fake_id
			INNER JOIN APW.ColourList cl ON partner_fake_id.Fake_ID = cl.ID
			) partner_colours
		ON complete.PartnerID = partner_colours.PartnerID
	WHERE complete.ReportDate = @MaxReportDate;

END