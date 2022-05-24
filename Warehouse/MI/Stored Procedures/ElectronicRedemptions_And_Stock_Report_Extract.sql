/******************************************************************************
-- Author:		Jason Shipp
-- Create date: 31/05/2017
-- Description:	Extract data from MI.ElectronicRedemptions_And_Stock table for eVoucher Usage Report

-- Alteration History:
	-- Jason Shipp 30/01/2018: Added value to fetch, for ordering results in SSRS within retailer groups

-- Jason Shipp 07/06/2018
	-- Added override to item description for Pizza Express so gift code / eGift card results are merged in the report

-- Jason Shipp 07/06/2018
	-- Restructured logic so unique items from all time are fetched first, before being joined to the most recent report data

-- Jason Shipp 27/03/2020
	-- Added item cost (to Reward) to fetch, using Warehouse.Staging.RedemptionItem_CommercialTerms table (this table is manually maintained)

-- Rory Francis 19/04/20201
	-- ItemCostToReward changed to use RewardCost rather than CustomerCost

******************************************************************************/

CREATE PROCEDURE [MI].[ElectronicRedemptions_And_Stock_Report_Extract]
	
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @MaxReportDate DATE = (SELECT MAX(ReportDate) FROM MI.ElectronicRedemptions_And_Stock);

	WITH Items AS (
		SELECT DISTINCT 
		d.PartnerID
		, CASE 
			WHEN d.PartnerID = 1000003 AND d.RedemptionDescription LIKE '%15%Pizza%Express%10%' 
			THEN '£15 PizzaExpress gift code/ eGift card for £10 Rewards'
			ELSE d.RedemptionDescription
		END AS RedemptionDescription
		, d.ItemID
		, weeks.WeekStart
		, weeks.WeekEnd
		, weeks.WeekID
		FROM MI.ElectronicRedemptions_And_Stock d
		CROSS JOIN 
			(SELECT DISTINCT WeekStart, WeekEnd, WeekID FROM MI.ElectronicRedemptions_And_Stock WHERE ReportDate = @MaxReportDate) weeks
	), ItemCosts AS (
		SELECT
		ct.RedeemID
		, MAX(COALESCE(ct.RewardCost, 0)) AS ItemCostToReward	--	CustomerCost replaced with RewardCost 20210414
		FROM Warehouse.Staging.RedemptionItem_CommercialTerms ct
		INNER JOIN
				(SELECT 
				ct2.RedeemID
				, MAX(ct2.StartDate) AS MaxStartDate
				FROM Warehouse.Staging.RedemptionItem_CommercialTerms ct2
				GROUP BY
				ct2.RedeemID
				) x
			ON ct.RedeemID = x.RedeemID
			AND (ct.StartDate = x.MaxStartDate OR ct.StartDate IS NULL AND x.MaxStartDate IS NULL)
		GROUP BY
		ct.RedeemID
	)
	SELECT 
		@MaxReportDate AS ReportDate
		, i.PartnerID
		, p.PartnerName
		, CASE WHEN -- Check if result is numeric, to avoid conversion error is SSRS
				ISNUMERIC(
					LEFT( -- Fetch first float in description column, for ordering rows in SSRS report
						SUBSTRING(i.RedemptionDescription, PATINDEX('%£[0-9.-]%', i.RedemptionDescription)+1, 8000)
						, PATINDEX('%[^0-9.-]%', SUBSTRING(
							i.RedemptionDescription, PATINDEX('%£[0-9.-]%', i.RedemptionDescription)+1, 8000
						)+'X')-1
					)
				) =1
			THEN 
				CAST(
					LEFT( -- Fetch first float in description column, for ordering rows in SSRS report
							SUBSTRING(i.RedemptionDescription, PATINDEX('%£[0-9.-]%', i.RedemptionDescription)+1, 8000)
							, PATINDEX('%[^0-9.-]%', SUBSTRING(
								i.RedemptionDescription, PATINDEX('%£[0-9.-]%', i.RedemptionDescription)+1, 8000
							)+'X')-1
					)
				AS FLOAT
				)
			ELSE 0.0
		END AS SubPartnerOrder
		, partner_colours.ColourHexCode
		, i.ItemID
		, i.RedemptionDescription
		, d.ID
		, i.WeekStart
		, i.WeekEnd
		, i.WeekID
		, d.eVouchRedemptions
		, d.eVouchRedemptionsMonthlyAverage
		, d.Current_eCodes_In_stock
		, SUM(d.eVouchRedemptions) OVER (PARTITION BY i.PartnerID, i.ItemID, i.RedemptionDescription) AS ItemTotalRedemptions
		, COALESCE(ic.ItemCostToReward, 0) AS ItemCostToReward
	FROM Items i
	LEFT JOIN
			(SELECT 
			d.ID
			, d.ReportDate
			, d.WeekStart
			, d.WeekEnd
			, WeekID
			, d.PartnerID
			, d.ItemID
			, d.RedemptionDescription
			, d.eVouchRedemptions
			, d.eVouchRedemptionsMonthlyAverage
			, d.Current_eCodes_In_stock
			FROM MI.ElectronicRedemptions_And_Stock d
			WHERE d.ReportDate = @MaxReportDate	
			) d
		ON i.ItemID = d.ItemID
		AND i.RedemptionDescription = d.RedemptionDescription
		AND i.PartnerID = d.PartnerID
		AND i.WeekStart = d.WeekStart
		AND i.WeekEnd = d.WeekEnd
		AND i.WeekID = d.WeekID
	LEFT JOIN ItemCosts ic
		ON i.ItemID = ic.RedeemID
	LEFT JOIN Relational.[Partner] p
		ON i.PartnerID = p.PartnerID
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
					FROM MI.ElectronicRedemptions_And_Stock
					) UniquePartners
				INNER JOIN Relational.Partner p on UniquePartners.PartnerID = p.PartnerID
				) partner_fake_id
			INNER JOIN APW.ColourList cl ON partner_fake_id.Fake_ID = cl.ID
			) partner_colours
		ON i.PartnerID = partner_colours.PartnerID;

END
GO
GRANT EXECUTE
    ON OBJECT::[MI].[ElectronicRedemptions_And_Stock_Report_Extract] TO [BIDIMAINReportUser]
    AS [dbo];

