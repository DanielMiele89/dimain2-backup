CREATE PROCEDURE [APW].[DirectLoad_SchemeTrans_IndividualPartner_RF]
AS
BEGIN

	SET NOCOUNT ON;

	/*
	SELECT *
	FROM [SLC_REPL].[dbo].[Partner] pa
	WHERE pa.Name LIKE '%readly%'
	*/

	--SELECT MAX(ID)
	--FROM BI.SchemeTrans WITH (NOLOCK)
	DECLARE @Today DATETIME = GETDATE()
	DECLARE @MatchID INT = 360000000

	;WITH
	Partners AS	(	SELECT	pa.ID
						,	pa.Name
					FROM [SLC_Report].[dbo].[Partner] pa
					WHERE pa.ID IN (4532, 9999, 9999, 9999, 9999, 9999))

	SELECT	DISTINCT
			m.ID AS MatchID
		,	f.ClubID AS PublisherID
		,	f.ID AS FanID
		,	CAST(m.TransactionDate AS date) AS TranDate
		,	CAST(m.AddedDate AS date) AS AddedDate
		,	m.Amount AS Spend		
		,	CONVERT(MONEY,	CASE
								WHEN o.OIN IS NOT NULL THEN (ISNULL(t.ClubCash * tt.Multiplier,0)  + (ISNULL(t.ClubCash * tt.Multiplier,0) * o.DDInvestmentProportionOfCashback)) -- For DDs, Cashback + Override, Where Override = Cashback x a multiplier -- Jason Shipp 15/05/2019
								ELSE m.AffiliateCommissionAmount
							END) AS Investment
		,	COALESCE(pa.AlternatePartnerID, o.PartnerID) AS RetailerID
	 	,	LEFT(COALESCE(m.CardHolderPresentData, mchp.CardholderPresentData), 1) AS CardHolderPresentData
		,	o.Channel AS OutletChannel
		,	pcr.RequiredIronOfferID AS IronOfferID
		,	ISNULL(t.ClubCash * tt.Multiplier,0) AS RetailerCashback
		,	ISNULL(COALESCE(pda.ManagedBy, pdo.ManagedBy), '1') AS DealManagedBy
		,	COALESCE(pda.Reward, pdo.Reward) AS RewardShare
		,	COALESCE(pda.Publisher, pdo.Publisher) AS PublisherShare
		,	iss.SpendStretchAmount
		,	pe.ID AS MonthlyExcludeID
		,	ISNULL(ro.IsOnline, 0) AS RetailerIsOnline
		,	CASE WHEN o.OIN IS NOT NULL THEN -1 ELSE o.OutletID END AS OutletID -- Jason Shipp 15/05/2019
		,	m.PanID
		,	qs.SourceUID AS QuidcoSourceUID
		,	rc.SchemeMembershipTypeID
		,	ups.MatchID AS UpstreamMatchID
		,	ISNULL(ROUND(t.Commission, 2), 0) AS OfferPercentage
		,	ISNULL(m.PartnerCommissionRate, 0) AS CommissionRate
		,	ISNULL(m.VatAmount, 0) AS VATCommission
		,	ISNULL(m.PartnerCommissionAmount, 0) AS GrossCommission
		,	CAST(m.TransactionDate AS time) AS TranTime
	--INTO #Check
	FROM SLC_Repl.dbo.Match m WITH (NOLOCK)
	INNER JOIN SLC_Repl.dbo.Trans t WITH (NOLOCK) ON t.MatchID = m.ID
	INNER JOIN SLC_Repl.dbo.Fan f ON t.FanID = f.ID
	LEFT JOIN Staging.MatchCardHolderPresent mchp ON t.MatchID = mchp.MatchID
	INNER JOIN APW.DirectLoad_OutletOinToPartnerID o ON (COALESCE(m.RetailOutletID, m.DirectDebitOriginatorID) = COALESCE(o.OutletID, o.DirectDebitOriginatorID)) AND (o.PartnerCommissionRuleID IS NULL OR m.PartnerCommissionRuleID = o.PartnerCommissionRuleID) -- Captures POS and MFDD transactions -- Jason Shipp 05/03/2019
	LEFT JOIN Relational.nFI_Partner_Deals pdo ON o.PartnerID = pdo.PartnerID AND f.ClubID = pdo.ClubID AND m.TransactionDate >= pdo.StartDate AND (pdo.EndDate IS NULL OR m.TransactionDate <= pdo.EndDate)
	INNER JOIN SLC_Repl.dbo.PartnerCommissionRule pcr ON (m.PartnerCommissionRuleID = pcr.ID) OR (m.VectorID = 40 AND o.PartnerID = pcr.PartnerID AND o.IronOfferID = pcr.RequiredIronOfferID) -- Jason Shipp 11/07/2019
	LEFT JOIN SLC_Repl.dbo.TransactionType tt ON t.TypeID = tt.ID
	--LEFT JOIN APW.DirectLoad_PartnerDeals pd ON f.ClubID = pd.PublisherID AND o.PartnerID = pd.PartnerID AND m.TransactionDate BETWEEN pd.StartDate AND pd.EndDate
	LEFT JOIN APW.PartnerAlternate pa ON o.PartnerID = pa.PartnerID
	LEFT JOIN Relational.nFI_Partner_Deals pda ON pa.AlternatePartnerID = pda.PartnerID AND f.ClubID = pdo.ClubID AND m.TransactionDate >= pda.StartDate AND (pda.EndDate IS NULL OR m.TransactionDate <= pda.EndDate)
	LEFT JOIN APW.DirectLoad_IronOfferSpendStretch iss ON pcr.RequiredIronOfferID = iss.IronOfferID
	LEFT JOIN APW.PublisherExclude pe ON f.ClubID = pe.PublisherID AND o.PartnerID = pe.RetailerID AND m.TransactionDate BETWEEN pe.StartDate AND pe.EndDate
	INNER JOIN APW.DirectLoad_PublisherIDs pu ON f.ClubID = pu.PublisherID
	LEFT JOIN APW.DirectLoad_RetailerOnline ro ON o.PartnerID = ro.RetailerID
	LEFT JOIN (SELECT DISTINCT SourceUID FROM InsightArchive.QuidcoR4GCustomers) qs ON f.SourceUID = qs.SourceUID
	LEFT JOIN Relational.Customer_SchemeMembership rc ON f.ID = rc.FanID AND m.TransactionDate BETWEEN rc.StartDate AND COALESCE(rc.EndDate, @Today)
	LEFT JOIN SLC_Repl.dbo.MatchSelfFundedTransaction ups ON m.ID = ups.MatchID
	WHERE m.[status] = 1 
	AND m.rewardstatus IN (0,1)
	AND pcr.TypeID = 2
	--AND m.TransactionDate >= '2012-01-01'
	AND o.PartnerID != 4433
	AND o.PartnerID != 4447
	AND (o.StartDate IS NULL OR m.TransactionDate >= o.StartDate) -- Make sure OIN is incentivised when transaction occurred (if there is an OIN) -- Jason Shipp 05/03/2019
	AND (o.EndDate IS NULL OR m.TransactionDate <= o.EndDate)
	AND NOT (m.VectorID = 40 AND t.TypeID = 24) -- Jason Shipp 10/05/2019 -- filter out non-nominee RBS direct debit transactions
	--AND m.ID >= @MatchID
	--AND t.MatchID >= @MatchID
	--AND EXISTS (SELECT 1
	--			FROM Sandbox.Rory.SchemeTrans_Dim_MisingFromRewardBI sb
	--			WHERE m.ID = sb.SourceTableID)
	AND EXISTS (SELECT 1
				FROM Partners pa
				WHERE o.PartnerID = pa.ID)
	ORDER BY m.ID

