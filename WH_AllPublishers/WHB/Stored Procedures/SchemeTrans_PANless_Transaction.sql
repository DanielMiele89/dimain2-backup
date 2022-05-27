
CREATE PROCEDURE [WHB].[SchemeTrans_PANless_Transaction]

AS
BEGIN

	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#CRT_File') IS NOT NULL DROP TABLE #CRT_File;
	SELECT	FileID = crt.ID
		,	FileName = crt.Filename
		,	MatcherShortName = crt.MatcherShortName
		,	VectorID = crt.VectorID
		,	PublisherID = vtp.PublisherID
	INTO #CRT_File
	FROM [DIMAIN_TR].[SLC_REPL].[dbo].[CRT_File] crt
	LEFT JOIN [WH_AllPublishers].[Report].[VectorIDToPublisherID] vtp
		ON crt.VectorID = vtp.VectorID
	WHERE vtp.PublisherID != 180	--	Visa Barclaycard
	AND vtp.PublisherID != 182	--	Virgin PCA

	CREATE CLUSTERED INDEX CIX_FileID ON #CRT_File (FileID)
		
	IF OBJECT_ID('tempdb..#RetailOutletHashed') IS NOT NULL DROP TABLE #RetailOutletHashed;
	SELECT	ID = MAX(CONVERT(INT, ro.ID))
		,	MerchantID = REPLACE(ro.MerchantID, '#', '')
		,	PartnerID = ro.PartnerID
		,	Channel = MIN(CONVERT(INT, ro.Channel))
	INTO #RetailOutletHashed
	FROM OPENQUERY([DIMAIN_TR],'SELECT * FROM [SLC_REPL].[dbo].[RetailOutlet]') ro
	WHERE MerchantID LIKE '%#%'
	GROUP BY	REPLACE(ro.MerchantID, '#', '')
			,	ro.PartnerID
		
	IF OBJECT_ID('tempdb..#RetailOutlet_Temp') IS NOT NULL DROP TABLE #RetailOutlet_Temp;
	SELECT	ID = MAX(CONVERT(INT, ro.ID))
		,	MerchantID = ro.MerchantID
		,	PartnerID = ro.PartnerID
		,	Channel = MIN(CONVERT(INT, ro.Channel))
	INTO #RetailOutlet_Temp
	FROM OPENQUERY([DIMAIN_TR],'SELECT * FROM [SLC_REPL].[dbo].[RetailOutlet]') ro
	WHERE MerchantID NOT LIKE '%#%'
	GROUP BY	ro.MerchantID
			,	ro.PartnerID

	INSERT INTO #RetailOutlet_Temp
	SELECT	ID = ro.ID
		,	MerchantID = ro.MerchantID
		,	PartnerID = ro.PartnerID
		,	Channel = ro.Channel
	FROM #RetailOutletHashed ro
	WHERE NOT EXISTS (	SELECT 1
						FROM #RetailOutlet_Temp ro2
						WHERE ro.MerchantID = ro2.MerchantID
						AND ro.PartnerID = ro2.PartnerID)

	IF OBJECT_ID('tempdb..#RetailOutlet') IS NOT NULL DROP TABLE #RetailOutlet;
	SELECT	PartnerID = ro.PartnerID
		,	MerchantID = ro.MerchantID
		,	RetailOutletID = ro.ID
		,	IsOnline =	CASE
							WHEN ro.Channel = 1 THEN 1
							ELSE 0
						END
	INTO #RetailOutlet
	FROM #RetailOutlet_Temp ro

	CREATE CLUSTERED INDEX CIX_MerchantID ON #RetailOutlet (PartnerID, MerchantID, RetailOutletID, IsOnline)
	
	IF OBJECT_ID('tempdb..#Offer') IS NOT NULL DROP TABLE #Offer;
	SELECT	RetailerID = o.RetailerID
		,	PartnerID = o.PartnerID
		,	OfferID = CONVERT(INT, o.OfferID)
		,	IronOfferID = o.IronOfferID
		,	OfferCode = CONVERT(VARCHAR(64), o.OfferCode)
		,	SourceOfferID = o.SourceOfferID
		,	BaseCashBackRate = o.BaseCashBackRate
		,	SpendStretchAmount = o.SpendStretchAmount_1
	INTO #Offer
	FROM [WH_AllPublishers].[Derived].[Offer] o
	WHERE OfferCode IS NOT NULL
	
	INSERT INTO #Offer
	SELECT	RetailerID = o.RetailerID
		,	PartnerID = o.PartnerID
		,	OfferID = CONVERT(INT, o.OfferID)
		,	IronOfferID = o.IronOfferID
		,	OfferCode = CONVERT(VARCHAR(64), o.IronOfferID)
		,	SourceOfferID = o.SourceOfferID
		,	BaseCashBackRate = o.BaseCashBackRate
		,	SpendStretchAmount = o.SpendStretchAmount_1
	FROM [WH_AllPublishers].[Derived].[Offer] o
	WHERE IronOfferID IS NOT NULL
	
	INSERT INTO #Offer
	SELECT	RetailerID = o.RetailerID
		,	PartnerID = o.PartnerID
		,	OfferID = CONVERT(INT, o.OfferID)
		,	IronOfferID = o.IronOfferID
		,	OfferCode = REPLACE(CONVERT(VARCHAR(64), o.OfferGUID), '-', '')
		,	SourceOfferID = o.SourceOfferID
		,	BaseCashBackRate = o.BaseCashBackRate
		,	SpendStretchAmount = o.SpendStretchAmount_1
	FROM [WH_AllPublishers].[Derived].[Offer] o
	WHERE OfferGUID IS NOT NULL

	CREATE CLUSTERED INDEX CIX_OfferCode ON #Offer (OfferCode, OfferID, IronOfferID, PartnerID)
	

	IF OBJECT_ID('tempdb..#PANless_Transaction') IS NOT NULL DROP TABLE #PANless_Transaction;
	SELECT	SourceID = 2
		,	SourceTableID = pt.ID
		,	PublisherID = crt.PublisherID
		,	SubPublisherID = 0
		,	NotRewardManaged = 0
		,	RetailerID = pa.RetailerID
		,	PartnerID = pt.PartnerID
		,	OfferID = o.OfferID
		,	IronOfferID = o.IronOfferID
		,	OfferPercentage = pt.OfferRate
		,	CommissionRate = pt.CommissionRate
		,	OutletID = COALESCE(ro.RetailOutletID, -1)
		,	MerchantNumber = pt.MerchantNumber
		
		,	FanID = cu.FanID
		,	PanID = NULL
		,	MaskedCardNumber = pt.MaskedCardNumber
		
		,	Spend = pt.Price
		,	RetailerCashback = pt.CashbackEarned
		,	Investment = pt.NetAmount

		,	PublisherCommission =	CASE
										WHEN ISNULL(pd.Publisher, 0) <= 0 THEN 0
										ELSE pt2.PublisherCommission
									END
		,	RewardCommission =		CASE
										WHEN ISNULL(pd.Publisher, 0) <= 0 THEN pt2.Commission
										ELSE pt2.Commission - pt2.PublisherCommission
									END

		,	VATCommission = pt.VATAmount
		,	GrossCommission = pt.GrossAmount
		,	TranDate = pt.TransactionDate

		,	TranFixDate =	CASE
								WHEN pt.AddedDate <= pt2.CheckDate THEN pt.TransactionDate
								ELSE NULL
							END

		,	TranTime = CONVERT(TIME, pt.TransactionDate)
		,	IsNegative =	CASE
								WHEN pt.Price < 0 THEN 1
								ELSE 0
							END
		,	IsOnline = COALESCE(ro.IsOnline, 0)
		,	IsSpendStretch =	CASE
									WHEN o.SpendStretchAmount < pt.Price THEN 1
									WHEN o.SpendStretchAmount IS NULL THEN NULL
									ELSE 0
								END
		,	SpendStretchAmount = o.SpendStretchAmount

		,	IsRetailMonthly =	CASE
									WHEN pt.AddedDate <= pt2.CheckDate THEN CONVERT(BIT, 1)
									ELSE CONVERT(BIT, 0)
								END
		,	IsRetailerReport = CONVERT(BIT, 1)

		,	AddedDate = pt.AddedDate
	INTO #PANless_Transaction
	FROM [DIMAIN_TR].[SLC_REPL].[RAS].[PANless_Transaction] pt
	INNER JOIN #CRT_File crt
		ON pt.FileID = crt.FileID
	LEFT JOIN #Offer o
		ON pt.OfferCode = o.OfferCode
	LEFT JOIN #RetailOutlet ro
		ON pt.MerchantNumber = ro.MerchantID
		AND pt.PartnerID = ro.PartnerID
	LEFT JOIN [WH_AllPublishers].[Derived].[Partner] pa
		ON pt.PartnerID = pa.PartnerID
	LEFT JOIN [WH_AllPublishers].[Derived].[Customer] cu
		ON COALESCE(pt.CustomerId, CONVERT(VARCHAR(64),HashBytes('SHA2_256', pt.MaskedCardNumber), 2)) = cu.SourceUID
		AND crt.PublisherID = cu.PublisherID
	LEFT JOIN [Warehouse].[Relational].[nFI_Partner_Deals] pd
		ON pa.RetailerID = pd.PartnerID
		AND crt.PublisherID = pd.ClubID
		AND pt.TransactionDate BETWEEN pd.StartDate AND pd.EndDate
	CROSS APPLY (	SELECT	CheckDate = DATEADD(DAY, 15, EOMONTH(TransactionDate))
						,	Commission = CONVERT(DECIMAL(32,2), pt.NetAmount - pt.CashbackEarned)
						,	PublisherCommission = CONVERT(DECIMAL(32,2), ((CONVERT(DECIMAL(32,2), pt.NetAmount - pt.CashbackEarned)) * pd.Publisher / 100) / ((pd.Publisher / 100) + (pd.Reward / 100)))) pt2
	WHERE NOT EXISTS (	SELECT 1
						FROM [Derived].[SchemeTrans] st
						WHERE pt.ID = st.SourceTableID
						AND st.SourceID = 2)

	CREATE CLUSTERED INDEX CIX_SourceTableID ON #PANless_Transaction (SourceTableID)
		
	INSERT INTO #PANless_Transaction
	SELECT	SourceID = 2
		,	SourceTableID = pt.ID
		,	PublisherID = crt.PublisherID
		,	SubPublisherID = 0
		,	NotRewardManaged = 0
		,	RetailerID = pa.RetailerID
		,	PartnerID = pt.PartnerID
		,	OfferID = o.OfferID
		,	IronOfferID = o.IronOfferID
		,	OfferPercentage = pt.OfferRate
		,	CommissionRate = pt.CommissionRate
		,	OutletID = COALESCE(ro.RetailOutletID, -1)
		,	MerchantNumber = pt.MerchantNumber
		
		,	FanID = cu.FanID
		,	PanID = NULL
		,	MaskedCardNumber = pt.MaskedCardNumber
		
		,	Spend = pt.Price
		,	RetailerCashback = pt.CashbackEarned
		,	Investment = pt.NetAmount
		
		,	PublisherCommission =	CASE
										WHEN ISNULL(pd.Publisher, 0) <= 0 THEN 0
										ELSE pt2.PublisherCommission
									END
		,	RewardCommission =		CASE
										WHEN ISNULL(pd.Publisher, 0) <= 0 THEN pt2.Commission
										ELSE pt2.Commission - pt2.PublisherCommission
									END

		,	VATCommission = pt.VATAmount
		,	GrossCommission = pt.GrossAmount
		,	TranDate = pt.TransactionDate

		,	TranFixDate =	CASE
								WHEN pt.AddedDate <= pt2.CheckDate THEN pt.TransactionDate
								ELSE NULL
							END

		,	TranTime = CONVERT(TIME, pt.TransactionDate)
		,	IsNegative =	CASE
								WHEN pt.Price < 0 THEN 1
								ELSE 0
							END
		,	IsOnline = COALESCE(ro.IsOnline, 0)
		,	IsSpendStretch =	CASE
									WHEN o.SpendStretchAmount < pt.Price THEN 1
									WHEN o.SpendStretchAmount IS NULL THEN NULL
									ELSE 0
								END
		,	SpendStretchAmount = o.SpendStretchAmount
		
		,	IsRetailMonthly =	CASE
									WHEN pt.AddedDate <= pt2.CheckDate THEN CONVERT(BIT, 1)
									ELSE CONVERT(BIT, 0)
								END
		,	IsRetailerReport = CONVERT(BIT, 1)

		,	AddedDate = pt.AddedDate
	FROM [DIMAIN_TR].[SLC_REPL].[RAS].[PANless_Transaction] pt
	INNER JOIN #CRT_File crt
		ON pt.FileID = crt.FileID
	LEFT JOIN #Offer o
		ON pt.PublisherOfferCode = o.OfferCode
	LEFT JOIN #RetailOutlet ro
		ON pt.MerchantNumber = ro.MerchantID
		AND pt.PartnerID = ro.PartnerID
	LEFT JOIN [WH_AllPublishers].[Derived].[Partner] pa
		ON pt.PartnerID = pa.PartnerID
	LEFT JOIN [WH_AllPublishers].[Derived].[Customer] cu
		ON COALESCE(pt.CustomerId, CONVERT(VARCHAR(64),HashBytes('SHA2_256', pt.MaskedCardNumber), 2)) = cu.SourceUID
		AND crt.PublisherID = cu.PublisherID
	LEFT JOIN [Warehouse].[Relational].[nFI_Partner_Deals] pd
		ON pa.RetailerID = pd.PartnerID
		AND crt.PublisherID = pd.ClubID
		AND pt.TransactionDate BETWEEN pd.StartDate AND pd.EndDate
	CROSS APPLY (	SELECT	CheckDate = DATEADD(DAY, 15, EOMONTH(TransactionDate))
						,	Commission = CONVERT(DECIMAL(32,2), pt.NetAmount - pt.CashbackEarned)
						,	PublisherCommission = CONVERT(DECIMAL(32,2), ((CONVERT(DECIMAL(32,2), pt.NetAmount - pt.CashbackEarned)) * pd.Publisher / 100) / ((pd.Publisher / 100) + (pd.Reward / 100)))) pt2
	WHERE NOT EXISTS (	SELECT 1
						FROM #PANless_Transaction p
						WHERE pt.ID = p.SourceTableID)
	AND NOT EXISTS (	SELECT 1
						FROM [Derived].[SchemeTrans] st
						WHERE pt.ID = st.SourceTableID
						AND st.SourceID = 2)
		
	INSERT INTO #PANless_Transaction
	SELECT	SourceID = 2
		,	SourceTableID = pt.ID
		,	PublisherID = crt.PublisherID
		,	SubPublisherID = 0
		,	NotRewardManaged = 0
		,	RetailerID = pa.RetailerID
		,	PartnerID = pt.PartnerID
		,	OfferID = NULL
		,	IronOfferID = NULL
		,	OfferPercentage = pt.OfferRate
		,	CommissionRate = pt.CommissionRate
		,	OutletID = COALESCE(ro.RetailOutletID, -1)
		,	MerchantNumber = pt.MerchantNumber
		
		,	FanID = cu.FanID
		,	PanID = NULL
		,	MaskedCardNumber = pt.MaskedCardNumber
		
		,	Spend = pt.Price
		,	RetailerCashback = pt.CashbackEarned
		,	Investment = pt.NetAmount
		
		,	PublisherCommission =	CASE
										WHEN ISNULL(pd.Publisher, 0) <= 0 THEN 0
										ELSE pt2.PublisherCommission
									END
		,	RewardCommission =		CASE
										WHEN ISNULL(pd.Publisher, 0) <= 0 THEN pt2.Commission
										ELSE pt2.Commission - pt2.PublisherCommission
									END

		,	VATCommission = pt.VATAmount
		,	GrossCommission = pt.GrossAmount
		,	TranDate = pt.TransactionDate

		,	TranFixDate =	CASE
								WHEN pt.AddedDate <= pt2.CheckDate THEN pt.TransactionDate
								ELSE NULL
							END

		,	TranTime = CONVERT(TIME, pt.TransactionDate)
		,	IsNegative =	CASE
								WHEN pt.Price < 0 THEN 1
								ELSE 0
							END
		,	IsOnline = COALESCE(ro.IsOnline, 0)
		,	IsSpendStretch =	NULL
		,	SpendStretchAmount = NULL
		
		,	IsRetailMonthly =	CASE
									WHEN pt.AddedDate <= pt2.CheckDate THEN CONVERT(BIT, 1)
									ELSE CONVERT(BIT, 0)
								END
		,	IsRetailerReport = CONVERT(BIT, 1)

		,	AddedDate = pt.AddedDate
	FROM [DIMAIN_TR].[SLC_REPL].[RAS].[PANless_Transaction] pt
	INNER JOIN #CRT_File crt
		ON pt.FileID = crt.FileID
	LEFT JOIN #RetailOutlet ro
		ON pt.MerchantNumber = ro.MerchantID
		AND pt.PartnerID = ro.PartnerID
	LEFT JOIN [WH_AllPublishers].[Derived].[Partner] pa
		ON pt.PartnerID = pa.PartnerID
	LEFT JOIN [WH_AllPublishers].[Derived].[Customer] cu
		ON COALESCE(pt.CustomerId, CONVERT(VARCHAR(64),HashBytes('SHA2_256', pt.MaskedCardNumber), 2)) = cu.SourceUID
		AND crt.PublisherID = cu.PublisherID
	LEFT JOIN [Warehouse].[Relational].[nFI_Partner_Deals] pd
		ON pa.RetailerID = pd.PartnerID
		AND crt.PublisherID = pd.ClubID
		AND pt.TransactionDate BETWEEN pd.StartDate AND pd.EndDate
	CROSS APPLY (	SELECT	CheckDate = DATEADD(DAY, 15, EOMONTH(TransactionDate))
						,	Commission = CONVERT(DECIMAL(32,2), pt.NetAmount - pt.CashbackEarned)
						,	PublisherCommission = CONVERT(DECIMAL(32,2), ((CONVERT(DECIMAL(32,2), pt.NetAmount - pt.CashbackEarned)) * pd.Publisher / 100) / ((pd.Publisher / 100) + (pd.Reward / 100)))) pt2
	WHERE NOT EXISTS (	SELECT 1
						FROM #PANless_Transaction p
						WHERE pt.ID = p.SourceTableID)
	AND NOT EXISTS (	SELECT 1
						FROM [Derived].[SchemeTrans] st
						WHERE pt.ID = st.SourceTableID
						AND st.SourceID = 2)
	
	--	Offer

		--	PartnerID

			UPDATE pt
			SET pt.IronOfferID = o.IronOfferID
			,	pt.OfferID = o.OfferID
			FROM #PANless_Transaction pt
			INNER JOIN [Derived].[Offer] o
				ON pt.PublisherID = o.PublisherID
				AND pt.PartnerID = o.PartnerID
				AND pt.OfferPercentage = o.BaseCashBackRate
				AND CONVERT(DATE, pt.TranDate) BETWEEN CONVERT(DATE, o.StartDate) AND CONVERT(DATE, o.EndDate)
			WHERE pt.IronOfferID IS NULL
	
			UPDATE pt
			SET pt.IronOfferID = o.IronOfferID
			,	pt.OfferID = o.OfferID
			FROM #PANless_Transaction pt
			INNER JOIN [Derived].[Partner] pa
				ON pt.PartnerID = pa.RetailerID
			INNER JOIN [Derived].[Offer] o
				ON pt.PublisherID = o.PublisherID
				AND pa.PartnerID = o.PartnerID
				AND pt.OfferPercentage = o.BaseCashBackRate
				AND CONVERT(DATE, pt.TranDate) BETWEEN CONVERT(DATE, o.StartDate) AND CONVERT(DATE, o.EndDate)
			WHERE pt.IronOfferID IS NULL
	
			UPDATE pt
			SET pt.IronOfferID = o.IronOfferID
			,	pt.OfferID = o.OfferID
			FROM #PANless_Transaction pt
			INNER JOIN [Derived].[Offer] o
				ON pt.PublisherID = o.PublisherID
				AND pt.PartnerID = o.PartnerID
				AND pt.OfferPercentage = o.TopCashBackRate
				AND CONVERT(DATE, pt.TranDate) BETWEEN CONVERT(DATE, o.StartDate) AND CONVERT(DATE, o.EndDate)
			WHERE pt.IronOfferID IS NULL
	
			UPDATE pt
			SET pt.IronOfferID = o.IronOfferID
			,	pt.OfferID = o.OfferID
			FROM #PANless_Transaction pt
			INNER JOIN [Derived].[Partner] pa
				ON pt.PartnerID = pa.RetailerID
			INNER JOIN [Derived].[Offer] o
				ON pt.PublisherID = o.PublisherID
				AND pa.PartnerID = o.PartnerID
				AND pt.OfferPercentage = o.TopCashBackRate
				AND CONVERT(DATE, pt.TranDate) BETWEEN CONVERT(DATE, o.StartDate) AND CONVERT(DATE, o.EndDate)
			WHERE pt.IronOfferID IS NULL

		--	RetailerID

			UPDATE pt
			SET pt.IronOfferID = o.IronOfferID
			,	pt.OfferID = o.OfferID
			FROM #PANless_Transaction pt
			INNER JOIN [Derived].[Offer] o
				ON pt.PublisherID = o.PublisherID
				AND pt.RetailerID = o.RetailerID
				AND pt.OfferPercentage = o.BaseCashBackRate
				AND CONVERT(DATE, pt.TranDate) BETWEEN CONVERT(DATE, o.StartDate) AND CONVERT(DATE, o.EndDate)
			WHERE pt.IronOfferID IS NULL
	
			UPDATE pt
			SET pt.IronOfferID = o.IronOfferID
			,	pt.OfferID = o.OfferID
			FROM #PANless_Transaction pt
			INNER JOIN [Derived].[Partner] pa
				ON pt.PartnerID = pa.RetailerID
			INNER JOIN [Derived].[Offer] o
				ON pt.PublisherID = o.PublisherID
				AND pa.RetailerID = o.RetailerID
				AND pt.OfferPercentage = o.BaseCashBackRate
				AND CONVERT(DATE, pt.TranDate) BETWEEN CONVERT(DATE, o.StartDate) AND CONVERT(DATE, o.EndDate)
			WHERE pt.IronOfferID IS NULL
	
			UPDATE pt
			SET pt.IronOfferID = o.IronOfferID
			,	pt.OfferID = o.OfferID
			FROM #PANless_Transaction pt
			INNER JOIN [Derived].[Offer] o
				ON pt.PublisherID = o.PublisherID
				AND pt.RetailerID = o.RetailerID
				AND pt.OfferPercentage = o.TopCashBackRate
				AND CONVERT(DATE, pt.TranDate) BETWEEN CONVERT(DATE, o.StartDate) AND CONVERT(DATE, o.EndDate)
			WHERE pt.IronOfferID IS NULL
	
			UPDATE pt
			SET pt.IronOfferID = o.IronOfferID
			,	pt.OfferID = o.OfferID
			FROM #PANless_Transaction pt
			INNER JOIN [Derived].[Partner] pa
				ON pt.PartnerID = pa.RetailerID
			INNER JOIN [Derived].[Offer] o
				ON pt.PublisherID = o.PublisherID
				AND pa.RetailerID = o.RetailerID
				AND pt.OfferPercentage = o.TopCashBackRate
				AND CONVERT(DATE, pt.TranDate) BETWEEN CONVERT(DATE, o.StartDate) AND CONVERT(DATE, o.EndDate)
			WHERE pt.IronOfferID IS NULL

	--	OutletID

		--	PartnerID

			UPDATE pt
			SET pt.OutletID = ro.RetailOutletID
			FROM #PANless_Transaction pt
			INNER JOIN #RetailOutlet ro
				ON pt.MerchantNumber = ro.MerchantID
				AND pt.PartnerID = ro.PartnerID
			WHERE pt.OutletID = -1
	
			UPDATE pt
			SET pt.OutletID = ro.RetailOutletID
			FROM #PANless_Transaction pt
			INNER JOIN [Derived].[Partner] pa
				ON pt.PartnerID = pa.RetailerID
			INNER JOIN #RetailOutlet ro
				ON pt.MerchantNumber = ro.MerchantID
				AND pa.PartnerID = ro.PartnerID
			WHERE pt.OutletID = -1
	
			UPDATE pt
			SET pt.OutletID = ro.RetailOutletID
			FROM #PANless_Transaction pt
			INNER JOIN #RetailOutlet ro
				ON pt.MerchantNumber LIKE '%' + ro.MerchantID
				AND pt.PartnerID = ro.PartnerID
			WHERE pt.OutletID = -1
	
			UPDATE pt
			SET pt.OutletID = ro.RetailOutletID
			FROM #PANless_Transaction pt
			INNER JOIN [Derived].[Partner] pa
				ON pt.PartnerID = pa.RetailerID
			INNER JOIN #RetailOutlet ro
				ON pt.MerchantNumber LIKE '%' + ro.MerchantID
				AND pa.PartnerID = ro.PartnerID
			WHERE pt.OutletID = -1
	
			UPDATE pt
			SET pt.OutletID = ro.RetailOutletID
			FROM #PANless_Transaction pt
			INNER JOIN #RetailOutlet ro
				ON ro.MerchantID LIKE '%' + pt.MerchantNumber
				AND pt.PartnerID = ro.PartnerID
			WHERE pt.OutletID = -1

		--	MerchantNumber
	
			UPDATE pt
			SET pt.OutletID = ro.RetailOutletID
			FROM #PANless_Transaction pt
			INNER JOIN #RetailOutlet ro
				ON ro.MerchantID = pt.MerchantNumber
			WHERE pt.OutletID = -1
			AND pt.MerchantNumber != ''
	
			UPDATE pt
			SET pt.OutletID = ro.RetailOutletID
			FROM #PANless_Transaction pt
			INNER JOIN #RetailOutlet ro
				ON ro.MerchantID LIKE '%' + pt.MerchantNumber
			WHERE pt.OutletID = -1
			AND pt.MerchantNumber != ''


	INSERT INTO [Derived].[SchemeTrans]	(	[SourceID]
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
			SourceID = pt.SourceID
		,	SourceTableID = pt.SourceTableID
		,	PublisherID = pt.PublisherID
		,	SubPublisherID = pt.SubPublisherID
		,	NotRewardManaged = pt.NotRewardManaged
		,	RetailerID = pt.RetailerID
		,	PartnerID = pt.PartnerID
		,	OfferID = pt.OfferID
		,	IronOfferID = pt.IronOfferID
		,	OfferPercentage = pt.OfferPercentage
		,	CommissionRate = pt.CommissionRate
		,	OutletID = pt.OutletID
	--	,	MerchantNumber = pt.MerchantNumber
		
		,	FanID = pt.FanID
		,	PanID = pt.PanID
		,	MaskedCardNumber = pt.MaskedCardNumber
		
		,	Spend = pt.Spend
		,	RetailerCashback = pt.RetailerCashback
		,	Investment = pt.Investment
		
		,	PublisherCommission = pt.PublisherCommission
		,	RewardCommission = pt.RewardCommission

		,	VATCommission = pt.VATCommission
		,	GrossCommission = pt.GrossCommission
		,	TranDate = pt.TranDate

		,	TranFixDate = pt.TranFixDate

		,	TranTime = pt.TranTime
		,	IsNegative = pt.IsNegative
		,	IsOnline = pt.IsOnline
		,	IsSpendStretch = pt.IsSpendStretch
		,	SpendStretchAmount = pt.SpendStretchAmount
		
		,	IsRetailMonthly = pt.IsRetailMonthly
		,	IsRetailerReport = pt.IsRetailerReport

		,	AddedDate = pt.AddedDate
	FROM #PANless_Transaction pt
	WHERE pt.FanID IS NOT NULL
	AND pt.OfferID IS NOT NULL
	AND pt.OutletID != -1

	/*

	SELECT	pub.PublisherID
		,	pub.PublisherName
		,	TotalTrans = COUNT(*)
		,	ValidTrans = COUNT(CASE WHEN pt.FanID IS NOT NULL AND pt.OfferID IS NOT NULL AND pt.OutletID != -1 THEN 1 END)
		,	NoFan = COUNT(CASE WHEN pt.FanID IS NULL THEN 1 END)
		,	NoOffer = COUNT(CASE WHEN pt.OfferID IS NULL THEN 1 END)
		,	NoOutlet = COUNT(CASE WHEN pt.OutletID = -1 THEN 1 END)

		
		,	MaxDateNoFan = MAX(CASE WHEN pt.FanID IS NULL THEN TranDate END)
		,	MaxDateNoOffer = MAX(CASE WHEN pt.OfferID IS NULL THEN TranDate END)
		,	MaxDateNoOutlet = MAX(CASE WHEN pt.OutletID = -1 THEN TranDate END)
	FROM #PANless_Transaction pt
	INNER JOIN [WH_AllPublishers].[Derived].[Publisher] pub
		ON pt.PublisherID = pub.PublisherID
	GROUP BY	pub.PublisherID
			,	pub.PublisherName
	ORDER BY	pub.PublisherName

	*/
	

END