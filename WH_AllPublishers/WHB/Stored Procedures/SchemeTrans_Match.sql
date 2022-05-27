/******************************************************************************
Author: JEA
Created: 06/12/2016
Purpose:
	- Retrieves transactions from SLC_Repl above the highest matchID already retrieved

------------------------------------------------------------------------------
Modification History

Jason Shipp 05/03/2019
	- Cleaned up code formatting
	- Added refresh of staging table (Warehouse.[Warehouse].[APW].DirectLoad_OutletOinToPartnerID) to allow RetailOutletIDs or OINs to be used to match transactions to PartnerIDs (to allow for MFDDs)
	- Used the above linking table in place of [Warehouse].[APW].DirectLoad_RetailOutlet

------------------------------------------------------------------------------
Modification History

Jason Shipp 29/04/2019
	- Updated logic linking OINs to PartnerIDs: Use Warehouse.Relational.DirectDebitOriginator table to link OINs to DirectDebitOriginatorIDs
	- Updated IsOnline logic in load of [Warehouse].[APW].DirectLoad_OutletOinToPartnerID table

Jason Shipp 10/05/2019
	- Added to WHERE clause: "NOT (m.VectorID = 40 AND t.TypeID = 24)", to filter out non-nominee RBS direct debit transactions from Trans table

Jason Shipp 15/05/2019
	- Added DDInvestmentProportionOfCashback column to [Warehouse].[APW].DirectLoad_OutletOinToPartnerID table so investment can be determined for RBS direct debit transactions
	- Added fallback to -1 for RBS direct debit transaction OutletIDs
	- Added TEMPORARY join alternative between Match and PartnerCommissionRule tables on PartnerID for RBS direct debit transactions
	- This is an interim solution to allow RBS direct debit transactions to flow into BI.SchemeTrans. Permanent solution (feeding PartnerCommissionRuleID into the Match table) will be implemented later by IT

Jason Shipp 11/07/2019
	- Refined the link between Match and PartnerCommissionRule tables by additionally linking by IronOfferID via the SLC_Repl.dbo.DirectDebitOfferOINs table
	- This still requires: 
		- The SLC_Repl.dbo.DirectDebitOfferOINs table to contain unique OINs (Ie. Different Iron Offers can't use the same OIN)
		- The SLC_Repl.dbo.PartnerCommissionRule table to contain one entry per DD IronOfferID with a TypeID of 2

Jason Shipp 01/04/2020
	- Added condition on join to Warehouse.[Warehouse].[APW].DirectLoad_OutletOinToPartnerID table to additionally match on PartnerCommissionRuleID for MFDDs (where a PartnerCommissionRuleID exists)
	- To handle Sky, which has multiple Iron Offers on the same DirectDebitOriginatorID

******************************************************************************/
CREATE PROCEDURE [WHB].[SchemeTrans_Match]
								--	@MatchID_Min BIGINT = NULL
								--,	@MatchID_Max BIGINT = NULL
