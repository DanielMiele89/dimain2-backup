/******************************************************************************
Author: JEA
Created: 06/12/2016
Purpose:
	- Retrieves transactions from SLC_Repl above the highest matchID already retrieved

------------------------------------------------------------------------------
Modification History

Jason Shipp 05/03/2019
	- Cleaned up code formatting
	- Added refresh of staging table (Warehouse.APW.DirectLoad_OutletOinToPartnerID) to allow RetailOutletIDs or OINs to be used to match transactions to PartnerIDs (to allow for MFDDs)
	- Used the above linking table in place of APW.DirectLoad_RetailOutlet

------------------------------------------------------------------------------
Modification History

Jason Shipp 29/04/2019
	- Updated logic linking OINs to PartnerIDs: Use Warehouse.Relational.DirectDebitOriginator table to link OINs to DirectDebitOriginatorIDs
	- Updated IsOnline logic in load of APW.DirectLoad_OutletOinToPartnerID table

Jason Shipp 10/05/2019
	- Added to WHERE clause: "NOT (m.VectorID = 40 AND t.TypeID = 24)", to filter out non-nominee RBS direct debit transactions from Trans table

Jason Shipp 15/05/2019
	- Added DDInvestmentProportionOfCashback column to APW.DirectLoad_OutletOinToPartnerID table so investment can be determined for RBS direct debit transactions
	- Added fallback to -1 for RBS direct debit transaction OutletIDs
	- Added TEMPORARY join alternative between Match and PartnerCommissionRule tables on PartnerID for RBS direct debit transactions
	- This is an interim solution to allow RBS direct debit transactions to flow into BI.SchemeTrans. Permanent solution (feeding PartnerCommissionRuleID into the Match table) will be implemented later by IT

Jason Shipp 11/07/2019
	- Refined the link between Match and PartnerCommissionRule tables by additionally linking by IronOfferID via the SLC_Repl.dbo.DirectDebitOfferOINs table
	- This still requires: 
		- The SLC_Repl.dbo.DirectDebitOfferOINs table to contain unique OINs (Ie. Different Iron Offers can't use the same OIN)
		- The SLC_Repl.dbo.PartnerCommissionRule table to contain one entry per DD IronOfferID with a TypeID of 2

Jason Shipp 01/04/2020
	- Added condition on join to Warehouse.APW.DirectLoad_OutletOinToPartnerID table to additionally match on PartnerCommissionRuleID for MFDDs (where a PartnerCommissionRuleID exists)
	- To handle Sky, which has multiple Iron Offers on the same DirectDebitOriginatorID

******************************************************************************/
CREATE PROCEDURE [APW].[DirectLoad_SchemeTrans_RetrospectiveLoad_Dev] @MatchID_Min BIGINT
AS
BEGIN

	SET NOCOUNT ON;

	/*
	SELECT *
	FROM [SLC_REPL].[dbo].[Partner] pa
	WHERE pa.Name LIKE '%morri%'
	*/
	

	-- Fetch incentivised transactions
	
