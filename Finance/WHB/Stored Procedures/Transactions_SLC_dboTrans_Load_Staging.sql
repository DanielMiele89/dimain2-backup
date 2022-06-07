
CREATE PROCEDURE [WHB].[Transactions_SLC_dboTrans_Load_Staging]
		@RunID INT = NULL,
		@initialLoad BIT = 0
AS
BEGIN
	 SET NOCOUNT ON;
	 SET XACT_ABORT ON;

	----------------------------------------------------------------------
	-- System Variables
	----------------------------------------------------------------------
	DECLARE @RunDateTime DATETIME2(7) = GETDATE()
		, @StoredProcedureName VARCHAR(100)
		, @SourceTypeID INT
		, @SourceSystemID INT
		, @SourceTable VARCHAR(100)
		, @CheckpointValue DATETIME
		, @CheckpointValue2 INT

	SET @StoredProcedureName = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

	EXEC WHB.Get_SourceTypeID 
		@StoredProcedureName
		, @SourceTypeID OUTPUT
		, @SourceSystemID OUTPUT
		, @SourceTable OUTPUT

	IF @RunID IS NULL
		SET @RunID = NEXT VALUE FOR WHB.RunID

	DECLARE @CheckpointTable VARCHAR(30) = 'SLC.dboTrans_Changes'
		, @CheckpointTable2 VARCHAR(30) = 'SLC.dboTrans'

	EXEC WHB.Get_TableCheckpoint @CheckpointTable, 1, 'DATETIME', @CheckpointValue OUTPUT
	EXEC WHB.Get_TableCheckpoint @CheckpointTable2, 1, 'INT', @CheckpointValue2 OUTPUT

	IF @initialLoad = 0
	BEGIN
		IF @CheckpointValue IS NULL
		BEGIN
			SET @CheckpointValue = '1900-01-02'
		END
	END
	ELSE
	BEGIN
		IF @CheckpointValue2 IS NULL
		BEGIN
			SET @CheckpointValue2 = 0
		END
	END

	SET @CheckpointValue = DATEADD(DAY, -1, @CheckpointValue)

	DECLARE @SourceSystemID_Finance INT = (SELECT SourceSystemID FROM dbo.SourceSystem WHERE SourceSystemName = 'Finance')

	DECLARE @SourceTypeID_SLCPoints INT				= (SELECT SourceTypeID FROM dbo.SourceType WHERE SourceSystemID = @SourceSystemID AND SourceTable = 'dbo.SLCPoints')
		, @SourceTypeID_SLCPointsNegative INT		= (SELECT SourceTypeID FROM dbo.SourceType WHERE SourceSystemID = @SourceSystemID AND SourceTable = 'dbo.SLCPointsNegative')
		, @SourceTypeID_DirectDebitOriginator INT	= (SELECT SourceTypeID FROM dbo.SourceType WHERE SourceSystemID = @SourceSystemID AND SourceTable = 'dbo.DirectDebitOriginator')
		, @SourceTypeID_Partner INT					= (SELECT SourceTypeID FROM dbo.SourceType WHERE SourceSystemID = @SourceSystemID_Finance AND SourceTable = 'dbo.Partner')
		, @SourceTypeID_RedeemSupplier INT			= (SELECT SourceTypeID FROM dbo.SourceType WHERE SourceSystemID = @SourceSystemID AND SourceTable = 'dbo.RedeemSupplier')
		, @SourceTypeID_TransactionType INT			= (SELECT SourceTypeID FROM dbo.SourceType WHERE SourceSystemID = @SourceSystemID AND SourceTable = 'dbo.TransactionType')

	IF @SourceTypeID_SLCPoints			
		+ @SourceTypeID_SLCPointsNegative	
		+ @SourceTypeID_DirectDebitOriginator
		+ @SourceTypeID_Partner	
		+ @SourceTypeID_RedeemSupplier		
		+ @SourceTypeID_TransactionType IS NULL
	BEGIN

		DECLARE @Err VARCHAR(MAX) = 'Missing SourceTypeID -- The following are the SourceTypeIDs passed in:
		' + CONCAT(
				'@SourceTypeID_SLCPoints :', @SourceTypeID_SLCPoints, '
				',	
				'@SourceTypeID_SLCPointsNegative :', @SourceTypeID_SLCPointsNegative, '
				',	
				'@SourceTypeID_DirectDebitOriginator :', @SourceTypeID_DirectDebitOriginator, '
				',
				'@SourceTypeID_Partner :', @SourceTypeID_Partner, '
				',	
				'@SourceTypeID_RedeemSupplier :', @SourceTypeID_RedeemSupplier, '
				',		
				'@SourceTypeID_TransactionType :', @SourceTypeID_TransactionType
			)


		;THROW 100000, @Err, 1	
	END


	ALTER TABLE Staging.Transactions NOCHECK CONSTRAINT ALL;
	/**********************************************************************
	Build Dimensions that do not rely on the transaction set
	***********************************************************************/

		----------------------------------------------------------------------
		-- Earning Source
		----------------------------------------------------------------------
		IF OBJECT_ID('tempdb..#EarningSource') IS NOT NULL
			DROP TABLE #EarningSource

		SELECT
			EarningSourceID
			, CAST(SourceID AS INT) AS SourceID
			, SourceTypeID
		INTO #EarningSource
		FROM dbo.EarningSource
		WHERE SourceTypeID IN (
			@SourceTypeID_SLCPoints
			, @SourceTypeID_SLCPointsNegative
			, @SourceTypeID_DirectDebitOriginator
			, @SourceTypeID_Partner
			, @SourceTypeID_RedeemSupplier
			, @SourceTypeID_TransactionType
		)

		CREATE CLUSTERED INDEX CIX ON #EarningSource (EarningSourceID)

		----------------------------------------------------------------------
		-- Customers
		----------------------------------------------------------------------
		DROP TABLE IF EXISTS #Customer

		CREATE TABLE #Customer
		(
			SourceID INT
			, PublisherID SMALLINT
			, CustomerID INT
		)

		CREATE UNIQUE CLUSTERED INDEX UCIX ON #Customer (SourceID)

		INSERT INTO #Customer
		(
			SourceID
			, PublisherID
			, CustomerID
		)
		SELECT
			TRY_CAST(c.SourceID AS INT) SourceID
			, c.PublisherID
			, c.CustomerID
		FROM dbo.Customer c
		JOIN dbo.SourceType st
			ON c.SourceTypeID = st.SourceTypeID
			AND st.SourceSystemID = @SourceSystemID

		----------------------------------------------------------------------
		-- Build DD Table to get IronOfferIDs for applicable DDs
		----------------------------------------------------------------------
		-- IF OBJECT_ID('tempdb..#DDSuppliers') IS NOT NULL DROP TABLE #DDSuppliers;
		-- SELECT DISTINCT
		-- 	o.ID AS DirectDebitOriginatorID
		-- 	, oin.IronOfferID
		-- INTO #DDSuppliers
		-- FROM SLC_REPL.dbo.DirectDebitOfferOINs oin -- Repoint to Warehouse.Relational.DirectDebit_MFDD_IncentivisedOINs if OINs start starting/ending whilst offers are active
		-- INNER JOIN SLC_REPL.dbo.DirectDebitOriginator o 
		-- 	ON oin.OIN = o.OIN

		-- CREATE CLUSTERED INDEX UCIX ON #DDSuppliers (DirectDebitOriginatorID)

		----------------------------------------------------------------------
		-- Build Applicable Transaction Types
			-- Not redemptions and a multiplier is not 0
		----------------------------------------------------------------------
		IF OBJECT_ID('tempdb..#TransactionType') IS NOT NULL
			DROP TABLE #TransactionType

		SELECT
			ID
			, Multiplier
		INTO #TransactionType
		FROM DIMAIN_TR.SLC_REPL.dbo.TransactionType
		WHERE Multiplier <> 0
			AND ID NOT IN (3,4)

		CREATE UNIQUE CLUSTERED INDEX UCIX ON #TransactionType (ID)

		----------------------------------------------------------------------
		-- Build Offers
		----------------------------------------------------------------------
		IF OBJECT_ID('tempdb..#Offer') IS NOT NULL
			DROP TABLE #Offer

		SELECT
			OfferID
			, TRY_CAST(SourceID AS INT) SourceID
		INTO #Offer
		FROM dbo.Offer c
		JOIN dbo.SourceType st
			ON (
				c.SourceTypeID = st.SourceTypeID
				AND st.SourceSystemID = @SourceSystemID
			) OR (
				c.OfferID = -1
				AND st.SourceSystemID = -1
			)

		CREATE UNIQUE CLUSTERED INDEX UCIX ON #Offer (SourceID)
	

	/**********************************************************************
	Build Transaction Dataset
	***********************************************************************/

		----------------------------------------------------------------------
		-- Get Latest Transaction Changes
		----------------------------------------------------------------------
		IF OBJECT_ID('tempdb..#Trans_Changes') IS NOT NULL
			DROP TABLE #Trans_Changes

		CREATE TABLE #Trans_Changes
		(
			ID INT
			, ActionType CHAR(1)
			, ActionDateTime DATETIME
		)

		CREATE CLUSTERED INDEX CIX ON #Trans_Changes (ID)
		
		IF @initialLoad = 0
		BEGIN
			INSERT INTO #Trans_Changes
			(
				ID
				, ActionType
				, ActionDateTime
			)
			SELECT
				TransID AS ID
				, [Action] AS ActionType
				, ActionDate AS ActionDateTime
			FROM DIMAIN_TR.SLC_REPL.dbo.Trans_Changes a
			WHERE ActionDate >= @CheckpointValue
				AND TransID NOT IN (
						-- TypeID 17, ItemID 15...suposed to be SLCPointsNegative but not idea what these are
						1345024651
						,1345024660
						, 1345024683
					)
			ORDER BY ActionDateTime
		END
		ELSE
		BEGIN
			INSERT INTO #Trans_Changes
			(
				ID
				, ActionType
				, ActionDateTime
			)
			SELECT TOP 25000000
				ID AS ID
				, 'I' AS ActionType
				, a.ProcessDate AS ActionDateTime
			FROM SLC_REPL.dbo.Trans a
			WHERE ID >= @CheckpointValue2
				AND ID NOT IN (
					-- TypeID 17, ItemID 15...suposed to be SLCPointsNegative but not idea what these are
					1345024651
					,1345024660
					, 1345024683
				)
			ORDER BY a.ID
		END
		----------------------------------------------------------------------
		-- Get Updated TransactionIDs so that they can be inserted with the same ID
		----------------------------------------------------------------------
		IF OBJECT_ID('tempdb..#UpdatedTranIDs') IS NOT NULL
			DROP TABLE #UpdatedTranIDs

		CREATE TABLE #UpdatedTranIDs
		(
			TransactionID INT
			, SourceID INT
		)

		CREATE UNIQUE CLUSTERED INDEX UCIX ON #UpdatedTranIDs (SourceID)

		INSERT INTO #UpdatedTranIDs
		(
			TransactionID
			, SourceID
		)
		SELECT
			t.TransactionID
			, t.SourceID
		FROM dbo.Transactions t
		WHERE EXISTS (
				SELECT 1
				FROM  #Trans_Changes tc
				WHERE t.SourceID = tc.ID
					AND t.SourceTypeID = @SourceTypeID
					AND tc.ActionType IN ('U')
		)

		----------------------------------------------------------------------
		-- Extract Transactions from SLC for updated/inserted rows
		----------------------------------------------------------------------

		IF OBJECT_ID('tempdb..#Trans_Staging') IS NOT NULL
			DROP TABLE #Trans_Staging

		CREATE TABLE #Trans_Staging
		(
			ID INT
			, [Date] DATETIME2
			, TypeID TINYINT
			, ItemID INT
			, Earning SMALLMONEY
			, Price SMALLMONEY
			, PanID INT
			, MatchID INT
			, DirectDebitOriginatorID INT
			, ActivationDays INT
			, ProcessDate DATETIME
			, PublisherID INT
			, CustomerID INT
		)

		CREATE CLUSTERED INDEX CIX ON #Trans_Staging (MatchID)

		INSERT INTO #Trans_Staging
		(
			ID
			, [Date]
			, TypeID
			, ItemID
			, Earning
			, Price
			, PanID
			, MatchID
			, DirectDebitOriginatorID
			, ActivationDays
			, ProcessDate
			, PublisherID
			, CustomerID
		)
		SELECT
			t.ID
			, t.Date
			, t.typeID
			, t.ItemID
			, t.ClubCash * tt.Multiplier AS Earning
			, t.Price * tt.Multiplier AS Price
			, t.PanID
			, t.MatchID
			, t.DirectDebitOriginatorID
			, t.ActivationDays
			, t.ProcessDate
			, f.PublisherID
			, f.CustomerID
		FROM SLC_REPL.dbo.Trans t
		JOIN #TransactionType tt
			ON t.TypeID = tt.ID
		JOIN #Customer f
			ON t.FanID = f.SourceID
		WHERE EXISTS (
				SELECT 1
				FROM  #Trans_Changes tc
				WHERE t.ID = tc.ID
					AND tc.ActionType IN ('U', 'I')
			)

		----------------------------------------------------------------------
		-- Build Retail Outlet
		----------------------------------------------------------------------
		IF OBJECT_ID('tempdb..#RetailOutlet') IS NOT NULL
			DROP TABLE #RetailOutlet

		CREATE TABLE #RetailOutlet
		(
			ID INT
			, PartnerID INT
		)
		CREATE UNIQUE CLUSTERED INDEX UCIX ON #RetailOutlet (ID)

		INSERT INTO #RetailOutlet
		SELECT *
		FROM OPENQUERY(DIMAIN_TR,
			'SELECT
				ID
				, PartnerID
			FROM SLC_REPL.dbo.RetailOutlet rom'
		) x
		----------------------------------------------------------------------
		-- Get Applicable Match Trans
		----------------------------------------------------------------------
		IF OBJECT_ID('tempdb..#MatchTrans') IS NOT NULL
			DROP TABLE #MatchTrans

		CREATE TABLE #MatchTrans
		(
			ID INT
			, RetailOutletID INT
			, PartnerCommissionRuleID INT
			, PartnerID INT
			, RequiredIronOfferID INT
		)

		CREATE UNIQUE CLUSTERED INDEX UCIX ON #MatchTrans (ID)

		INSERT INTO #MatchTrans
		(
			ID
			, RetailOutletID
			, PartnerCommissionRuleID
			, PartnerID
			, RequiredIronOfferID
		)
		SELECT
			m.ID
			, RetailOutletID
			, PartnerCommissionRuleID
			, rom.PartnerID
			, pcr.RequiredIronOfferID
		FROM SLC_REPL.dbo.[Match] m
		LEFT JOIN #RetailOutlet rom
			ON m.RetailOutletID = rom.ID
		LEFT JOIN SLC_REPL.dbo.PartnerCommissionRule pcr
			ON m.PartnerCommissionRuleID = pcr.ID
		WHERE EXISTS (
			SELECT 1
			FROM #Trans_Staging tx
			WHERE m.ID = tx.MatchID
		)
		
		----------------------------------------------------------------------
		-- Get Applicable Payment Cards
		----------------------------------------------------------------------
		IF OBJECT_ID('tempdb..#PaymentCard') IS NOT NULL
			DROP TABLE #PaymentCard

		CREATE TABLE #PaymentCard
		(
			ID INT
			, PaymentCardID INT
			, PaymentMethodID SMALLINT
		)

		CREATE UNIQUE CLUSTERED INDEX CIX ON #PaymentCard (ID)

		INSERT INTO #PaymentCard
		(
			ID
			, PaymentCardID
			, PaymentMethodID
		)
		SELECT 
			p.ID
			, pc.PaymentCardID
			, CASE
				WHEN pc.SourcePaymentCardTypeID = 1 THEN 1
				WHEN pc.SourcePaymentCardTypeID = 2 THEN 0
				ELSE -1
			END AS PaymentMethodID
		FROM SLC_REPL.dbo.Pan p	
		JOIN dbo.PaymentCard pc
			ON p.PaymentCardID = pc.SourceID
		JOIN dbo.SourceType st
			ON pc.SourceTypeID = st.SourceTypeID
			AND st.SourceSystemID = @SourceSystemID
		WHERE EXISTS (
			SELECT 1
			FROM #Trans_Staging tx
			WHERE p.ID = tx.PanID
		)

		
		----------------------------------------------------------------------
		-- SLC Redeems
		----------------------------------------------------------------------
		IF OBJECT_ID('tempdb..#SLCRedeem') IS NOT NULL
			DROP TABLE #SLCRedeem


		CREATE TABLE #SLCRedeem
		(
			ID INT
			, SupplierID INT
		)

		CREATE UNIQUE CLUSTERED INDEX CIX ON #SLCRedeem (ID)

		INSERT INTO #SLCRedeem
		SELECT
			ID
			, SupplierID
		FROM DIMAIN_TR.SLC_REPL.dbo.Redeem

		
		----------------------------------------------------------------------
		-- Cleanup Trans to be transformed into final insert
		----------------------------------------------------------------------

		IF OBJECT_ID('tempdb..#Trans') IS NOT NULL
			DROP TABLE #Trans
		CREATE TABLE #Trans
		(
			ID INT
			, [Date] DATETIME2
			, TypeID TINYINT
			, ItemID INT
			, Earning SMALLMONEY
			, Price SMALLMONEY
			, PanID INT
			, MatchID INT
			, DirectDebitOriginatorID INT
			, PublisherID INT
			, EarningSource_SourceTypeID INT
			, EarningSource_SourceID VARCHAR(36)
			, RequiredIronOfferID INT
			, PaymentCardID INT
			, PaymentMethodID INT
			, CustomerID INT
			, ActivationDays INT
			, ProcessDate DATETIME
		)

		CREATE CLUSTERED INDEX UCIX ON #Trans (EarningSource_SourceTypeID, EarningSource_SourceID)

		INSERT INTO #Trans
		(
			ID
			, [Date]
			, TypeID
			, ItemID
			, Earning
			, Price
			, PanID
			, MatchID
			, DirectDebitOriginatorID
			, PublisherID
			, EarningSource_SourceTypeID
			, EarningSource_SourceID
			, RequiredIronOfferID
			, PaymentCardID
			, PaymentMethodID
			, CustomerID
			, ActivationDays
			, ProcessDate
		)
		SELECT
			t.ID
			, t.Date
			, t.TypeID
			, t.ItemID
			, t.Earning
			, t.Price
			, t.PanID
			, t.MatchID
			, t.DirectDebitOriginatorID
			, t.PublisherID
			, x.EarningSource_SourceTypeID
			, CASE EarningSource_SourceTypeID
				WHEN @SourceTypeID_SLCPoints THEN ItemID
				WHEN @SourceTypeID_SLCPointsNegative THEN ItemID
				WHEN @SourceTypeID_DirectDebitOriginator THEN t.DirectDebitOriginatorID
				WHEN @SourceTypeID_Partner THEN px.PartnerID
				WHEN @SourceTypeID_TransactionType THEN t.TypeID
			END AS EarningSource_SourceID
			, m.RequiredIronOfferID
			, pan.PaymentCardID
			, pan.PaymentMethodID
			, t.CustomerID
			, t.ActivationDays
			, t.ProcessDate
		FROM #Trans_Staging t
		LEFT JOIN #PaymentCard pan
			ON pan.ID = t.PanID
		LEFT JOIN SLC_REPL.dbo.PartnerOffer po 
			ON t.TypeID IN (2, 5) 
			AND	po.id = t.ItemID -- Online Transactions
		LEFT JOIN #RetailOutlet ro 
			ON t.TypeID IN (2, 5, 9, 10) 
			AND ro.id = t.ItemID -- Offline Transactions
		LEFT JOIN #MatchTrans m
			ON t.MatchID = m.id
		CROSS APPLY (
			SELECT COALESCE(ro.PartnerID /* Offline Transactions */, po.PartnerID /* Online Transactions */, m.PartnerID)
		) px(PartnerID)
		CROSS APPLY (
			SELECT CASE
				WHEN t.TypeID = 1
					THEN @SourceTypeID_SLCPoints

				WHEN t.typeID = 17
					THEN @SourceTypeID_SLCPointsNegative
					
				WHEN t.TypeID IN (23, 24) AND t.ItemID = 89
					THEN @SourceTypeID_Partner					
				WHEN t.TypeID IN (2, 5, 9, 10, 13, 14)
					THEN @SourceTypeID_Partner

				WHEN t.TypeID IN (23, 24)
					THEN @SourceTypeID_DirectDebitOriginator

				ELSE @SourceTypeID_TransactionType
				END
		) x(EarningSource_SourceTypeID)

		----------------------------------------------------------------------
		-- Linked Transactions
		----------------------------------------------------------------------
		IF OBJECT_ID('tempdb..#LinkedTrans') IS NOT NULL
			DROP TABLE #LinkedTrans

		CREATE TABLE #LinkedTrans
		(
			ID INT
			, ItemID INT
			, TypeID INT
		)

		CREATE CLUSTERED INDEX CIX ON #LinkedTrans (ID)

		INSERT INTO #LinkedTrans
		SELECT
			ID
			, ItemID
			, TypeID
		FROM SLC_REPL.dbo.Trans tx WITH (NOLOCK) -- Get the linked transaction for earn/burn redemptions
		WHERE EXISTS (
			SELECT 1 FROM #Trans t
			WHERE t.ItemID = tx.ID
				AND t.TypeID IN (26,27)
		)

		INSERT INTO #LinkedTrans
		SELECT
			ID
			, ItemID
			, TypeID
		FROM SLC_REPL.dbo.Trans tx WITH (NOLOCK) -- Get the linked transaction for earn/burn redemptions refunds
		WHERE EXISTS (
			SELECT 1 FROM #LinkedTrans t
			WHERE t.ItemID = tx.ID
				AND t.TypeID IN (4)
		) AND NOT EXISTS (
			SELECT 1 FROM #LinkedTrans t
			WHERE tx.ID = t.ID
		)

		----------------------------------------------------------------------
		-- Perform Final Transformation
		----------------------------------------------------------------------
		IF OBJECT_ID('tempdb..#Transactions') IS NOT NULL
			DROP TABLE #Transactions

		CREATE TABLE #Transactions(
			[TransactionID] INT NULL,
			CustomerID [int] NOT NULL,
			[OfferID] [int] NOT NULL,
			[PublisherID] [smallint] NOT NULL,
			[PaymentCardID] INT NOT NULL,
			[Spend]  DECIMAL(9,2) NULL,
			[Earning]  DECIMAL(9,2) NULL,
			[CurrencyCode] varchar(3) NOT NULL,
			[TranDate] [date] NOT NULL,
			[TranDateTime] [datetime2](7) NOT NULL,
			[PaymentMethodID] [smallint] NOT NULL,
			[EarningSourceID] [smallint] NOT NULL,
			[ActivationDays] [int] NULL,
			[EligibleDate] [date] NOT NULL,
			SourceTypeID smallint NOT NULL,
			SourceID VARCHAR(36) NOT NULL,
			[CreatedDateTime] [datetime2](7) NOT NULL,
			[SourceAddedDateTime] [datetime2] NULL
		)
		
		CREATE CLUSTERED INDEX CIX ON #Transactions (TranDate)
		CREATE NONCLUSTERED INDEX NIX ON #Transactions (TransactionID)
		
		INSERT INTO #Transactions
		(
			TransactionID
			, CustomerID
			, OfferID
			, PublisherID
			, PaymentCardID
			, Spend
			, Earning
			, CurrencyCode
			, TranDate
			, TranDateTime
			, PaymentMethodID
			, EarningSourceID
			, ActivationDays
			, EligibleDate
			, SourceTypeID
			, SourceID
			, CreatedDateTime
			, SourceAddedDateTime
		)
		SELECT
			ut.TransactionID
			, t.CustomerID
			, o.OfferID
			, t.PublisherID
			, COALESCE(t.PaymentCardID, -1)
			, CASE
					WHEN t.TypeID NOT IN (9, 10) 
							AND t.ItemID NOT IN (56, 57, 58, 62, 63, 64, 66, 75, 77, 79, 89)
						THEN 0
					ELSE t.Price 
				END AS Spend
			, t.Earning
			, 'GBP' AS CurrencyCode
			, TranDate
			, t.Date AS TranDateTime
			, COALESCE(
					CASE
						WHEN t.PaymentMethodID IS NULL 
								AND (t.DirectDebitOriginatorID IS NOT NULL OR t.TypeID = 29)
							THEN 2
						ELSE t.PaymentMethodID
					END
				, -1) AS PaymentMethodID
			, COALESCE(esry.EarningSourceID, esrx.EarningSourceID, es.EarningSourceID) AS EarningSourceID
			, t.ActivationDays
			, DATEADD(DAY, t.ActivationDays, TranDate) AS EligibleDate
			, @SourceTypeID 						AS SourceTypeID
			, t.ID 									AS SourceID
			, @RunDateTime							AS CreatedDateTime
			, t.ProcessDate							AS SourceAddedDateTime
		FROM #Trans t
		-- LEFT JOIN #DDSuppliers dd
		-- 	ON t.DirectDebitOriginatorID = dd.DirectDebitOriginatorID
		CROSS APPLY (
			SELECT 
				COALESCE(t.RequiredIronOfferID, -1)
				, CAST(t.Date AS DATE)
		) i(IronOfferID, TranDate)
		LEFT JOIN #EarningSource es
			ON t.EarningSource_SourceTypeID = es.SourceTypeID 
			AND t.EarningSource_SourceID = es.SourceID
		LEFT JOIN #Offer o
			ON i.IronOfferID = o.SourceID
		LEFT JOIN #LinkedTrans tx WITH (NOLOCK) -- Get the linked transaction for earn/burn redemptions
			ON t.ItemID = tx.ID
			AND t.TypeID IN (26,27)
		LEFT JOIN #SLCRedeem rx -- Get the redemption info for the linked earn/burn transaction
			ON tx.ItemID = rx.ID
			AND tx.TypeID = 3
		LEFT JOIN #EarningSource esrx -- Get the redemption supplier details
			ON rx.SupplierID = esrx.SourceID
			AND esrx.SourceTypeID = @SourceTypeID_RedeemSupplier
		LEFT JOIN #LinkedTrans ty WITH (NOLOCK) -- if it is a refunded earn/burn transaction, the first link will be a cancelled redemption that links to the original redemption
			ON tx.ItemID = ty.ID
			AND t.TypeID = 27
		LEFT JOIN #SLCRedeem ry -- get redemption info for linked cancelled redemption
			ON ty.ItemID = ry.ID
			AND ty.TypeID = 3
		LEFT JOIN #EarningSource esry -- get redemption supplier details
			ON ry.SupplierID = esry.SourceID
			AND esry.SourceTypeID = @SourceTypeID_RedeemSupplier
		LEFT JOIN #UpdatedTranIDs ut
			ON t.ID = ut.SourceID
		
	BEGIN TRAN
		DECLARE @Inserted BIGINT = 0
			, @Updated INT = 0
			, @Deleted INT = 0
		----------------------------------------------------------------------
		-- Remove deleted transactions
		----------------------------------------------------------------------
		DELETE t 
		FROM dbo.Transactions t
		WHERE EXISTS (
			SELECT 1
			FROM #Trans_Changes tc
			WHERE t.SourceID = tc.ID
				AND t.SourceTypeID = @SourceTypeID
				AND tc.ActionType IN ('D')
		)

		SET @Deleted = @@ROWCOUNT

		-- If an updated transaction already exists in the staging table, just delete it and let it be reinserted

		UPDATE #Trans_Changes
		SET ActionType = 'X'
		FROM #Trans_Changes tc
		WHERE EXISTS (
			SELECT 1
			FROM Staging.Transactions tx
			WHERE tc.ID = tx.SourceID
				AND tx.SourceTypeID = @SourceTypeID
		)
			AND tc.ActionType = 'U'
			

		DELETE t 
		FROM Staging.Transactions t
		WHERE EXISTS (
			SELECT 1
			FROM #Trans_Changes tc
			WHERE t.SourceID = tc.ID
				AND t.SourceTypeID = @SourceTypeID
				AND tc.ActionType IN ('D', 'X')
		)

		SET @Deleted += @@ROWCOUNT

		----------------------------------------------------------------------
		-- Update Transactions
		----------------------------------------------------------------------
		UPDATE t
		SET 
			CustomerID = tx.CustomerID
			, OfferID = tx.OfferID
			, EarningSourceID = tx.EarningSourceID
			, PublisherID = tx.PublisherID
			, PaymentCardID = tx.PaymentCardID
			, Spend = tx.Spend
			, Earning = tx.Earning
			, CurrencyCode = tx.CurrencyCode
			, TranDate = tx.TranDate
			, TranDateTime = tx.TranDateTime
			, PaymentMethodID = tx.PaymentMethodID
			, ActivationDays = tx.ActivationDays
			, EligibleDate = tx.EligibleDate
			, SourceTypeID = tx.SourceTypeID
			, SourceID = tx.SourceID
			, CreatedDateTime = tx.CreatedDateTime
			, SourceAddedDateTime = tx.SourceAddedDateTime 
		FROM dbo.Transactions t
		JOIN #Transactions tx
			ON t.TransactionID = tx.TransactionID
			AND tx.TransactionID IS NOT NULL

		SET @Updated = @@ROWCOUNT

		----------------------------------------------------------------------
		-- Insert new transactions
		----------------------------------------------------------------------
		INSERT INTO Staging.Transactions WITH (TABLOCKX)
		(
			CustomerID
			, OfferID
			, EarningSourceID
			, PublisherID
			, PaymentCardID
			, Spend
			, Earning
			, CurrencyCode
			, TranDate
			, TranDateTime
			, PaymentMethodID
			, ActivationDays
			, EligibleDate
			, SourceTypeID
			, SourceID
			, CreatedDateTime
			, SourceAddedDateTime
		)

		SELECT
			CustomerID
			, OfferID
			, EarningSourceID
			, PublisherID
			, PaymentCardID
			, Spend
			, Earning
			, CurrencyCode
			, TranDate
			, TranDateTime
			, PaymentMethodID
			, ActivationDays
			, EligibleDate
			, SourceTypeID
			, SourceID
			, CreatedDateTime
			, SourceAddedDateTime
		FROM #Transactions t
		WHERE TransactionID IS NULL
			AND NOT EXISTS (
				SELECT 1 FROM Staging.Transactions tx
				WHERE t.SourceID = tx.SourceID
					AND t.SourceTypeID = tx.SourceTypeID

			)
			AND NOT EXISTS (
				SELECT 1 FROM dbo.Transactions tx
				WHERE t.SourceID = tx.SourceID
					AND t.SourceTypeID = tx.SourceTypeID

			)
		
		SET @Inserted = @@ROWCOUNT
		----------------------------------------------------------------------
		-- Update Checkpoints
		----------------------------------------------------------------------		
		DECLARE @NewCheckpointValue DATETIME = (SELECT MAX(ActionDateTime) FROM #Trans_Changes)
		
		IF @initialLoad = 1
		BEGIN
			
			DECLARE @NewCheckpointValue2 INT = (SELECT MAX(ID) FROM #Trans_Changes)
			EXEC WHB.Update_TableCheckpoint @CheckpointTable2, @NewCheckpointValue2

		END

		EXEC WHB.Update_TableCheckpoint @CheckpointTable, @NewCheckpointValue

		----------------------------------------------------------------------
		-- Log
		----------------------------------------------------------------------
		
		INSERT INTO WHB.Build_Log (RunID, StartDateTime, EndDateTime, StoredProcName, InsertedRows, UpdatedRows, DeletedRows)
		SELECT
			@RunID
			,@RunDateTime
			,GETDATE()
			,@StoredProcedureName
			,InsertedRows = @Inserted
			,UpdatedRows = @Updated
			,DeletedRows = @Deleted

	COMMIT TRAN

END








