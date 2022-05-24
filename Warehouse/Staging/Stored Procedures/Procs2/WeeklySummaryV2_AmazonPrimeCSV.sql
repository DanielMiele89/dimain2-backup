
/******************************************************************************
Author: William Allen
Created: 20/07/2021
Purpose: 
	- Fetch Amazon Prime transaction data summary by weeks used in the latest Weekly Summary reports, for RPT
------------------------------------------------------------------------------
Modification History



******************************************************************************/
CREATE PROCEDURE [Staging].[WeeklySummaryV2_AmazonPrimeCSV]

AS
BEGIN
	
	SET NOCOUNT ON;
	--SET FMTONLY OFF;
	
		DECLARE @StartDate DATE = DATEADD(MONTH, -1, GETDATE())
				--@StartDate DATE = '2021-07-01'	--	DATEADD(MONTH, -6, GETDATE())
			,	@EndDate DATE = GETDATE()
		

		IF @EndDate < '2021-11-16' SET @EndDate = '2021-11-12'
		
			
		IF OBJECT_ID('tempdb..#Partners') IS NOT NULL DROP TABLE #Partners
		SELECT *
		INTO #Partners
		FROM [SLC_REPL].[dbo].[Partner]
		WHERE ID IN (4905)
		
		IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
		SELECT cc.*
		INTO #CC
		FROM [Relational].[ConsumerCombination] cc
		INNER JOIN [Relational].[MCCList] mcc
			ON cc.MCCID = mcc.MCCID
		WHERE EXISTS (	SELECT 1
						FROM [SLC_REPL].[dbo].[RetailOutlet] ro
						WHERE cc.MID = ro.MerchantID
						AND (cc.Narrative LIKE ro.MerchantNarrative OR ro.MerchantNarrative IS NULL)
						AND (mcc.MCC = ro.MerchantCategoryCode OR ro.MerchantCategoryCode IS NULL)
						AND ro.PartnerID IN (SELECT ID FROM #Partners))
		
		CREATE CLUSTERED INDEX CIX_CCID ON #CC (ConsumerCombinationID)
		
		IF OBJECT_ID('tempdb..#IOF') IS NOT NULL DROP TABLE #IOF
		SELECT	iof.IronOfferID
			,	iof.IronOfferName
			,	iof.StartDate
			,	iof.EndDate
			,	pcr.Channel
			,	pcr.CommissionRate * 0.01 AS CommissionRate
			,	COALESCE(pcr.MinimumBasketSize, 0) AS MinimumBasketSize
			,	COALESCE(pcr.MaximumBasketSize, 9999999) AS MaximumBasketSize
		INTO #IOF
		FROM Relational.IronOffer iof
		INNER JOIN Relational.IronOffer_PartnerCommissionRule pcr
			ON iof.IronOfferID = pcr.IronOfferID
		WHERE iof.PartnerID IN (SELECT ID FROM #Partners)
		AND pcr.TypeID = 1
		AND DeletionDate IS NULL
		AND iof.EndDate > @StartDate
		
		UPDATE iof
		SET iof.MaximumBasketSize = iof2.MinimumBasketSize - 0.01
		FROM #IOF iof
		INNER JOIN #IOF iof2
			ON iof.IronOfferID = iof2.IronOfferID
			AND iof.MinimumBasketSize < iof2.MinimumBasketSize
		
		CREATE CLUSTERED INDEX CIX_IronOfferID ON #IOF (IronOfferID)
		
		IF OBJECT_ID('tempdb..#IOM') IS NOT NULL DROP TABLE #IOM
		SELECT	iof.IronOfferID
			,	iof.IronOfferName
			,	iof.CommissionRate
			,	iof.MinimumBasketSize
			,	iof.MaximumBasketSize
			,	iom.CompositeID
			,	cu.FanID
			,	cl.CINID
			,	iom.StartDate
			,	iom.EndDate
		INTO #IOM
		FROM #IOF iof
		INNER JOIN [SLC_REPL].dbo.[IronOfferMember] iom
			ON iof.IronOfferID = iom.IronOfferID
		INNER JOIN [Relational].[Customer] cu
			ON iom.CompositeID = cu.CompositeID
		INNER JOIN [Relational].[CINList] cl
			ON cu.SourceUID = cl.CIN
		WHERE iom.EndDate > @StartDate
		
		INSERT INTO #IOM
		SELECT	iof.IronOfferID
			,	iof.IronOfferName
			,	iof.CommissionRate
			,	iof.MinimumBasketSize
			,	iof.MaximumBasketSize
			,	iom.CompositeID
			,	cu.FanID
			,	cl.CINID
			,	iom.StartDate
			,	COALESCE(iom.EndDate, iof.EndDate) AS EndDate
		FROM #IOF iof
		INNER JOIN [SLC_REPL].dbo.[IronOfferMember] iom
			ON iof.IronOfferID = iom.IronOfferID
		INNER JOIN [Relational].[Customer] cu
			ON iom.CompositeID = cu.CompositeID
		INNER JOIN [Relational].[CINList] cl
			ON cu.SourceUID = cl.CIN
		WHERE iom.EndDate IS NULL
		
		CREATE CLUSTERED INDEX CIX_CCID ON #IOM (StartDate, EndDate, CINID)
		
		IF OBJECT_ID('tempdb..#CT') IS NOT NULL DROP TABLE #CT
		SELECT	cc.MID
			,	ct.CINID
			,	ct.Amount
			,	ct.TranDate
			,	37 AS VectorID
			,	ct.FileID
			,	ct.RowNum
		INTO #CT
		FROM [Relational].[ConsumerTransaction] ct
		INNER JOIN #CC cc
			ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
		WHERE TranDate >= @StartDate
		AND TranDate < '2021-07-31'
		
		INSERT INTO #CT
		SELECT	cc.MID
			,	ct.CINID
			,	ct.Amount
			,	ct.TranDate
			,	37 AS VectorID
			,	ct.FileID
			,	ct.RowNum
		FROM [Relational].[ConsumerTransactionHolding] ct
		INNER JOIN #CC cc
			ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
		WHERE TranDate >= @StartDate
		AND TranDate < '2021-07-31'
		
		INSERT INTO #CT
		SELECT	cc.MID
			,	ct.CINID
			,	ct.Amount
			,	ct.TranDate
			,	38 AS VectorID
			,	ct.FileID
			,	ct.RowNum
		FROM [Relational].[ConsumerTransaction_CreditCard] ct
		INNER JOIN #CC cc
			ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
		WHERE TranDate >= @StartDate
		AND TranDate < '2021-07-31'
		
		INSERT INTO #CT
		SELECT	cc.MID
			,	ct.CINID
			,	ct.Amount
			,	ct.TranDate
			,	38 AS VectorID
			,	ct.FileID
			,	ct.RowNum
		FROM [Relational].[ConsumerTransaction_CreditCardHolding] ct
		INNER JOIN #CC cc
			ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
		WHERE TranDate >= @StartDate
		AND TranDate < '2021-07-31'
		
		CREATE CLUSTERED INDEX CIX_CCID ON #CT (TranDate, CINID)
			
			IF OBJECT_ID('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates;
			WITH
			Tally AS (	SELECT	TOP 365
								ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS ID
						FROM MASTER.dbo.SysColumns),
		
			Dates AS (	SELECT	ID
							,	DATEADD(DAY, ID, '2021-06-27') AS Date
							,	((ID - 1) / 7) + 1 AS WeekNumber
						FROM Tally),
		
			WeekRange AS (	SELECT	WeekNumber
								,	CONVERT(VARCHAR(11), MIN(Date)) AS FirstDate
								,	CONVERT(VARCHAR(11), MAX(Date)) AS LastDate
							FROM Dates
							GROUP BY WeekNumber)
		
			SELECT	d.ID
				,	d.Date
				,	d.WeekNumber
				,	wr.FirstDate + ' - ' + wr.LastDate AS WeekRange
				,	wr.FirstDate
				,	wr.LastDate
			INTO #Dates
			FROM Dates d
			LEFT JOIN WeekRange wr
				ON d.WeekNumber = wr.WeekNumber
		
			IF OBJECT_ID('tempdb..#AcquireTransactions') IS NOT NULL DROP TABLE #AcquireTransactions
			SELECT	iom.IronOfferID
				,	iom.IronOfferName
				,	iom.CommissionRate
				,	iom.MinimumBasketSize
				,	iom.MaximumBasketSize
				,	iom.StartDate
				,	iom.EndDate
				,	iom.CompositeID
				,	iom.FanID
				,	iom.CINID
				,	ct.MID
				,	ct.Amount
				,	ct.TranDate
				,	ct.VectorID
				,	ct.FileID
				,	ct.RowNum
				,	cu.DeactivatedDate
			INTO #AcquireTransactions
			FROM #IOM iom
			INNER JOIN #CT ct
				ON iom.CINID = ct.CINID
				AND ct.TranDate BETWEEN iom.StartDate AND iom.EndDate
			INNER JOIN [Relational].[Customer] cu
				ON iom.CompositeID = cu.CompositeID
			WHERE Amount BETWEEN MinimumBasketSize AND MaximumBasketSize
			AND (cu.DeactivatedDate IS NULL OR ct.TranDate < cu.DeactivatedDate)
			AND iom.IronOfferID = 22751
		
			DECLARE @MatchID INT = 300000000
				,	@PartnerID INT = 4905
		
			DECLARE @Today DATETIME = GETDATE()
		
			
			IF OBJECT_ID('tempdb..#IncentivisedTrans') IS NOT NULL DROP TABLE #IncentivisedTrans
			SELECT	DISTINCT
					m.ID AS MatchID
				,	m.VectorID
				,	m.VectorMajorID
				,	m.VectorMinorID
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
				,	pcr.RequiredIronOfferID AS IronOfferID
				,	ISNULL(t.ClubCash * tt.Multiplier,0) AS RetailerCashback
				,	CASE WHEN o.OIN IS NOT NULL THEN -1 ELSE o.OutletID END AS OutletID -- Jason Shipp 15/05/2019
				,	m.PanID
				,	ISNULL(ROUND(t.Commission, 2), 0) AS OfferPercentage
				,	ISNULL(m.PartnerCommissionRate, 0) AS CommissionRate
				,	ISNULL(m.VatAmount, 0) AS VATCommission
				,	ISNULL(m.PartnerCommissionAmount, 0) AS GrossCommission
				,	CAST(m.TransactionDate AS time) AS TranTime
			INTO #IncentivisedTrans
			FROM SLC_Repl.dbo.Match m WITH (NOLOCK)
			INNER JOIN APW.DirectLoad_OutletOinToPartnerID o
				ON m.RetailOutletID = o.OutletID
			INNER JOIN SLC_Repl.dbo.PartnerCommissionRule pcr
				ON m.PartnerCommissionRuleID = pcr.ID
			INNER JOIN SLC_Repl.dbo.Trans t WITH (NOLOCK)
				ON t.MatchID = m.ID
			INNER JOIN SLC_Repl.dbo.Fan f
				ON t.FanID = f.ID
			LEFT JOIN Relational.nFI_Partner_Deals pdo
				ON o.PartnerID = pdo.PartnerID AND f.ClubID = pdo.ClubID AND m.TransactionDate >= pdo.StartDate AND (pdo.EndDate IS NULL OR m.TransactionDate <= pdo.EndDate)
			LEFT JOIN SLC_Repl.dbo.TransactionType tt
				ON t.TypeID = tt.ID
			LEFT JOIN APW.PartnerAlternate pa
				ON o.PartnerID = pa.PartnerID
			LEFT JOIN Relational.nFI_Partner_Deals pda
				ON pa.AlternatePartnerID = pda.PartnerID AND f.ClubID = pdo.ClubID AND m.TransactionDate >= pda.StartDate AND (pda.EndDate IS NULL OR m.TransactionDate <= pda.EndDate)
			WHERE 1 = 1
			AND m.[status] = 1 
			AND m.rewardstatus IN (0,1)
			AND pcr.TypeID = 2
			AND (o.StartDate IS NULL OR m.TransactionDate >= o.StartDate) -- Make sure OIN is incentivised when transaction occurred (if there is an OIN) -- Jason Shipp 05/03/2019
			AND (o.EndDate IS NULL OR m.TransactionDate <= o.EndDate)
			AND m.ID >= @MatchID
			AND t.MatchID >= @MatchID
			AND o.PartnerID IN (@PartnerID)
		--	AND NOT (m.VectorID = 40 AND t.TypeID = 24) -- Jason Shipp 10/05/2019 -- filter out non-nominee RBS direct debit transactions
		
			IF OBJECT_ID('tempdb..#Transactions') IS NOT NULL DROP TABLE #Transactions
			SELECT	tr.WeekNumber
				,	tr.WeekRange
				,	tr.MatchID
				,	tr.MerchantID
				,	tr.MerchantDBAName
				,	tr.Date
				,	tr.Time
				,	tr.CardNumber
				,	tr.AmountSpent
				,	tr.OfferCode
				,	tr.OfferPercentage
				,	tr.CashbackEarned
				,	tr.CommissionRate
				,	tr.NetAmount
				,	tr.VatAmount
				,	tr.GrossAmount
			INTO #Transactions
			FROM (	SELECT	d.WeekNumber
						,	d.WeekRange
						,	c.MatchID
						,	ro.MerchantID
						,	LTRIM(RTRIM(COALESCE(ct.MerchantDBAName, dt.LocationName))) AS MerchantDBAName
						,	c.TranDate AS Date
						,	c.TranTime AS Time
						,	pc.MaskedCardNumber AS CardNumber
						,	c.Spend AS AmountSpent
						,	'TA' AS OfferCode
						,	c.OfferPercentage
						,	c.RetailerCashback AS CashbackEarned
						,	c.CommissionRate
						,	c.Investment AS NetAmount
						,	c.VATCommission AS VatAmount
						,	c.GrossCommission AS GrossAmount
					FROM #IncentivisedTrans c
					INNER JOIN #Dates d
						ON CONVERT(DATE, c.TranDate) = CONVERT(DATE, d.Date)
					INNER JOIN SLC_REPL.dbo.RetailOutlet ro
						ON c.OutletID = ro.ID
					LEFT JOIN SLC_REPL.dbo.Pan pa
						ON c.PanID = pa.ID
					LEFT JOIN SLC_REPL.dbo.PaymentCard pc
						ON pa.PaymentCardID = pc.ID
					LEFT JOIN [Archive_Light].[dbo].[CBP_Credit_TransactionHistory] ct
						ON c.VectorMajorID = ct.FileID
						AND c.VectorMinorID = ct.RowNum
						AND c.VectorID = 38
					LEFT JOIN [Archive_Light].[dbo].[NobleTransactionHistory_MIDI] dt
						ON c.VectorMajorID = dt.FileID
						AND c.VectorMinorID = dt.RowNum
						AND c.VectorID = 37
					UNION ALL
					SELECT	d.WeekNumber
						,	d.WeekRange
							,	NULL AS MatchID
						,	mt.MID AS MerchantID
						,	LTRIM(RTRIM(COALESCE(ct.MerchantDBAName, dt.LocationName))) AS MerchantDBAName
						,	mt.TranDate AS Date
						,	'' AS Time
						,	pc.MaskedCardNumber AS CardNumber
						,	mt.Amount AS AmountSpent
						,	'TA' AS OfferCode
						,	0 AS OfferPercentage
						,	0 AS CashbackEarned
						,	0 AS CommissionRate
						,	0 AS NetAmount
						,	0 AS VatAmount
						,	0 AS GrossAmount
					FROM #AcquireTransactions mt
					INNER JOIN #Dates d
						ON CONVERT(DATE, mt.TranDate) = CONVERT(DATE, d.Date)
					LEFT JOIN [Archive_Light].[dbo].[CBP_Credit_TransactionHistory] ct
						ON mt.FileID = ct.FileID
						AND mt.RowNum = ct.RowNum
						AND mt.VectorID = 38
					LEFT JOIN [Archive_Light].[dbo].[NobleTransactionHistory_MIDI] dt
						ON mt.FileID = dt.FileID
						AND mt.RowNum = dt.RowNum
						AND mt.VectorID = 37
					LEFT JOIN SLC_REPL.dbo.PaymentCard pc
						ON COALESCE(ct.PaymentCardID, dt.PaymentCardID) = pc.ID) tr
			ORDER BY tr.Date
		
			
			IF OBJECT_ID('tempdb..#WeekRange') IS NOT NULL 
			DROP TABLE #WeekRange
			SELECT TOP 1 StartDate,EndDate
			INTO #WeekRange
			FROM Warehouse.Staging.WeeklySummaryV2_RetailerAnalysisPeriods
			where RetailerID = 4905
			AND PeriodType = 'Week'
			ORDER BY StartDate DESC
		
			SELECT	tr.WeekNumber
				,	tr.WeekRange
				,	tr.MatchID
				,	tr.MerchantID
				,	tr.MerchantDBAName
				,	tr.Date
				,	tr.Time
				,	tr.CardNumber
				,	tr.AmountSpent
				,	tr.OfferCode
				,	tr.OfferPercentage
				,	tr.CashbackEarned
				,	tr.CommissionRate
				,	tr.NetAmount
				,	tr.VatAmount
				,	tr.GrossAmount
			FROM #Transactions tr
			join #WeekRange wr
			on tr.Date >= wr.StartDate AND tr.Date <= wr.EndDate
			--WHERE WeekRange = 'Jul 12 2021 - Jul 18 2021'
			ORDER BY tr.Date, tr.CardNumber

	

END