--	DECLARE	@MatchID_Min BIGINT = 369200000
	DECLARE	@MatchID_Max BIGINT = 1000000000

	--IF OBJECT_ID('tempdb..#Partners') IS NOT NULL DROP TABLE #Partners;
	--SELECT pa.ID
	--INTO #Partners
	--FROM [SLC_Report].[dbo].[Partner] pa
	--WHERE pa.ID IN (4263, 4770, 9999, 9999, 9999, 9999, 9999)

	IF OBJECT_ID('tempdb..#Match') IS NOT NULL DROP TABLE #Match
	SELECT	ma.ID
		,	ma.VectorID
		,	ma.PanID
		,	ma.Amount
		,	ma.TransactionDate
		,	ma.CardHolderPresentData
		,	ma.DirectDebitOriginatorID
		,	ma.RetailOutletID
		,	COALESCE(ma.RetailOutletID, ma.DirectDebitOriginatorID) AS RetailOutlet_DirectDebitOriginatorID
		,	ma.PartnerCommissionRuleID
		,	ma.VatAmount
		,	ma.AffiliateCommissionAmount
		,	ma.PartnerCommissionAmount
		,	ma.PartnerCommissionRate
		,	ma.AddedDate
	INTO #Match
	FROM [SLC_REPL].[dbo].[Match] ma WITH (NOLOCK)
	WHERE ma.[Status] = 1 
	AND ma.RewardStatus IN (0, 1)
	AND ma.TransactionDate >= '2012-01-01'
	AND ma.ID BETWEEN @MatchID_Min AND @MatchID_Max

	CREATE CLUSTERED INDEX CIX_ID ON #Match (ID)

	IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans;
	SELECT	tr.ID
		,	tr.MatchID
		,	tr.ClubCash
		,	tr.Commission
		,	tr.FanID
		,	tr.TypeID
		,	ISNULL(tr.ClubCash * tt.Multiplier, 0) AS RetailerCashback
	INTO #Trans
	FROM [SLC_REPL].[dbo].[Trans] tr
	LEFT JOIN [SLC_REPL].[dbo].[TransactionType] tt
		ON tr.TypeID = tt.ID
	WHERE EXISTS (	SELECT 1
					FROM #Match ma
					WHERE tr.MatchID = ma.ID)

	CREATE CLUSTERED INDEX CIX_FanID ON #Trans (FanID)

	IF OBJECT_ID('tempdb..#TransFan') IS NOT NULL DROP TABLE #TransFan;
	SELECT	tr.ID
		,	tr.MatchID
		,	tr.ClubCash
		,	tr.Commission
		,	tr.FanID
		,	tr.TypeID
		,	tr.RetailerCashback
		,	fa.ClubID
		,	fa.SourceUID
		,	qs.SourceUID AS QuidcoSourceUID
	INTO #TransFan
	FROM #Trans tr
	INNER JOIN [SLC_REPL].[dbo].[Fan] fa
		ON tr.FanID = fa.ID
	LEFT JOIN (SELECT DISTINCT SourceUID FROM InsightArchive.QuidcoR4GCustomers) qs
		ON fa.SourceUID = qs.SourceUID

	CREATE CLUSTERED INDEX CIX_MatchID ON #TransFan (MatchID)

	IF OBJECT_ID('tempdb..#MatchCardHolderPresent') IS NOT NULL DROP TABLE #MatchCardHolderPresent;
	SELECT *
	INTO #MatchCardHolderPresent
	FROM [Staging].[MatchCardHolderPresent] mchp
	WHERE EXISTS (	SELECT 1
					FROM #Match ma
					WHERE mchp.MatchID = ma.ID)
	
	CREATE CLUSTERED INDEX CIX_MatchID ON #MatchCardHolderPresent (MatchID)

	IF OBJECT_ID('tempdb..#MatchSelfFundedTransaction') IS NOT NULL DROP TABLE #MatchSelfFundedTransaction;
	SELECT *
	INTO #MatchSelfFundedTransaction
	FROM [SLC_REPL].[dbo].[MatchSelfFundedTransaction] msft
	WHERE EXISTS (	SELECT 1
					FROM #Match ma
					WHERE msft.MatchID = ma.ID)
	
	CREATE CLUSTERED INDEX CIX_MatchID ON #MatchSelfFundedTransaction (MatchID)
	
	DECLARE @Today DATETIME = GETDATE()

	IF OBJECT_ID('tempdb..#Customer_SchemeMembership') IS NOT NULL DROP TABLE #Customer_SchemeMembership;
	SELECT	csm.FanID
		,	csm.SchemeMembershipTypeID
		,	csm.StartDate
		,	COALESCE(csm.EndDate, @Today) AS EndDate
	INTO #Customer_SchemeMembership
	FROM [Relational].[Customer_SchemeMembership] csm
	WHERE EXISTS (	SELECT 1
					FROM #Trans tr
					WHERE tr.FanID = csm.FanID)
	
	CREATE CLUSTERED INDEX CIX_FanID ON #Customer_SchemeMembership (FanID)
		
	IF OBJECT_ID('tempdb..#DirectLoad_OutletOinToPartnerID') IS NOT NULL DROP TABLE #DirectLoad_OutletOinToPartnerID;	
	SELECT	*
		,	COALESCE(o.OutletID, o.DirectDebitOriginatorID) AS RetailOutlet_DirectDebitOriginatorID
	INTO #DirectLoad_OutletOinToPartnerID
	FROM [APW].[DirectLoad_OutletOinToPartnerID] o
	WHERE EXISTS (	SELECT 1
					FROM #Match m
					WHERE o.PartnerCommissionRuleID = m.PartnerCommissionRuleID)
	AND o.PartnerID NOT IN (4433, 4447)
	UNION
	SELECT *
		,	COALESCE(o.OutletID, o.DirectDebitOriginatorID) AS RetailOutlet_DirectDebitOriginatorID
	FROM [APW].[DirectLoad_OutletOinToPartnerID] o
	WHERE EXISTS (	SELECT 1
					FROM #Match m
					WHERE o.DirectDebitOriginatorID = m.DirectDebitOriginatorID)
	AND o.PartnerID NOT IN (4433, 4447)
	UNION
	SELECT *
		,	COALESCE(o.OutletID, o.DirectDebitOriginatorID) AS RetailOutlet_DirectDebitOriginatorID
	FROM [APW].[DirectLoad_OutletOinToPartnerID] o
	WHERE EXISTS (	SELECT 1
					FROM #Match m
					WHERE o.OutletID = m.RetailOutletID)
	AND o.PartnerID NOT IN (4433, 4447)
	
	IF OBJECT_ID('tempdb..#PartnerCommissionRule') IS NOT NULL DROP TABLE #PartnerCommissionRule;
	SELECT	DISTINCT
			pcr.ID
		,	pcr.PartnerID
		,	pcr.RequiredIronOfferID
	INTO #PartnerCommissionRule
	FROM SLC_Repl.dbo.PartnerCommissionRule pcr
	WHERE pcr.TypeID = 2
	AND EXISTS (SELECT 1
				FROM #Match ma
				WHERE ma.PartnerCommissionRuleID = pcr.ID)
	UNION
	SELECT	DISTINCT
			pcr.ID
		,	pcr.PartnerID
		,	pcr.RequiredIronOfferID
	FROM SLC_Repl.dbo.PartnerCommissionRule pcr
	WHERE pcr.TypeID = 2
	AND EXISTS (SELECT 1
				FROM #Match ma
				INNER JOIN #DirectLoad_OutletOinToPartnerID o
					ON (ma.RetailOutlet_DirectDebitOriginatorID = o.RetailOutlet_DirectDebitOriginatorID) AND (o.PartnerCommissionRuleID IS NULL OR ma.PartnerCommissionRuleID = o.PartnerCommissionRuleID) -- Captures POS and MFDD transactions -- Jason Shipp 05/03/2019
					AND (o.StartDate IS NULL OR ma.TransactionDate >= o.StartDate) -- Make sure OIN is incentivised when transaction occurred (if there is an OIN) -- Jason Shipp 05/03/2019
					AND (o.EndDate IS NULL OR ma.TransactionDate <= o.EndDate)
				WHERE ma.VectorID = 40
				AND o.PartnerID = pcr.PartnerID
				AND o.IronOfferID = pcr.RequiredIronOfferID)

	CREATE CLUSTERED INDEX CIX_ID ON #PartnerCommissionRule (ID)
	CREATE NONCLUSTERED INDEX IX_FanID ON #PartnerCommissionRule (PartnerID, RequiredIronOfferID)
	
	IF OBJECT_ID('tempdb..#MatchTransFan') IS NOT NULL DROP TABLE #MatchTransFan;	
	SELECT	DISTINCT
			ma.ID AS MatchID
		,	tf.ClubID
		,	tf.FanID
		,	CAST(ma.TransactionDate AS date) AS TranDate
		,	CAST(ma.AddedDate AS date) AS AddedDate
		,	ma.Amount AS Spend
	 	,	LEFT(COALESCE(ma.CardHolderPresentData, mchp.CardholderPresentData), 1) AS CardHolderPresentData
		,	tf.RetailerCashback
		,	ma.PanID
		,	tf.QuidcoSourceUID
		,	csm.SchemeMembershipTypeID
		,	msft.MatchID AS UpstreamMatchID
		,	ISNULL(ROUND(tf.Commission, 2), 0) AS OfferPercentage
		,	ISNULL(ma.PartnerCommissionRate, 0) AS CommissionRate
		,	ISNULL(ma.VatAmount, 0) AS VATCommission
		,	ISNULL(ma.PartnerCommissionAmount, 0) AS GrossCommission
		,	CAST(ma.TransactionDate AS time) AS TranTime
		,	ma.RetailOutlet_DirectDebitOriginatorID
		,	ma.RetailOutletID
		,	ma.DirectDebitOriginatorID
		,	ma.PartnerCommissionRuleID
		,	ma.AffiliateCommissionAmount
		,	ma.VectorID
		,	o.PartnerID
		,	pcr.RequiredIronOfferID AS IronOfferID
		,	o.OIN
		,	o.DDInvestmentProportionOfCashback
		,	o.Channel
		,	o.OutletID
	INTO #MatchTransFan
	FROM #Match ma
	INNER JOIN #TransFan tf
		ON ma.ID = tf.MatchID
	INNER JOIN #DirectLoad_OutletOinToPartnerID o
		ON (ma.RetailOutlet_DirectDebitOriginatorID = o.RetailOutlet_DirectDebitOriginatorID) AND (o.PartnerCommissionRuleID IS NULL OR ma.PartnerCommissionRuleID = o.PartnerCommissionRuleID) -- Captures POS and MFDD transactions -- Jason Shipp 05/03/2019
		AND (o.StartDate IS NULL OR ma.TransactionDate >= o.StartDate) -- Make sure OIN is incentivised when transaction occurred (if there is an OIN) -- Jason Shipp 05/03/2019
		AND (o.EndDate IS NULL OR ma.TransactionDate <= o.EndDate)
	INNER JOIN #PartnerCommissionRule pcr
		ON ma.PartnerCommissionRuleID = pcr.ID
	LEFT JOIN #MatchCardHolderPresent mchp
		ON ma.ID = mchp.MatchID
	LEFT JOIN #MatchSelfFundedTransaction msft
		ON ma.ID = msft.MatchID
	LEFT JOIN #Customer_SchemeMembership csm
		ON tf.FanID = csm.FanID
		AND ma.TransactionDate BETWEEN csm.StartDate AND csm.EndDate
	WHERE NOT (ma.VectorID = 40 AND tf.TypeID = 24) -- Jason Shipp 10/05/2019 -- filter out non-nominee RBS direct debit transactions
	UNION
	SELECT	DISTINCT
			ma.ID AS MatchID
		,	tf.ClubID
		,	tf.FanID
		,	CAST(ma.TransactionDate AS date) AS TranDate
		,	CAST(ma.AddedDate AS date) AS AddedDate
		,	ma.Amount AS Spend
	 	,	LEFT(COALESCE(ma.CardHolderPresentData, mchp.CardholderPresentData), 1) AS CardHolderPresentData
		,	tf.RetailerCashback
		,	ma.PanID
		,	tf.QuidcoSourceUID
		,	csm.SchemeMembershipTypeID
		,	msft.MatchID AS UpstreamMatchID
		,	ISNULL(ROUND(tf.Commission, 2), 0) AS OfferPercentage
		,	ISNULL(ma.PartnerCommissionRate, 0) AS CommissionRate
		,	ISNULL(ma.VatAmount, 0) AS VATCommission
		,	ISNULL(ma.PartnerCommissionAmount, 0) AS GrossCommission
		,	CAST(ma.TransactionDate AS time) AS TranTime
		,	ma.RetailOutlet_DirectDebitOriginatorID
		,	ma.RetailOutletID
		,	ma.DirectDebitOriginatorID
		,	ma.PartnerCommissionRuleID
		,	ma.AffiliateCommissionAmount
		,	ma.VectorID
		,	o.PartnerID
		,	pcr.RequiredIronOfferID AS IronOfferID
		,	o.OIN
		,	o.DDInvestmentProportionOfCashback
		,	o.Channel
		,	o.OutletID
	FROM #Match ma
	INNER JOIN #TransFan tf
		ON ma.ID = tf.MatchID
	INNER JOIN #DirectLoad_OutletOinToPartnerID o
		ON (ma.RetailOutlet_DirectDebitOriginatorID = o.RetailOutlet_DirectDebitOriginatorID) AND (o.PartnerCommissionRuleID IS NULL OR ma.PartnerCommissionRuleID = o.PartnerCommissionRuleID) -- Captures POS and MFDD transactions -- Jason Shipp 05/03/2019
		AND (o.StartDate IS NULL OR ma.TransactionDate >= o.StartDate) -- Make sure OIN is incentivised when transaction occurred (if there is an OIN) -- Jason Shipp 05/03/2019
		AND (o.EndDate IS NULL OR ma.TransactionDate <= o.EndDate)
	INNER JOIN #PartnerCommissionRule pcr
		ON ma.VectorID = 40
		AND o.PartnerID = pcr.PartnerID
		AND o.IronOfferID = pcr.RequiredIronOfferID
	LEFT JOIN #MatchCardHolderPresent mchp
		ON ma.ID = mchp.MatchID
	LEFT JOIN #MatchSelfFundedTransaction msft
		ON ma.ID = msft.MatchID
	LEFT JOIN #Customer_SchemeMembership csm
		ON tf.FanID = csm.FanID
		AND ma.TransactionDate BETWEEN csm.StartDate AND csm.EndDate
	WHERE NOT (ma.VectorID = 40 AND tf.TypeID = 24) -- Jason Shipp 10/05/2019 -- filter out non-nominee RBS direct debit transactions
	
	IF OBJECT_ID('tempdb..#nFI_Partner_Deals') IS NOT NULL DROP TABLE #nFI_Partner_Deals;
	SELECT	ClubID
		,	PartnerID
		,	StartDate
		,	EndDate = COALESCE(EndDate, '9999-12-31')
		,	ManagedBy
		,	Reward
		,	Publisher
	INTO #nFI_Partner_Deals
	FROM [Relational].[nFI_Partner_Deals]

	CREATE CLUSTERED INDEX CIX_ClubIDPartnerID ON #nFI_Partner_Deals (ClubID, PartnerID)
	
	IF OBJECT_ID('tempdb..#SchemeTransTemp') IS NOT NULL DROP TABLE #SchemeTransTemp;
	SELECT	DISTINCT
			mtf.MatchID
		,	mtf.ClubID AS PublisherID
		,	mtf.FanID
		,	mtf.TranDate
		,	mtf.AddedDate
		,	mtf.Spend		
		,	CONVERT(MONEY,	CASE
								WHEN mtf.OIN IS NOT NULL THEN (mtf.RetailerCashback + (mtf.RetailerCashback * mtf.DDInvestmentProportionOfCashback)) -- For DDs, Cashback + Override, Where Override = Cashback x a multiplier -- Jason Shipp 15/05/2019
								ELSE mtf.AffiliateCommissionAmount
							END) AS Investment
		,	COALESCE(pa.AlternatePartnerID, mtf.PartnerID) AS RetailerID
	 	,	mtf.CardHolderPresentData
		,	mtf.Channel AS OutletChannel
		,	mtf.IronOfferID
		,	mtf.RetailerCashback
		,	ISNULL(COALESCE(pda.ManagedBy, pdo.ManagedBy), '1') AS DealManagedBy
		,	COALESCE(pda.Reward, pdo.Reward) AS RewardShare
		,	COALESCE(pda.Publisher, pdo.Publisher) AS PublisherShare
		,	iss.SpendStretchAmount
		,	pe.ID AS MonthlyExcludeID
		,	ISNULL(ro.IsOnline, 0) AS RetailerIsOnline
		,	CASE WHEN mtf.OIN IS NOT NULL THEN -1 ELSE mtf.OutletID END AS OutletID -- Jason Shipp 15/05/2019
		,	mtf.PanID
		,	mtf.QuidcoSourceUID
		,	mtf.SchemeMembershipTypeID
		,	mtf.UpstreamMatchID
		,	mtf.OfferPercentage
		,	mtf.CommissionRate
		,	mtf.VATCommission
		,	mtf.GrossCommission
		,	mtf.TranTime
	INTO #SchemeTransTemp
	FROM #MatchTransFan mtf
	LEFT JOIN #nFI_Partner_Deals pdo
		ON mtf.PartnerID = pdo.PartnerID
		AND mtf.ClubID = pdo.ClubID
		AND mtf.TranDate >= pdo.StartDate
		AND mtf.TranDate <= pdo.EndDate
	LEFT JOIN APW.PartnerAlternate pa ON mtf.PartnerID = pa.PartnerID
	LEFT JOIN #nFI_Partner_Deals pda
		ON pa.AlternatePartnerID = pda.PartnerID
		AND mtf.ClubID = pdo.ClubID
		AND mtf.TranDate >= pda.StartDate
		AND mtf.TranDate <= pda.EndDate
	LEFT JOIN APW.DirectLoad_IronOfferSpendStretch iss ON mtf.IronOfferID = iss.IronOfferID
	LEFT JOIN APW.PublisherExclude pe ON mtf.ClubID = pe.PublisherID AND mtf.PartnerID = pe.RetailerID AND mtf.TranDate BETWEEN pe.StartDate AND pe.EndDate
	INNER JOIN APW.DirectLoad_PublisherIDs pu ON mtf.ClubID = pu.PublisherID
	LEFT JOIN APW.DirectLoad_RetailerOnline ro ON mtf.PartnerID = ro.RetailerID
	
	SELECT	c.MatchID
		,	CASE
				WHEN c.PublisherID = 138 THEN 132
				ELSE c.PublisherID
			END AS PublisherID
		,	c.FanID
		,	c.TranDate
		,	c.AddedDate
		,	Spend = CONVERT(DECIMAL(32,2), c.Spend)
		,	Investment = CONVERT(DECIMAL(32,2), c.Investment)
		,	c.RetailerID
		,	c.IronOfferID
		,	RetailerCashback = CONVERT(DECIMAL(32,2), c.RetailerCashback)
		,	SpendStretchAmount = CONVERT(DECIMAL(32,2), c.SpendStretchAmount)
		,	c.OutletID
		,	c.PanID
		,	c.OfferPercentage
		,	c.CommissionRate
		,	VATCommission = CONVERT(DECIMAL(32,2), c.VATCommission)
		,	GrossCommission = CONVERT(DECIMAL(32,2), c.GrossCommission)
		,	c.TranTime
		,	RewardCommission = CONVERT(DECIMAL(32,2), (c2.Commission * c2.RewardShare) / c2.TotalShare)
		,	PublisherCommission = CONVERT(DECIMAL(32,2), (c2.Commission * c2.PublisherShare) / c2.TotalShare)
		,	CASE
				WHEN c.AddedDate <= c2.CheckDate THEN c.TranDate
				ELSE NULL
			END AS TranFixDate
		,	CASE
				WHEN c.OutletID = -1 THEN 1
				WHEN c.PublisherID IN (132, 138) AND c.CardHolderPresentData = '5' THEN 1
				WHEN c.PublisherID IN (132, 138) AND c.OutletChannel = 1 AND (c.CardHolderPresentData = '9' OR c.RetailerID = 3724) THEN 1
				WHEN c.PublisherID IN (132, 138) THEN 0
				ELSE c.RetailerIsOnline				
				--WHEN c.OutletID = -1 THEN 1
				--WHEN c.PublisherID NOT IN (132, 138) THEN c.RetailerIsOnline	--	Should theis be OutletChannel?
				--WHEN c.OutletChannel = 1 AND c.CardHolderPresentData = '9' THEN 1
				--WHEN c.OutletChannel = 1 AND c.RetailerID = 3724 THEN 1
				--ELSE 0
			END AS IsOnline
		,	CASE
				WHEN c.MonthlyExcludeID IS NULL AND c.UpstreamMatchID IS NULL AND c.DealManagedBy = 1 THEN 1
				ELSE 0
			END AS IsRetailerMonthly
		,	CASE
				WHEN c.SpendStretchAmount IS NULL THEN NULL
				WHEN c.SpendStretchAmount <= c.Spend THEN 1
				ELSE 0
			END AS IsSpendStretch
		,	CASE
				WHEN Spend < 0 THEN 1
				ELSE 0
			END AS IsNegative
		,	CASE
				WHEN c.DealManagedBy = 2 THEN 1
				ELSE 0
			END AS NotRewardManaged
		,	CASE
				WHEN c.QuidcoSourceUID IS NOT NULL THEN 1	--	Quidco R4G
				WHEN c.SchemeMembershipTypeID IS NULL THEN 0
				WHEN c.SchemeMembershipTypeID IN (6, 7) THEN 2	--	NWG Front Book
				ELSE 3
			END AS SubPublisherID
		,	CASE
				WHEN c.UpstreamMatchID IS NULL AND c.DealManagedBy = 1 THEN 1
				ELSE 0
			END AS IsRetailerReport

		--,	c.CardHolderPresentData
		--,	c.OutletChannel
		--,	c.RewardShare
		--,	c.PublisherShare
		--,	c.MonthlyExcludeID
		--,	c.RetailerIsOnline
		--,	c.DealManagedBy
		--,	c.QuidcoSourceUID
		--,	c.SchemeMembershipTypeID
		--,	c.UpstreamMatchID

		--,	c2.Commission

	FROM #SchemeTransTemp c
	CROSS APPLY (	SELECT	DATEADD(MONTH, 1, DATEFROMPARTS(DATEPART(YEAR, TranDate), DATEPART(MONTH, TranDate), 15)) AS CheckDate
						,	c2.Investment - c2.RetailerCashback AS Commission
						,	CASE
								WHEN COALESCE(c.PublisherShare, 0.00) = 0.00 THEN 100.00
								ELSE COALESCE(c.RewardShare, 100.00)
							END AS RewardShare
						,	COALESCE(c.PublisherShare, 0.00) AS PublisherShare
						,	100.00 AS TotalShare
					FROM #SchemeTransTemp c2
					WHERE c.MatchID = c2.MatchID) c2
	--WHERE EXISTS (	SELECT 1
	--				FROM #Partners pa
	--				WHERE c.RetailerID = pa.ID)

END