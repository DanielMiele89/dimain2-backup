/******************************************************************************
Author: Jason Shipp
Created: 18/09/2019
Purpose: 
	- Fetch invoice summary data, to support Finance's monthly financial reconciliation
	
------------------------------------------------------------------------------
Modification History

Jason Shipp 13/02/2020
	- Changed date logic to capture transactions invoiced (regardless of transaction date) in the last 3 complete months
	- Added normalised partner name to fetch

Jason Shipp 15/03/2020
	- Filtered out non-nominee MFDD RBS direct debit transactions in Match/Trans WHERE clause

Jason Shipp 01/04/2020
	- Added condition on join to Warehouse.APW.DirectLoad_OutletOinToPartnerID table to additionally match on PartnerCommissionRuleID for MFDDs (where a PartnerCommissionRuleID exists)
	- To handle Sky, which has multiple Iron Offers on the same DirectDebitOriginatorID

******************************************************************************/
CREATE PROCEDURE [Staging].[FinancialReconciliation_InvoiceSummary_Fetch_Aggregation]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	-- Declare the analysis period parameters as the start and end dates of the most recent complete month

	DECLARE @Today datetime = CAST(CAST(GETDATE() AS date) AS datetime);

	DECLARE @Startdate datetime = DATEADD(
		day
		, 1
		, EOMONTH(@Today,-4)
	) 			

	DECLARE @Enddate datetime = DATEADD(
		SECOND
		, -1
		, DATEADD(day, -((DATEPART(day, @Today))-1), @Today)
	);

	--DECLARE @RunNo INT = 0
	
	--IF @Today = '2022-04-13'
	--	BEGIN
	--		SET @Startdate =	DATEADD(MONTH, 3 * @RunNo, '2019-01-01')
	--		SET @Enddate = DATEADD(MONTH, 3, @Startdate)
	--	END

--	SELECT @Startdate, @Enddate

	;WITH PartnerAlternate AS ( -- Load partner alternates
		SELECT 
			PartnerID
			, AlternatePartnerID
		FROM Warehouse.APW.PartnerAlternate
		UNION 
		SELECT 
			PartnerID
			, AlternatePartnerID
		FROM nFI.APW.PartnerAlternate
	), PartnerNames AS (
		SELECT y.PartnerID, y.PartnerName 
		FROM (
			SELECT x.PartnerID, x.PartnerName, ROW_NUMBER() OVER(PARTITION BY x.PartnerID ORDER BY x.PartnerName) AS NameRank FROM (
				SELECT p.PartnerID, p.PartnerName FROM Warehouse.Relational.[Partner] p
				UNION 
				SELECT p.PartnerID, p.PartnerName FROM nFI.Relational.[Partner] p
			) x
		) y
		WHERE y.NameRank = 1
	), InvoiceData AS (
		SELECT -- Load invoice summary data for non-standard publishers
			CAST(COALESCE(
				pub.PublisherName
				, CASE f.MatcherShortName
					WHEN 'AMX' THEN 'American Express'
					WHEN 'VSA' THEN 'Visa'
					WHEN 'MTR' THEN 'MTR'
					WHEN 'HSB' THEN 'HSBC'
					ELSE f.MatcherShortName
				END	
			) AS NVARCHAR(30)) AS Publisher
			, p.Name AS [Partner]
			, COALESCE(pn.PartnerName, p.Name) AS [NormalisedPartner]
			, CAST(pt.TransactionDate AS date) AS [DateOfTrans]
			, i.InvoiceNumber
			, i.InvoiceDate
			, SUM(COALESCE(pt.Price, 0)) AS Spend
			, SUM(COALESCE(pt.CashbackEarned, 0)) AS ClubCash
			, SUM(COALESCE(pt.GrossAmount, 0)) AS Gross
			, SUM(COALESCE(pt.VATAmount, 0)) AS VAT
			, SUM(COALESCE(pt.NetAmount - pt.CashbackEarned, 0)) AS NetOver
			, COUNT(pt.ID) AS Transactions
			, SUM((CASE WHEN (pt.NetAmount - pt.CashbackEarned) >= 0.2 THEN 1 ELSE 0 END)) AS TransWithNetOverMoreThan20p
			, SUM((CASE WHEN (pt.NetAmount - pt.CashbackEarned) <= -0.2 THEN 1 ELSE 0 END)) AS RefundsWithNetOverLessThanNeg20p
			, PublisherOfferCode
		FROM SLC_REPL.RAS.PANless_Transaction pt
		INNER JOIN SLC_REPORT.dbo.Invoice i
			ON pt.InvoiceID = i.ID
		INNER JOIN SLC_REPL.dbo.CRT_File f
			ON pt.FileID = f.ID
		LEFT JOIN PartnerAlternate pa
			ON pt.PartnerID = pa.PartnerID
		LEFT JOIN PartnerNames pn
			ON COALESCE(pa.AlternatePartnerID, pt.PartnerID) = pn.PartnerID
		LEFT JOIN SLC_Report.dbo.[Partner] p
			ON pt.PartnerID = p.ID		
		LEFT JOIN Warehouse.Staging.AmexOfferStage_OfferNameToPublisher otp
			ON LEFT(pt.PublisherOfferCode, 3) = otp.OfferIDPrefix3
		LEFT JOIN Warehouse.APW.DirectLoad_PublisherIDs pub
			ON otp.PublisherID = pub.PublisherID
		WHERE
			i.InvoiceNumber IS NOT NULL
			AND i.InvoiceDate BETWEEN @StartDate and @EndDate
			AND p.Name != 'BP'		
		GROUP BY
			COALESCE(
				pub.PublisherName
				, CASE f.MatcherShortName
					WHEN 'AMX' THEN 'American Express'
					WHEN 'VSA' THEN 'Visa'
					WHEN 'MTR' THEN 'MTR'
					WHEN 'HSB' THEN 'HSBC'
					ELSE f.MatcherShortName
				END	
			)
			, p.Name
			, COALESCE(pn.PartnerName, p.Name)  
			, CAST(pt.TransactionDate AS date)
			, i.InvoiceNumber
			, i.InvoiceDate
			, PublisherOfferCode
	)
	SELECT -- Fetch combined results
		r.Publisher
		, r.[Partner]
		, r.NormalisedPartner
		, r.DateOfTrans
		, r.InvoiceNumber
		, r.InvoiceDate
		, SUM(r.Spend) AS Spend 
		, SUM(r.ClubCash) AS ClubCash
		, SUM(r.Gross) AS Gross
		, SUM(r.VAT) AS VAT
		, SUM(r.NetOver) AS NetOver
		, SUM(r.Transactions) AS Transactions
		, SUM(r.TransWithNetOverMoreThan20p) AS TransWithNetOverMoreThan20p
		, SUM(r.RefundsWithNetOverLessThanNeg20p) AS RefundsWithNetOverLessThanNeg20p
		,PublisherOfferCode
	FROM InvoiceData r
	GROUP BY
		r.Publisher
		, r.[Partner]
		, r.NormalisedPartner
		, r.DateOfTrans
		, r.InvoiceNumber
		, r.InvoiceDate
		, publisheroffercode
	ORDER BY
		r.Publisher
		, r.[Partner]
		, r.NormalisedPartner
		, r.InvoiceDate
		, r.InvoiceNumber
		, r.DateOfTrans;

END