AS
BEGIN

	SET NOCOUNT ON;

	/*
	SELECT *
	FROM [SLC_REPL].[dbo].[Partner] pa
	WHERE pa.Name LIKE '%morri%'
	*/
	

	-- Fetch incentivised transactions
	
	DECLARE @SourceTableID_Max INT

	SELECT	@SourceTableID_Max = MAX(SourceTableID)
	FROM [WH_AllPublishers].[Derived].[SchemeTrans]
	WHERE SourceID = 1

	SET @SourceTableID_Max = @SourceTableID_Max - 10000000

	--IF OBJECT_ID('tempdb..#Partners') IS NOT NULL DROP TABLE #Partners;
	--SELECT pa.ID
	--INTO #Partners
	--FROM [DIMAIN_TR].[SLC_REPL].[dbo].[Partner] pa
	--WHERE pa.ID IN (4263, 4770, 9999, 9999, 9999, 9999, 9999)

	IF OBJECT_ID('tempdb..##Match_SchemeTrans_Match') IS NOT NULL DROP TABLE ##Match_SchemeTrans_Match
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
	INTO ##Match_SchemeTrans_Match
	FROM [DIMAIN_TR].[SLC_REPL].[dbo].[Match] ma WITH (NOLOCK)
	WHERE ma.[Status] = 1 
	AND ma.RewardStatus IN (0, 1)
	AND ma.TransactionDate >= '2012-01-01'
	AND ma.ID > @SourceTableID_Max
	AND NOT EXISTS (SELECT 1
					FROM [WH_AllPublishers].[Derived].[SchemeTrans] st
					WHERE ma.ID = st.SourceTableID
					AND st.SourceID = 1)

	CREATE CLUSTERED INDEX CIX_ID ON ##Match_SchemeTrans_Match (ID)
	CREATE NONCLUSTERED INDEX IX_PanID ON ##Match_SchemeTrans_Match (PanID)
	
	IF OBJECT_ID('tempdb..#MaskedCardNumber') IS NOT NULL DROP TABLE #MaskedCardNumber
	SELECT	DISTINCT
			PanID = pa.ID
		,	MaskedCardNumber = pc.MaskedCardNumber
	INTO #MaskedCardNumber
	FROM [DIMAIN_TR].[SLC_REPL].[dbo].[Pan] pa
	INNER JOIN [DIMAIN_TR].[SLC_REPL].[dbo].[PaymentCard] pc
		ON pa.PaymentCardID = pc.ID
	WHERE EXISTS (	SELECT 1
					FROM ##Match_SchemeTrans_Match st
					WHERE pa.ID = st.PanID)

	CREATE CLUSTERED INDEX CIX_PanID ON #MaskedCardNumber (PanID, MaskedCardNumber)