/*
DROP TABLE #CC
SELECT DISTINCT cc.ConsumerCombinationID, Narrative
INTO #CC
FROM SLC_Report..RetailOutlet ro
INNER JOIN Relational.ConsumerCombination cc
	ON ro.MerchantID = cc.MID
WHERE PartnerID = 4695


DROP TABLE #CT
SELECT *
INTO #CT
FROM Relational.ConsumerTransaction ct
WHERE EXISTS (	SELECT 1
				FROM #CC cc
				WHERE ct.ConsumerCombinationID = cc.ConsumerCombinationID)
AND ct.TranDate >= '2021-04-19'
		
SELECT	CASE
			WHEN '2021-05-24' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-05-24') THEN '2021-05-24'
			WHEN '2021-05-17' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-05-17') THEN '2021-05-17'
			WHEN '2021-05-10' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-05-10') THEN '2021-05-10'
			WHEN '2021-05-03' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-05-03') THEN '2021-05-03'
			WHEN '2021-04-26' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-04-26') THEN '2021-04-26'
			WHEN '2021-04-19' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-04-19') THEN '2021-04-19'
		END AS WeekStart
	,	COUNT(*) AS Trans
	--,	SUM(CASE WHEN PublisherID < 0 THEN Investment END) AS Investment_Amex
	--,	SUM(CASE WHEN PublisherID IN (132, 138) THEN Investment END) AS Investment_MyRewards
	--,	SUM(CASE WHEN PublisherID IN (166) THEN Investment END) AS Investment_Virgin
	--,	SUM(CASE WHEN PublisherID > 0 AND PublisherID NOT IN (132, 138, 166) THEN Investment END) AS Investment_nFI
	,	SUM(Investment) AS Investment
	,	SUM(Spend) AS Spend
FROM #Check
GROUP BY CASE
			WHEN '2021-05-24' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-05-24') THEN '2021-05-24'
			WHEN '2021-05-17' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-05-17') THEN '2021-05-17'
			WHEN '2021-05-10' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-05-10') THEN '2021-05-10'
			WHEN '2021-05-03' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-05-03') THEN '2021-05-03'
			WHEN '2021-04-26' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-04-26') THEN '2021-04-26'
			WHEN '2021-04-19' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-04-19') THEN '2021-04-19'
		END
ORDER BY CASE
			WHEN '2021-05-24' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-05-24') THEN '2021-05-24'
			WHEN '2021-05-17' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-05-17') THEN '2021-05-17'
			WHEN '2021-05-10' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-05-10') THEN '2021-05-10'
			WHEN '2021-05-03' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-05-03') THEN '2021-05-03'
			WHEN '2021-04-26' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-04-26') THEN '2021-04-26'
			WHEN '2021-04-19' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-04-19') THEN '2021-04-19'
		END DESC
		


SELECT	CASE
			WHEN '2021-05-24' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-05-24') THEN '2021-05-24'
			WHEN '2021-05-17' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-05-17') THEN '2021-05-17'
			WHEN '2021-05-10' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-05-10') THEN '2021-05-10'
			WHEN '2021-05-03' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-05-03') THEN '2021-05-03'
			WHEN '2021-04-26' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-04-26') THEN '2021-04-26'
			WHEN '2021-04-19' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-04-19') THEN '2021-04-19'
		END AS WeekStart
	,	Narrative
	,	COUNT(*) AS Trans
	--,	SUM(CASE WHEN PublisherID < 0 THEN Investment END) AS Investment_Amex
	--,	SUM(CASE WHEN PublisherID IN (132, 138) THEN Investment END) AS Investment_MyRewards
	--,	SUM(CASE WHEN PublisherID IN (166) THEN Investment END) AS Investment_Virgin
	--,	SUM(CASE WHEN PublisherID > 0 AND PublisherID NOT IN (132, 138, 166) THEN Investment END) AS Investment_nFI
	,	SUM(Amount) AS Amount
	,	SUM(CASE WHEN IsOnline = 1 THEN Amount END) AS Amount
FROM #CT ct
INNER JOIN #CC cc
	ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
GROUP BY CASE
			WHEN '2021-05-24' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-05-24') THEN '2021-05-24'
			WHEN '2021-05-17' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-05-17') THEN '2021-05-17'
			WHEN '2021-05-10' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-05-10') THEN '2021-05-10'
			WHEN '2021-05-03' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-05-03') THEN '2021-05-03'
			WHEN '2021-04-26' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-04-26') THEN '2021-04-26'
			WHEN '2021-04-19' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-04-19') THEN '2021-04-19'
		END
	,	Narrative
ORDER BY CASE
			WHEN '2021-05-24' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-05-24') THEN '2021-05-24'
			WHEN '2021-05-17' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-05-17') THEN '2021-05-17'
			WHEN '2021-05-10' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-05-10') THEN '2021-05-10'
			WHEN '2021-05-03' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-05-03') THEN '2021-05-03'
			WHEN '2021-04-26' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-04-26') THEN '2021-04-26'
			WHEN '2021-04-19' <= TranDate AND TranDate < DATEADD(DAY, 7, '2021-04-19') THEN '2021-04-19'
		END DESC
	,	4
	
	
	*/




	

END