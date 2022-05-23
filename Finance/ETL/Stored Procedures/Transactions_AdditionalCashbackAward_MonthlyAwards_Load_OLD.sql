CREATE PROCEDURE [ETL].[Transactions_AdditionalCashbackAward_MonthlyAwards_Load_OLD]
AS
BEGIN

	 SET XACT_ABORT ON
	 SET NOCOUNT ON

	----------------------------------------------------------------------
	-- Checkpoint Variables
	----------------------------------------------------------------------
	DECLARE @CheckpointTypeID INT = 4
		, @StoredProcName VARCHAR(100) = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)
	DECLARE @CheckpointValue INT = ETL.getTableCheckpoint(@CheckpointTypeID, @StoredProcName, 1, 0)

	----------------------------------------------------------------------
	-- System Variables
	----------------------------------------------------------------------
	DECLARE @RunDateTime DATETIME2 = GETDATE()
		, @SourceTypeID INT = 2

	EXEC ETL.SourceType_CheckID @SourceTypeID, 'AdditionalCashbackAward'

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Pull off a list of Transactions for Amazon Offer-----------------------
	----------------------------------------------------------------------------------------------------*/
	if object_id('tempdb..#Trans') is not null drop table #Trans
	Select	ID as TranID,
			t.ItemID,
			a.ACATypeID
	Into #Trans
	From SLC_Report.dbo.Trans as t
	inner join Warehouse.Staging.AdditionalCashbackAwards_MonthlyCCOffers as a
		on t.ItemID = a.ItemID
	Where TypeID = 1

	/*--------------------------------------------------------------------------------------------------
	------------------------------------Create Typesd Table Table---------------------------------------
	----------------------------------------------------------------------------------------------------*/
	if object_id('tempdb..#Types') is not null drop table #Types
	Select aca.*,tt.Multiplier
	Into #Types
	From Warehouse.Relational.[AdditionalCashbackAwardType] as aca
	inner join SLC_Report.dbo.TransactionType as tt with (Nolock)
		on	aca.TransactionTypeID = tt.ID

	------------------------------------------------------------------------------
	--------------Get Additional Cashback Awards with a PanID---------------------
	------------------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#Transactions') IS NOT NULL
		DROP TABLE #Transactions

		
	CREATE TABLE #Transactions
	(
		FanID INT NOT NULL,
		IronOfferID INT NOT NULL,
		PartnerID INT NOT NULL,
		PublisherID INT NOT NULL,
		Spend SMALLMONEY,
		Earnings SMALLMONEY,
		TranDate DATE NOT NULL,
		TransactionTypeID SMALLINT NULL,
		AdditionalCashbackAwardTypeID SMALLINT NOT NULL,
		AdditionalCashbackAdjustmentTypeID SMALLINT NOT NULL,
		AdditionalCashbackAdjustmentCategoryID SMALLINT NOT NULL,
		PaymentMethodID TINYINT NOT NULL,
		VAT SMALLMONEY,
		VATRate DECIMAL(4,2),
		SourceAddedDate DATE,
		SourceID INT NOT NULL,
		SourceTypeID INT NOT NULL,
		SourceSystemID INT NOT NULL,
		CreatedDateTime DATETIME2 NOT NULL

	)

	Insert Into #Transactions
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
		, VAT
		, VATRate
		, SourceAddedDate
		, SourceID
		, SourceTypeID
		, SourceSystemID
		, CreatedDateTime
	) 
	select --top 1
		t.FanID
		, -1 AS IronOfferID
		, -1 AS PartnerID
		, 132 AS PublisherID
		, t.Price AS Spend
		, t.ClubCash*tt.Multiplier as CashbackEarned
		, t.Date as TranDate
		, t.TypeID AS TransactionTypeID
		, tt.AdditionalCashbackAwardTypeID
		, -1 AS AdditionalCashbackAdjustmentTypeID
		, -1 AS AdditionalCashbackAdjustmentCategoryID
		, 1 as PaymentMethodID
		, t.VAT
		, t.VATRate
		, t.ProcessDate AS SourceAddedDate
		, t.ID AS SourceID
		, @SourceTypeID AS SourceTypeID
		, 2 AS SourceSystemID
		, @RunDateTime AS CreatedDateTime
	from Warehouse.relational.Customer as c with (nolock)
	inner join SLC_Report.DBO.Trans as t with (nolock)
		on t.FanID = c.fanid
	inner join #Types as tt
		on tt.ItemID = t.ItemID and
			tt.TransactionTypeID = t.TypeID          
	inner join Warehouse.Staging.RBSGFundedCreditCardMonthlyOffers as a
		on t.ID = a.TranID
	Where t.ID > @CheckpointValue
		AND t.Date between '2021-01-01' and '2021-01-31'


	BEGIN TRAN

		INSERT INTO Finance.dbo.Transactions
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
			, VAT
			, VATRate
			, SourceAddedDate
			, SourceID
			, SourceTypeID
			, SourceSystemID
			, CreatedDateTime
		) 
		SELECT
			FanID
			, IronOfferID
			, PartnerID
			, PublisherID
			, Spend
			, Earnings
			, TranDate
			, TransactionTypeID
			, COALESCE(a.AdditionalCashbackAwardTypeID_New, t.AdditionalCashbackAwardTypeID) As AdditionalCashbackAwardTypeID
			, AdditionalCashbackAdjustmentTypeID
			, AdditionalCashbackAdjustmentCategoryID
			, PaymentMethodID
			, VAT
			, VATRate
			, SourceAddedDate
			, SourceID
			, SourceTypeID
			, SourceSystemID
			, CreatedDateTime
		FROM #Transactions t
		LEFT JOIN warehouse.[Relational].[AdditionalCashbackAwardTypeAdjustments] a
			ON t.AdditionalCashbackAwardTypeID = a.AdditionalCashbackAwardTypeID_Original
			AND t.TranDate between a.StartDate and a.EndDate

		INSERT INTO ETL.TableCheckpoint (
			CheckpointTypeID,
			CheckpointValue1
		)
		SELECT 
			@CheckpointTypeID
			, MAX(SourceID)
		FROM #Transactions

	COMMIT TRAN

	RETURN @@rowcount

END
