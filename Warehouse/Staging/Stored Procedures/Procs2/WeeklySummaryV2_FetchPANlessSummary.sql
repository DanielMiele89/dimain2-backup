/******************************************************************************
Author: Jason Shipp
Created: 21/10/2019
Purpose: 
	- Fetch MTR/AMEX-type transaction data summary by weeks used in the latest Weekly Summary reports, for RPT
	- Note: This points to the PANless_Transaction view in SLC_REPORT as opposed to the live table in SLC_REPL, so the output will not be as up-to-date as the equivalent query for Finance

------------------------------------------------------------------------------
Modification History

Jason Shipp 29/01/2020
	- Added publisher linking using SLC_REPL.dbo.CRT_File table

******************************************************************************/
CREATE PROCEDURE [Staging].[WeeklySummaryV2_FetchPANlessSummary]

AS
BEGIN
	
	SET NOCOUNT ON;
	
	WITH PartnerAlternate AS ( -- Load alternate PartnerIDs 
		SELECT 
		PartnerID
		, AlternatePartnerID
		FROM Warehouse.APW.PartnerAlternate
		UNION
		SELECT 
		PartnerID
		, AlternatePartnerID
		FROM nFI.APW.PartnerAlternate
	), Staging AS (
		SELECT -- Load invoice summary data for non-standard publishers
			cal.RetailerID
			, cal.PeriodType
			, cal.StartDate
			, cal.EndDate
			, COALESCE(
				p.PublisherName
				, CASE f.MatcherShortName
					WHEN 'AMX' THEN 'American Express'
					WHEN 'VSA' THEN 'Visa'
					WHEN 'MTR' THEN 'MTR'
					WHEN 'HSB' THEN 'HSBC'
					WHEN 'VGN' THEN 'Virgin Money'
					ELSE f.MatcherShortName
				END
			) AS Publisher
			, SUM(COALESCE(pt.Price, 0)) AS Spend
			, SUM(COALESCE(pt.CashbackEarned, 0)) AS Cashback
			, SUM(COALESCE(pt.GrossAmount, 0)) - SUM(COALESCE(pt.VATAmount, 0)) AS Investment
			, SUM(COALESCE(pt.NetAmount - pt.CashbackEarned, 0)) AS [Override]
			, COUNT(pt.ID) AS Transactions
		FROM SLC_Report.RAS.PANless_Transaction pt
		LEFT JOIN PartnerAlternate alt
			ON pt.PartnerID = alt.PartnerID
		INNER JOIN Warehouse.Staging.WeeklySummaryV2_RetailerAnalysisPeriods cal
			ON CAST(pt.TransactionDate AS date) BETWEEN cal.StartDate AND cal.EndDate
			AND COALESCE(alt.AlternatePartnerID, pt.PartnerID) = cal.RetailerID
		LEFT JOIN Warehouse.Staging.AmexOfferStage_OfferNameToPublisher otp
			ON LEFT(pt.PublisherOfferCode, 3) = otp.OfferIDPrefix3
		LEFT JOIN Warehouse.APW.DirectLoad_PublisherIDs p
			ON otp.PublisherID = p.PublisherID
		LEFT JOIN SLC_REPL.dbo.CRT_File f
			ON pt.FileID = f.ID
		WHERE
			pt.FileID <> 20332 -- Duplicated from 20309, so ignore
			AND cal.PeriodType = 'Week'
		GROUP BY
			cal.RetailerID
			, cal.PeriodType
			, cal.StartDate
			, cal.EndDate
			, COALESCE(
				p.PublisherName
				, CASE f.MatcherShortName
					WHEN 'AMX' THEN 'American Express'
					WHEN 'VSA' THEN 'Visa'
					WHEN 'MTR' THEN 'MTR'
					WHEN 'HSB' THEN 'HSBC'
					WHEN 'VGN' THEN 'Virgin Money'
					ELSE f.MatcherShortName
				END
			)
	), Staging2 AS ( -- Load results plus retailers' total spend
		SELECT 
			p.Name AS Retailer
			, cal.PeriodType
			, cal.StartDate
			, cal.EndDate
			, COALESCE(s.Publisher, 'N/A') AS Publisher
			, COALESCE(s.Spend, 0) AS Spend
			, COALESCE(s.Cashback, 0) AS Cashback
			, COALESCE(s.Investment, 0) AS Investment
			, COALESCE(s.[Override], 0) AS [Override]
			, COALESCE(s.Transactions, 0) AS Transactions
			, SUM(s.Spend) OVER (PARTITION BY p.Name) AS TotalRetailerSpend
		FROM Warehouse.Staging.WeeklySummaryV2_RetailerAnalysisPeriods cal
		LEFT JOIN Staging s
			ON cal.RetailerID = s.RetailerID
			AND cal.StartDate = s.StartDate
			AND cal.EndDate = s.EndDate
		LEFT JOIN SLC_Report.dbo.[Partner] p 
			ON cal.RetailerID = p.ID
		WHERE
			cal.PeriodType = 'Week'
	)
	SELECT -- Fetch final results, only for retailers with spend in at least one of the weekly periods
		s.Retailer
		, s.PeriodType AS 'Period Type'
		, s.StartDate AS 'Start Date'
		, s.EndDate AS 'End Date'
		, s.Publisher
		, s.Spend
		, s.Cashback
		, s.Investment
		, s.[Override]
		, s.Transactions
	FROM Staging2 s
	WHERE 
		s.TotalRetailerSpend >0
	ORDER BY 
		s.Retailer
		, s.PeriodType
		, s.StartDate
		, s.EndDate
		, s.Publisher;

END