--	EXEC('CREATE TABLE [SLC_REPL].[RemoteTables].[Match_SchemeTrans_Match] (ID INT PRIMARY KEY);') AT DIMAIN_TR
	EXEC('TRUNCATE TABLE [SLC_REPL].[RemoteTables].[Match_SchemeTrans_Match]') AT DIMAIN_TR

	EXEC('
	INSERT INTO [DIMAIN_TR].[SLC_REPL].[RemoteTables].[Match_SchemeTrans_Match] WITH (TABLOCK) (ID)
	SELECT ID
	FROM ##Match_SchemeTrans_Match
	ORDER BY ID
	')

	IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans;
	SELECT  d.*
	INTO #Trans
	FROM OPENQUERY(DIMAIN_TR,
		'SELECT	ID = tr.ID
			,   MatchID = tr.MatchID
			,   ClubCash = tr.ClubCash
			,   Commission = tr.Commission
			,   FanID = tr.FanID
			,   TypeID = tr.TypeID
			,   RetailerCashback = ISNULL(tr.ClubCash * tt.Multiplier, 0) 
		FROM [SLC_REPL].[dbo].[Trans] tr
		INNER JOIN [SLC_REPL].[dbo].[TransactionType] tt
			ON tr.TypeID = tt.ID
		INNER JOIN [SLC_REPL].[RemoteTables].[Match_SchemeTrans_Match] ma
			ON ma.ID = tr.MatchID'
	) d 

--	EXEC('DROP TABLE [SLC_REPL].[RemoteTables].[Match_SchemeTrans_Match];') AT DIMAIN_TR
	EXEC('TRUNCATE TABLE [SLC_REPL].[RemoteTables].[Match_SchemeTrans_Match];') AT DIMAIN_TR

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
	INNER JOIN [DIMAIN_TR].[SLC_REPL].[dbo].[Fan] fa
		ON tr.FanID = fa.ID
	LEFT JOIN (SELECT DISTINCT SourceUID FROM [Warehouse].[InsightArchive].[QuidcoR4GCustomers]) qs
		ON fa.SourceUID = qs.SourceUID

	CREATE CLUSTERED INDEX CIX_MatchID ON #TransFan (MatchID)

	IF OBJECT_ID('tempdb..#MatchCardHolderPresent') IS NOT NULL DROP TABLE #MatchCardHolderPresent;
	SELECT *
	INTO #MatchCardHolderPresent
	FROM [Warehouse].[Staging].[MatchCardHolderPresent] mchp
	WHERE EXISTS (	SELECT 1
					FROM ##Match_SchemeTrans_Match ma
					WHERE mchp.MatchID = ma.ID)
	
	CREATE CLUSTERED INDEX CIX_MatchID ON #MatchCardHolderPresent (MatchID)

	IF OBJECT_ID('tempdb..#MatchSelfFundedTransaction') IS NOT NULL DROP TABLE #MatchSelfFundedTransaction;
	SELECT *
	INTO #MatchSelfFundedTransaction
	FROM [SLC_REPL].[dbo].[MatchSelfFundedTransaction] msft
	WHERE EXISTS (	SELECT 1
					FROM ##Match_SchemeTrans_Match ma
					WHERE msft.MatchID = ma.ID)
	
	CREATE CLUSTERED INDEX CIX_MatchID ON #MatchSelfFundedTransaction (MatchID)
	
	DECLARE @Today DATETIME = GETDATE()

	IF OBJECT_ID('tempdb..#Customer_SchemeMembership') IS NOT NULL DROP TABLE #Customer_SchemeMembership;
	SELECT	csm.FanID
		,	csm.SchemeMembershipTypeID
		,	csm.StartDate
		,	COALESCE(csm.EndDate, @Today) AS EndDate
	INTO #Customer_SchemeMembership
	FROM [Warehouse].[Relational].[Customer_SchemeMembership] csm
	WHERE EXISTS (	SELECT 1
					FROM #Trans tr
					WHERE tr.FanID = csm.FanID)
	
	CREATE CLUSTERED INDEX CIX_FanID ON #Customer_SchemeMembership (FanID)
		
	IF OBJECT_ID('tempdb..#DirectLoad_OutletOinToPartnerID') IS NOT NULL DROP TABLE #DirectLoad_OutletOinToPartnerID;	
	SELECT	*
		,	COALESCE(o.OutletID, o.DirectDebitOriginatorID) AS RetailOutlet_DirectDebitOriginatorID
	INTO #DirectLoad_OutletOinToPartnerID
	FROM [Warehouse].[APW].[DirectLoad_OutletOinToPartnerID] o
	WHERE EXISTS (	SELECT 1
					FROM ##Match_SchemeTrans_Match m
					WHERE o.PartnerCommissionRuleID = m.PartnerCommissionRuleID)
	AND o.PartnerID NOT IN (4433, 4447)
	UNION
	SELECT *
		,	COALESCE(o.OutletID, o.DirectDebitOriginatorID) AS RetailOutlet_DirectDebitOriginatorID
	FROM [Warehouse].[APW].[DirectLoad_OutletOinToPartnerID] o
	WHERE EXISTS (	SELECT 1
					FROM ##Match_SchemeTrans_Match m
					WHERE o.DirectDebitOriginatorID = m.DirectDebitOriginatorID)
	AND o.PartnerID NOT IN (4433, 4447)
	UNION
	SELECT *
		,	COALESCE(o.OutletID, o.DirectDebitOriginatorID) AS RetailOutlet_DirectDebitOriginatorID
	FROM [Warehouse].[APW].[DirectLoad_OutletOinToPartnerID] o
	WHERE EXISTS (	SELECT 1
					FROM ##Match_SchemeTrans_Match m
					WHERE o.OutletID = m.RetailOutletID)
	AND o.PartnerID NOT IN (4433, 4447)
	
	IF OBJECT_ID('tempdb..#PartnerCommissionRule') IS NOT NULL DROP TABLE #PartnerCommissionRule;
	SELECT	DISTINCT
			pcr.ID
		,	pcr.PartnerID
		,	pcr.RequiredIronOfferID
	INTO #PartnerCommissionRule
	FROM [DIMAIN_TR].[SLC_REPL].[dbo].[PartnerCommissionRule] pcr
	WHERE pcr.TypeID = 2
	AND EXISTS (SELECT 1
				FROM ##Match_SchemeTrans_Match ma
				WHERE ma.PartnerCommissionRuleID = pcr.ID)
	UNION
	SELECT	DISTINCT
			pcr.ID
		,	pcr.PartnerID
		,	pcr.RequiredIronOfferID
	FROM [DIMAIN_TR].[SLC_REPL].[dbo].[PartnerCommissionRule] pcr
	WHERE pcr.TypeID = 2
	AND EXISTS (SELECT 1
				FROM ##Match_SchemeTrans_Match ma
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
			MatchID = ma.ID
		,	ClubID = tf.ClubID
		,	FanID = tf.FanID
		,	TranDate = ma.TransactionDate
		,	AddedDate = ma.AddedDate
		,	Spend = ma.Amount
	 	,	CardHolderPresentData = LEFT(COALESCE(ma.CardHolderPresentData, mchp.CardholderPresentData), 1)
		,	RetailerCashback = tf.RetailerCashback
		,	PanID = ma.PanID
		,	MaskedCardNumber = mcn.MaskedCardNumber
		,	QuidcoSourceUID = tf.QuidcoSourceUID
		,	SchemeMembershipTypeID = csm.SchemeMembershipTypeID
		,	UpstreamMatchID = msft.MatchID
		,	OfferPercentage = ISNULL(CONVERT(DECIMAL(32, 4), tf.Commission), 0)
		,	CommissionRate = ISNULL(CONVERT(DECIMAL(32, 4), ma.PartnerCommissionRate), 0)
		,	VATCommission = ISNULL(ma.VatAmount, 0)
		,	GrossCommission = ISNULL(ma.PartnerCommissionAmount, 0)
		,	TranTime = CONVERT(TIME, ma.TransactionDate)
		,	RetailOutlet_DirectDebitOriginatorID = ma.RetailOutlet_DirectDebitOriginatorID
		,	RetailOutletID = ma.RetailOutletID
		,	DirectDebitOriginatorID = ma.DirectDebitOriginatorID
		,	PartnerCommissionRuleID = ma.PartnerCommissionRuleID
		,	AffiliateCommissionAmount = ma.AffiliateCommissionAmount
		,	VectorID = ma.VectorID
		,	PartnerID = o.PartnerID
		,	IronOfferID = pcr.RequiredIronOfferID
		,	OIN = o.OIN
		,	DDInvestmentProportionOfCashback = o.DDInvestmentProportionOfCashback
		,	Channel = o.Channel
		,	OutletID = o.OutletID
	INTO #MatchTransFan
	FROM ##Match_SchemeTrans_Match ma
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
	LEFT JOIN #MaskedCardNumber mcn
		ON ma.PanID = mcn.PanID
	WHERE NOT (ma.VectorID = 40 AND tf.TypeID = 24) -- Jason Shipp 10/05/2019 -- filter out non-nominee RBS direct debit transactions
	UNION
	SELECT	DISTINCT
			MatchID = ma.ID
		,	ClubID = tf.ClubID
		,	FanID = tf.FanID
		,	TranDate = ma.TransactionDate
		,	AddedDate = ma.AddedDate
		,	Spend = ma.Amount
	 	,	CardHolderPresentData = LEFT(COALESCE(ma.CardHolderPresentData, mchp.CardholderPresentData), 1)
		,	RetailerCashback = tf.RetailerCashback
		,	PanID = ma.PanID
		,	MaskedCardNumber = mcn.MaskedCardNumber
		,	QuidcoSourceUID = tf.QuidcoSourceUID
		,	SchemeMembershipTypeID = csm.SchemeMembershipTypeID
		,	UpstreamMatchID = msft.MatchID
		,	OfferPercentage = ISNULL(CONVERT(DECIMAL(32, 4), tf.Commission), 0)
		,	CommissionRate = ISNULL(CONVERT(DECIMAL(32, 4), ma.PartnerCommissionRate), 0)
		,	VATCommission = ISNULL(ma.VatAmount, 0)
		,	GrossCommission = ISNULL(ma.PartnerCommissionAmount, 0)
		,	TranTime = CONVERT(TIME, ma.TransactionDate)
		,	RetailOutlet_DirectDebitOriginatorID = ma.RetailOutlet_DirectDebitOriginatorID
		,	RetailOutletID = ma.RetailOutletID
		,	DirectDebitOriginatorID = ma.DirectDebitOriginatorID
		,	PartnerCommissionRuleID = ma.PartnerCommissionRuleID
		,	AffiliateCommissionAmount = ma.AffiliateCommissionAmount
		,	VectorID = ma.VectorID
		,	PartnerID = o.PartnerID
		,	IronOfferID = pcr.RequiredIronOfferID
		,	OIN = o.OIN
		,	DDInvestmentProportionOfCashback = o.DDInvestmentProportionOfCashback
		,	Channel = o.Channel
		,	OutletID = o.OutletID
	FROM ##Match_SchemeTrans_Match ma
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
	LEFT JOIN #MaskedCardNumber mcn
		ON ma.PanID = mcn.PanID
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
	FROM [Warehouse].[Relational].[nFI_Partner_Deals]

	CREATE CLUSTERED INDEX CIX_ClubIDPartnerID ON #nFI_Partner_Deals (ClubID, PartnerID)
	
	IF OBJECT_ID('tempdb..#SchemeTransTemp') IS NOT NULL DROP TABLE #SchemeTransTemp;
	SELECT	DISTINCT
			mtf.MatchID
		,	mtf.ClubID AS PublisherID
		,	mtf.FanID
		,	mtf.TranDate
		,	mtf.AddedDate
		,	mtf.Spend		
		,	CONVERT(DECIMAL(32, 2),	CASE
										WHEN mtf.OIN IS NOT NULL THEN (mtf.RetailerCashback + (mtf.RetailerCashback * mtf.DDInvestmentProportionOfCashback)) -- For DDs, Cashback + Override, Where Override = Cashback x a multiplier -- Jason Shipp 15/05/2019
										ELSE mtf.AffiliateCommissionAmount
									END) AS Investment
		,	mtf.PartnerID
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
		,	mtf.MaskedCardNumber
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
	LEFT JOIN [Warehouse].[APW].PartnerAlternate pa ON mtf.PartnerID = pa.PartnerID
	LEFT JOIN #nFI_Partner_Deals pda
		ON pa.AlternatePartnerID = pda.PartnerID
		AND mtf.ClubID = pdo.ClubID
		AND mtf.TranDate >= pda.StartDate
		AND mtf.TranDate <= pda.EndDate
	LEFT JOIN [Warehouse].[APW].DirectLoad_IronOfferSpendStretch iss ON mtf.IronOfferID = iss.IronOfferID
	LEFT JOIN [Warehouse].[APW].PublisherExclude pe ON mtf.ClubID = pe.PublisherID AND mtf.PartnerID = pe.RetailerID AND mtf.TranDate BETWEEN pe.StartDate AND pe.EndDate
	INNER JOIN [Warehouse].[APW].DirectLoad_PublisherIDs pu ON mtf.ClubID = pu.PublisherID
	LEFT JOIN [Warehouse].[APW].DirectLoad_RetailerOnline ro ON mtf.PartnerID = ro.RetailerID

	
	INSERT INTO [WH_AllPublishers].[Derived].[SchemeTrans] ([SourceID]
														,	[SourceTableID]
														,	[PublisherID]
														,	[SubPublisherID]
														,	[NotRewardManaged]
														,	[RetailerID]
														,	[PartnerID]
														,	[OfferID]
														,	[IronOfferID]
														,	[OfferPercentage]
														,	[CommissionRate]
														,	[OutletID]
														,	[FanID]
														,	[PanID]
														,	[MaskedCardNumber]
														,	[Spend]
														,	[RetailerCashback]
														,	[Investment]
														,	[PublisherCommission]
														,	[RewardCommission]
														,	[VATCommission]
														,	[GrossCommission]
														,	[TranDate]
														,	[TranFixDate]
														,	[TranTime]
														,	[IsNegative]
														,	[IsOnline]
														,	[IsSpendStretch]
														,	[SpendStretchAmount]
														,	[IsRetailMonthly]
														,	[IsRetailerReport]
														,	[AddedDate])
	SELECT	DISTINCT
			[SourceID] = 1
		,	[SourceTableID] = c.MatchID
		,	[PublisherID] = CASE
								WHEN c.PublisherID = 138 THEN 132
								ELSE c.PublisherID
							END
		,	[SubPublisherID] =	CASE
									WHEN c.QuidcoSourceUID IS NOT NULL THEN 1	--	Quidco R4G
									WHEN c.SchemeMembershipTypeID IS NULL THEN 0
									WHEN c.SchemeMembershipTypeID IN (6, 7) THEN 2	--	NWG Front Book
									ELSE 3
								END

		,	[NotRewardManaged] =	CASE
										WHEN c.DealManagedBy = 2 THEN 1
										ELSE 0
									END
		,	[RetailerID] = c.RetailerID
		,	[PartnerID] = c.PartnerID
		,	[OfferID] = o.OfferID
		,	[IronOfferID] = c.IronOfferID
		,	[OfferPercentage] = c.OfferPercentage
		,	[CommissionRate] = c.CommissionRate
		,	[OutletID] = c.OutletID
		,	[FanID] = c.FanID
		,	[PanID] = c.PanID
		,	[MaskedCardNumber] = c.MaskedCardNumber
		,	[Spend] = CONVERT(DECIMAL(32,2), c.Spend)
		,	[RetailerCashback] = CONVERT(DECIMAL(32,2), c.RetailerCashback)
		,	[Investment] = CONVERT(DECIMAL(32,2), c.Investment)
		,	[PublisherCommission] = CONVERT(DECIMAL(32,2), (c2.Commission * c2.PublisherShare) / c2.TotalShare)
		,	[RewardCommission] = CONVERT(DECIMAL(32,2), (c2.Commission * c2.RewardShare) / c2.TotalShare)
		,	[VATCommission] = CONVERT(DECIMAL(32,2), c.VATCommission)
		,	[GrossCommission] = CONVERT(DECIMAL(32,2), c.GrossCommission)
		,	[TranDate] = c.TranDate
		,	[TranFixDate] = CASE
								WHEN c.AddedDate <= c2.CheckDate THEN c.TranDate
								ELSE NULL
							END
		,	[TranTime] = c.TranTime
		,	[IsNegative] =	CASE
								WHEN Spend < 0 THEN 1
								ELSE 0
							END
		,	[IsOnline] =	CASE
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
							END
		,	[IsSpendStretch] =	CASE
									WHEN c.SpendStretchAmount IS NULL THEN NULL
									WHEN c.SpendStretchAmount <= c.Spend THEN 1
									ELSE 0
								END
		,	[SpendStretchAmount] = CONVERT(DECIMAL(32,2), c.SpendStretchAmount)
		,	[IsRetailMonthly] =	CASE
									WHEN c.MonthlyExcludeID IS NULL AND c.UpstreamMatchID IS NULL AND c.DealManagedBy = 1 THEN 1
									ELSE 0
								END
		,	[IsRetailerReport] =	CASE
										WHEN c.UpstreamMatchID IS NULL AND c.DealManagedBy = 1 THEN 1
										ELSE 0
									END
		,	[AddedDate] = c.AddedDate

	FROM #SchemeTransTemp c
	INNER JOIN [WH_AllPublishers].[Derived].[Offer] o
		ON c.IronOfferID = o.IronOfferID
	CROSS APPLY (	SELECT	CheckDate = DATEADD(MONTH, 1, DATEFROMPARTS(DATEPART(YEAR, TranDate), DATEPART(MONTH, TranDate), 15))
						,	Investment - RetailerCashback AS Commission
						,	RewardShare =	CASE
												WHEN COALESCE(c.PublisherShare, 0.00) = 0.00 THEN 100.00
												ELSE COALESCE(c.RewardShare, 100.00)
											END
						,	PublisherShare = COALESCE(c.PublisherShare, 0.00)
						,	TotalShare = 100.00) c2
	--WHERE EXISTS (	SELECT 1
	--				FROM #Partners pa
	--				WHERE c.RetailerID = pa.ID)

	DROP TABLE ##Match_SchemeTrans_Match

END