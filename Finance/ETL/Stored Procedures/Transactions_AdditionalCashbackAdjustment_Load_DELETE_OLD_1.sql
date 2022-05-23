
CREATE PROCEDURE [ETL].[Transactions_AdditionalCashbackAdjustment_Load_DELETE_OLD]
AS
BEGIN

	 SET NOCOUNT ON
	 SET XACT_ABORT ON

	----------------------------------------------------------------------
	-- Checkpoint Variables
	----------------------------------------------------------------------
	DECLARE @CheckpointTypeID INT = 1
		, @StoredProcName VARCHAR(100) = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)
	DECLARE @CheckpointValue INT = ETL.getTableCheckpoint(@CheckpointTypeID, @StoredProcName, 1, 0)

	----------------------------------------------------------------------
	-- System Variables
	----------------------------------------------------------------------
	DECLARE @RunDateTime DATETIME2 = GETDATE()
		, @SourceTypeID INT = 3

	EXEC ETL.SourceType_CheckID @SourceTypeID, 'AdditionalCashbackAdjustment'

	/**********************************************************************
	Build base tables
		TODO: Turn #EarnBurnType into Permanent table
	***********************************************************************/

	if object_id('tempdb..#AdditionalCashbackAdjustmentType') is not null 
		drop table #AdditionalCashbackAdjustmentType
	Select	aca.*
		,	tt.Multiplier
	Into #AdditionalCashbackAdjustmentType
	From Warehouse.Relational.AdditionalCashbackAdjustmentType as aca
	inner join SLC_Report.dbo.TransactionType as tt with (Nolock)
		on aca.TypeID = tt.ID

	----------------------------------------------------------------------
	----------------------------------------------------------------------

	if object_id('tempdb..#Customer') is not null 
		drop table #Customer
	Select FanID
	Into #Customer
	From Warehouse.Relational.Customer

	Create Clustered Index ix_Customer_FanID on #Customer (FanID)

	----------------------------------------------------------------------
	----------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#EarnBurnType') IS NOT NULL
		DROP TABLE #EarnBurnType

	SELECT
		x.*, act.AdditionalCashbackAdjustmentCategoryID
	INTO #EarnBurnType
	-- Make perm table
	FROM (
		VALUES
			-- Amazon
			('Amazon', 7236, 26, 77) 
			, ('Amazon', 7238, 26, 78)
			, ('Amazon', 7240, 26, 79)
			, ('Amazon', 7236, 27, 80)
			, ('Amazon', 7238, 27, 81)
			, ('Amazon', 7240, 27, 82)
		
			-- M&S
			, ('M&S', 7242, 26, 83)
			, ('M&S', 7243, 26, 84)
			, ('M&S', 7244, 26, 85)
			, ('M&S', 7242, 27, 86)
			, ('M&S', 7243, 27, 87)
			, ('M&S', 7244, 27, 88)
		 
			, ('M&S', 7274, 26, 152)
			, ('M&S', 7274, 27, 155)
			, ('M&S', 7275, 26, 151)
			, ('M&S', 7275, 27, 154)
			, ('M&S', 7276, 26, 150)
			, ('M&S', 7276, 27, 153)
		 
			-- B&Q
			, ('B&Q', 7248, 26, 95)
			, ('B&Q', 7249, 26, 96)
			, ('B&Q', 7250, 26, 97)
			, ('B&Q', 7248, 27, 98)
			, ('B&Q', 7249, 27, 99)
			, ('B&Q', 7250, 27, 100)
		 
			, ('B&Q', 7279, 26, 144)
			, ('B&Q', 7279, 27, 147)
			, ('B&Q', 7277, 26, 146)
			, ('B&Q', 7277, 27, 149)
			, ('B&Q', 7278, 26, 145)
			, ('B&Q', 7278, 27, 148)
		 
			-- Argos
			, ('Argos', 7256, 26, 101)
			, ('Argos', 7257, 26, 102)
			, ('Argos', 7258, 26, 103)
			, ('Argos', 7256, 27, 104)
			, ('Argos', 7257, 27, 105)
			, ('Argos', 7258, 27, 106)
		
			-- John Lewis
			, ('John Lewis', 7260, 26, 107)
			, ('John Lewis', 7261, 26, 108)
			, ('John Lewis', 7262, 26, 109)
			, ('John Lewis', 7260, 27, 110)
			, ('John Lewis', 7261, 27, 111)
			, ('John Lewis', 7262, 27, 112)
		
			-- Greggs
			, ('Greggs',7264, 26, 114)
			, ('Greggs',7265, 26, 115)
			, ('Greggs',7266, 26, 116)
			, ('Greggs',7264, 27, 117)
			, ('Greggs',7265, 27, 118)
			, ('Greggs',7266, 27, 119)
		
			-- Morrisons
			, ('Morrisons',7268, 26, 126)
			, ('Morrisons',7269, 26, 127)
			, ('Morrisons',7270, 26, 128)
			, ('Morrisons',7268, 27, 129)
			, ('Morrisons',7269, 27, 130)
			, ('Morrisons',7270, 27, 131)
		
			--	Nero
			, ('Nero',7283, 26, 140)
			, ('Nero',7283, 27, 143)
			, ('Nero',7284, 26, 139)
			, ('Nero',7284, 27, 142)
			, ('Nero',7285, 26, 138)
			, ('Nero',7285, 27, 141)
		
			--	Curry's
			, ('Currys',7271, 26, 158)
			, ('Currys',7271, 27, 161)
			, ('Currys',7273, 26, 156)
			, ('Currys',7273, 27, 159)
			, ('Currys',7272, 26, 157)
			, ('Currys',7272, 27, 160)
		
			--	TK Maxx
			, ('TK Maxx',7280, 26, 134)
			, ('TK Maxx',7280, 27, 137)
			, ('TK Maxx',7282, 26, 132)
			, ('TK Maxx',7282, 27, 135)
			, ('TK Maxx',7281, 26, 133)
			, ('TK Maxx',7281, 27, 136)
	) x(RetailerName, ItemID, TypeID, AdditionalCashbackAdjustmentTypeID)
	JOIN Warehouse.Relational.AdditionalCashbackAdjustmentType act
		ON x.AdditionalCashbackAdjustmentTypeID = act.AdditionalCashbackAdjustmentTypeID
	
	CREATE UNIQUE CLUSTERED INDEX UCIX_Tempdb_EarnBurnType ON #EarnBurnType (ItemID, TypeID)

	----------------------------------------------------------------------
	-- LOAD Staging Table
	----------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#AdditionalCashbackAdjustment') IS NOT NULL
		DROP TABLE #AdditionalCashbackAdjustment

	CREATE TABLE #AdditionalCashbackAdjustment
	(
		FanID INT NOT NULL,
		IronOfferID INT NOT NULL,
		PartnerID INT NOT NULL,
		ClubID INT NOT NULL,
		Spend SMALLMONEY,
		Earnings SMALLMONEY,
		TranDate DATE NOT NULL,
		TransactionTypeID SMALLINT NULL,
		AdditionalCashbackAwardTypeID SMALLINT NOT NULL,
		AdditionalCashbackAdjustmentTypeID SMALLINT NOT NULL,
		AdditionalCashbackAdjustmentCategoryID SMALLINT NOT NULL,
		PaymentMethodID SMALLINT NOT NULL,
		DirectDebitOriginatorID INT,
		SourceAddedDate DATE,
		SourceID INT NOT NULL,
		SourceTypeID INT NOT NULL,
		SourceSystemID INT NOT NULL,
		CreatedDateTime DATETIME2 NOT NULL,
		ItemID INT NULL,
		TypeID INT NULL,
		ActivationDays INT

	)
	
	INSERT INTO #AdditionalCashbackAdjustment
	(
		FanID
		, IronOfferID
		, PartnerID
		, ClubID
		, Spend
		, Earnings
		, TranDate
		, TransactionTypeID
		, AdditionalCashbackAwardTypeID
		, AdditionalCashbackAdjustmentTypeID
		, AdditionalCashbackAdjustmentCategoryID
		, PaymentMethodID
		, DirectDebitOriginatorID
		, SourceAddedDate
		, SourceID
		, SourceTypeID
		, SourceSystemID
		, CreatedDateTime
		, ActivationDays
	)
	Select	--top 1
		tr.FanID
		, -1 AS IronOfferID
		, -1 AS PartnerID
		, 132 AS ClubID
		, NULL AS Spend
		, tr.ClubCash * aca.Multiplier AS Earnings
		, tr.Date AS TranDate
		, tr.TypeID AS TransactionTypeID
		, -1 AS AdditionalCashbackAwardTypeID
		, aca.AdditionalCashbackAdjustmentTypeID
		, aca.AdditionalCashbackAdjustmentCategoryID
		, -1 AS PaymentMethodID
		, DirectDebitOriginatorID
		, tr.ProcessDate AS SourceAddedDate
		, tr.ID AS SourceID
		, @SourceTypeID AS SourceTypeID
		, 1 AS SourceSystemID
		, @RunDateTime AS CreatedDateTime
		, ActivationDays
	FROM SLC_Report.[dbo].[Trans] tr
	INNER JOIN #AdditionalCashbackAdjustmentType aca -- Insert excludes Burn As You Earn, as these have an ItemID of 0 in the Warehouse.Relational.AdditionalCashbackAdjustmentType table
		on tr.ItemID = aca.ItemID
		and tr.TypeID = aca.TypeID
	WHERE EXISTS (	SELECT 1
					FROM #Customer as c
					WHERE tr.FanID = c.FanID)
			AND tr.ID > @CheckpointValue

	/**********************************************************************
	BURN AS YOUR EARN OFFERS
	***********************************************************************/	
	if object_id('tempdb..#Trans') is not null drop table #Trans
	SELECT	--top 1 
		t.FanID,
			t.Date,
			t.ProcessDate AS AddedDate,
			t.TypeiD,
			t.ClubCash* tt.Multiplier	as CashbackEarned,
			t.ActivationDays,
			t.ItemID,
			t.ID AS TranID,
			t.DirectDebitOriginatorID
	Into #Trans
	From SLC_Report.dbo.Trans as t with (Nolock)
	inner join SLC_Report.dbo.TransactionType as tt with (Nolock)
		on t.TypeID = tt.ID		
	WHERE EXISTS (	SELECT 1
					FROM #Customer as c
					WHERE t.FanID = c.FanID)
		AND TypeID in (26,27)
		AND t.ID > @CheckpointValue

	Create Clustered Index i_Trans_ItemID on #Trans (ItemID)

	----------------------------------------------------------------------
	-- LOAD Staging table
	----------------------------------------------------------------------

	INSERT INTO #AdditionalCashbackAdjustment
	(
		FanID
		, IronOfferID
		, PartnerID
		, ClubID
		, Spend
		, Earnings
		, TranDate
		, TransactionTypeID
		, AdditionalCashbackAwardTypeID
		, AdditionalCashbackAdjustmentTypeID
		, AdditionalCashbackAdjustmentCategoryID
		, PaymentMethodID
		, DirectDebitOriginatorID
		, SourceAddedDate
		, SourceID
		, SourceTypeID
		, SourceSystemID
		, CreatedDateTime
		, ItemID
		, ActivationDays
	)
	SELECT
		a.FanID
		, -1 AS IronOfferID
		, -1 AS PartnerID
		, 132 AS ClubID
		, NULL AS Spend
		, a.CashbackEarned AS Earnings
		, a.Date AS TranDate
		, a.TypeID AS TransactionTypeID
		, -1 AS AdditionalCashbackAwardTypeID
		, COALESCE(ebt.AdditionalCashbackAdjustmentTypeID, -2) AS AdditionalCashbackAdjustmentTypeID -- -2's become errors 
		, COALESCE(ebt.AdditionalCashbackAdjustmentCategoryID, -2) AS AdditionalCashbackAdjustmentCategoryID
		, -1 AS PaymentMethodID
		, a.DirectDebitOriginatorID
		, a.AddedDate AS SourceAddedDate
		, a.TranID AS SourceID
		, @SourceTypeID AS SourceTypeID
		, 1 AS SourceSystemID
		, @RunDateTime AS CreatedDateTime
		, b.ItemID
		, a.ActivationDays
	From #Trans as a
	inner join SLC_Report.dbo.Trans as b with (Nolock)
		on a.ItemID = b.ID
	LEFT JOIN #EarnBurnType ebt
		ON b.ItemID = ebt.ItemID
		AND a.TypeID = ebt.TypeID

	/**********************************************************************
	LOAD INTO Main Table and update checkpoint
	***********************************************************************/
	BEGIN TRAN

		INSERT INTO dbo.Transactions
		(
			FanID
			, IronOfferID
			, PartnerID
			, PublisherID
			, Spend
			, Earnings
			, TranDate
			, TransactionTypeID
			, AdditionalCashbackAwardTypeID
			, AdditionalCashbackAdjustmentTypeID
			, AdditionalCashbackAdjustmentCategoryID
			, PaymentMethodID
			, DirectDebitOriginatorID
			, SourceAddedDate
			, SourceID
			, SourceTypeID
			, SourceSystemID
			, CreatedDateTime
			, EarningSourceID
			, ActivationDays
		)
		SELECT
			te.FanID
			, te.IronOfferID
			, te.PartnerID
			, te.ClubID
			, te.Spend
			, te.Earnings
			, te.TranDate
			, te.TransactionTypeID
			, te.AdditionalCashbackAwardTypeID
			, te.AdditionalCashbackAdjustmentTypeID
			, te.AdditionalCashbackAdjustmentCategoryID
			, te.PaymentMethodID
			, te.DirectDebitOriginatorID
			, te.SourceAddedDate
			, te.SourceID
			, te.SourceTypeID
			, te.SourceSystemID
			, te.CreatedDateTime
			, cs.EarningSourceID
			, te.ActivationDays
		FROM #AdditionalCashbackAdjustment te
		LEFT JOIN dbo.PartnerAlternate pa
			ON te.PartnerID = pa.AlternatePartnerID
		LEFT JOIN dbo.DirectDebitOriginator do
			ON te.DirectDebitOriginatorID = do.DirectDebitOriginatorID
		LEFT JOIN dbo.EarningSource cs 
			ON COALESCE(pa.PartnerID, te.PartnerID) = cs.PartnerID
			AND te.AdditionalCashbackAdjustmentTypeID = cs.AdditionalCashbackAdjustmentTypeID
			AND te.AdditionalCashbackAwardTypeID = cs.AdditionalCashbackAwardTypeID
			AND te.AdditionalCashbackAdjustmentCategoryID = cs.AdditionalCashbackAdjustmentCategoryID
			AND COALESCE(do.Category2, '') = cs.DDCategory
		WHERE (te.AdditionalCashbackAdjustmentTypeID <> -2
			AND te.AdditionalCashbackAdjustmentCategoryID <> -2)


		INSERT INTO ETL.Missing_Transactions
		(
			FanID
			, IronOfferID
			, PartnerID
			, PublisherID
			, Spend
			, Earnings
			, TranDate
			, TransactionTypeID
			, AdditionalCashbackAwardTypeID
			, AdditionalCashbackAdjustmentTypeID
			, AdditionalCashbackAdjustmentCategoryID
			, PaymentMethodID
			, DirectDebitOriginatorID
			, SourceAddedDate
			, SourceID
			, SourceTypeID
			, SourceSystemID
			, CreatedDateTime
			, ItemID
			, EarningSourceID
			, ActivationDays
		) 
		SELECT
			FanID
			, te.IronOfferID
			, te.PartnerID
			, te.ClubID
			, te.Spend
			, te.Earnings
			, te.TranDate
			, te.TransactionTypeID
			, te.AdditionalCashbackAwardTypeID
			, te.AdditionalCashbackAdjustmentTypeID
			, te.AdditionalCashbackAdjustmentCategoryID
			, te.PaymentMethodID
			, te.DirectDebitOriginatorID
			, te.SourceAddedDate
			, te.SourceID
			, te.SourceTypeID
			, te.SourceSystemID
			, te.CreatedDateTime
			, te.ItemID
			, cs.EarningSourceID
			, te.ActivationDays
		FROM #AdditionalCashbackAdjustment te
		LEFT JOIN dbo.PartnerAlternate pa
			ON te.PartnerID = pa.AlternatePartnerID
		LEFT JOIN dbo.DirectDebitOriginator do
			ON te.DirectDebitOriginatorID = do.DirectDebitOriginatorID
		LEFT JOIN dbo.EarningSource cs 
			ON COALESCE(pa.PartnerID, te.PartnerID) = cs.PartnerID
			AND te.AdditionalCashbackAdjustmentTypeID = cs.AdditionalCashbackAdjustmentTypeID
			AND te.AdditionalCashbackAwardTypeID = cs.AdditionalCashbackAwardTypeID
			AND te.AdditionalCashbackAdjustmentCategoryID = cs.AdditionalCashbackAdjustmentCategoryID
			AND COALESCE(do.Category2, '') = cs.DDCategory
		WHERE NOT (te.AdditionalCashbackAdjustmentTypeID <> -2
			AND te.AdditionalCashbackAdjustmentCategoryID <> -2)

		INSERT INTO Finance.ETL.TableCheckpoint
		(
			CheckpointTypeID
			, CheckpointValue1
		)
		SELECT
			@CheckpointTypeID
			, MAX(SourceID)
		FROM #AdditionalCashbackAdjustment

	COMMIT TRAN

END




