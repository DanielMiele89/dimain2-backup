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
CREATE PROCEDURE [APW].[DirectLoad_SchemeTrans_Incremental] 
	(
		@MatchID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

	-- Refresh RetailOutletID/OIN - PartnerID linking table --Jason Shipp 05/03/2019

	--The duplicate key value is (<NULL>, 312, 50925)
	TRUNCATE TABLE APW.DirectLoad_OutletOinToPartnerID;

	INSERT INTO APW.DirectLoad_OutletOinToPartnerID (
		OutletID
		, PartnerID
		, Channel
		, OIN
		, IronOfferID
		, DirectDebitOriginatorID
		, StartDate
		, EndDate
		, DDInvestmentProportionOfCashback
		, PartnerCommissionRuleID
	)
	SELECT	NULL AS OutletID	--	MFDD
		,	oin.PartnerID
		,	1 AS Channel
		,	oin.OIN
		,	ddo.IronOfferID
		,	o.ID AS DirectDebitOriginatorID
		,	oin.StartDate
		,	oin.EndDate
		,	CASE
				WHEN ddo.IronOfferID = 22166 THEN 0.30
				WHEN ddo.IronOfferID = 23374 THEN 0.50
				WHEN ddo.IronOfferID = 24050 THEN 0.4333
				ELSE pd.[Override]
			END AS DDInvestmentProportionOfCashback
		,	pcr.ID AS PartnerCommissionRuleID
	FROM [Warehouse].[Relational].[DirectDebit_MFDD_IncentivisedOINs] oin
	INNER JOIN [Warehouse].[Relational].[DirectDebitOriginator] o
		ON oin.OIN = o.OIN
	INNER JOIN [SLC_REPL].[dbo].[DirectDebitOfferOINs] ddo
		ON oin.OIN = ddo.OIN
	INNER JOIN [SLC_REPL].[dbo].[IronOffer] iof
		ON oin.PartnerID = iof.PartnerID
		AND ddo.IronOfferID = iof.ID
	LEFT JOIN [SLC_REPL].[dbo].[PartnerCommissionRule] pcr
		ON ddo.IronOfferID = pcr.RequiredIronOfferID
		AND pcr.TypeID = 2
		AND pcr.DeletionDate IS NULL
	LEFT JOIN [Warehouse].[Relational].nFI_Partner_Deals pd -- Populated from this spreadsheet owned by Finance: S:\Finance\Commercial Terms - PublisherRetailer\Commercial Terms - Publisher_Retailer2.xlsx
		ON oin.PartnerID = pd.PartnerID
		AND (COALESCE(oin.EndDate, '9999-01-01') BETWEEN pd.StartDate AND COALESCE(pd.EndDate, '9999-01-01'))
		AND pd.ClubID = 132



	UNION
	
	SELECT -- CLO
		ro.OutletID
		, ro.PartnerID
		, CASE ro.Channel 
			WHEN 1 THEN 1 -- 1 = Online. Otherwise, offline
			WHEN 0 THEN 0
			WHEN 2 THEN 0
			ELSE NULL 
		END AS Channel
		, NULL AS OIN
		, NULL AS IronOfferID
		, NULL AS DirectDebitOriginatorID
		, NULL AS StartDate
		, NULL AS EndDate
		, NULL AS DDInvestmentProportionOfCashback
		, NULL AS PartnerCommissionRuleID
	FROM [Warehouse].APW.DirectLoad_RetailOutlet ro; -- This is populated via: WHB.IronOfferPartnerTrans_Outlet_V1_5 => APW.DirectLoad_Outlets_Fetch => APW Build SSIS package data flow

	-- Fetch incentivised transactions

--	DECLARE @MatchID INT = 390280066
	DECLARE @Today DATETIME = GETDATE()

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
--	INTO #Check
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
	AND m.TransactionDate >= '2012-01-01'
	AND o.PartnerID != 4433
	AND o.PartnerID != 4447
	AND (o.StartDate IS NULL OR m.TransactionDate >= o.StartDate) -- Make sure OIN is incentivised when transaction occurred (if there is an OIN) -- Jason Shipp 05/03/2019
	AND (o.EndDate IS NULL OR m.TransactionDate <= o.EndDate)
	AND NOT (m.VectorID = 40 AND t.TypeID = 24) -- Jason Shipp 10/05/2019 -- filter out non-nominee RBS direct debit transactions
	AND m.ID > @MatchID
	AND t.MatchID > @MatchID
	
	--AND o.PartnerID != 4938	--	RF 20211017
	
	;

END
