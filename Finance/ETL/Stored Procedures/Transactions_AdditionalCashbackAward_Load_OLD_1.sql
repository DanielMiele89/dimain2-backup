CREATE PROCEDURE [ETL].[Transactions_AdditionalCashbackAward_Load_OLD]
AS
BEGIN

	 SET NOCOUNT ON
	 SET XACT_ABORT ON
	----------------------------------------------------------------------
	-- Checkpoint Variables
	----------------------------------------------------------------------
	DECLARE @CheckpointTypeID INT = 2
		, @StoredProcName VARCHAR(100) = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)
	DECLARE @CheckpointValue INT = ETL.getTableCheckpoint(@CheckpointTypeID, @StoredProcName, 1, 0)

	----------------------------------------------------------------------
	-- System Variables
	----------------------------------------------------------------------
	DECLARE @RunDateTime DATETIME2 = GETDATE()
		, @SourceTypeID INT = 2

	EXEC ETL.SourceType_CheckID @SourceTypeID, 'AdditionalCashbackAward'

	----------------------------------------------------------------------
	-- Build Base tables
	----------------------------------------------------------------------
	if object_id('tempdb..#Customer') is not null drop table #Customer
	Select FanID,ROW_NUMBER() OVER(ORDER BY FanID ASC) AS RowNo
	Into #Customer
	From Warehouse.Relational.Customer

	Create Clustered Index ix_Customer_FanID on #Customer (FanID)

	----------------------------------------------------------------------
	----------------------------------------------------------------------
	if object_id('tempdb..#Types') is not null drop table #Types
	Select aca.*,tt.Multiplier
	Into #Types
	From Warehouse.Relational.[AdditionalCashbackAwardType] as aca
	inner join SLC_Report.dbo.TransactionType as tt with (Nolock)
		on	aca.TransactionTypeID = tt.ID

	----------------------------------------------------------------------
	-- Loop Control Variables
	----------------------------------------------------------------------
	Declare @RowNo int = 1,
			@MaxRowNo int = (Select Max(RowNo) from #Customer),
			@ChunkSize int = 100000 --1000000, --250000,

	if object_id('tempdb..#Customer_Temp') is not null drop table #Customer_Temp
		Create Table #Customer_Temp (FanID int, Primary Key (FanID))

	/**********************************************************************
	LOOP through Customers and pull transactions
	***********************************************************************/
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

	While @RowNo <= @MaxRowNo
	Begin
		------------------------------------------------------------------------------
		------------------------------ Find specific customers -----------------------
		------------------------------------------------------------------------------
	
		Insert into #Customer_Temp	
		Select	FanID
		From	#Customer as c
		Where	c.RowNo Between @RowNo and @RowNo + (@ChunkSize-1)
	
		------------------------------------------------------------------------------
		--------------Get Additional Cashback Awards with a PanID---------------------
		------------------------------------------------------------------------------

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
			, 132 AS ClubID
			, t.Price AS Spend
			, t.ClubCash*tt.Multiplier as CashbackEarned
			, t.Date as TranDate
			, t.TypeID AS TransactionTypeID
			, tt.AdditionalCashbackAwardTypeID
			, -1 AS AdditionalCashbackAdjustmentTypeID
			, -1 AS AdditionalCashbackAdjustmentCategoryID
			, Case
					When CardTypeID = 1 then 1 -- Credit Card
					When CardTypeID = 2 then 0 -- Debit Card
					When t.DirectDebitOriginatorID IS not null then 2 -- Direct Debit
					When t.DirectDebitOriginatorID IS null and t.typeid = 29 then 2 -- Direct Debit-- ZT 31/032020 changed the clause to IS NULL and included the R30 typeid
					When tt.AdditionalCashbackAwardTypeID = 11 then 1 -- ApplyPay and Credit Card
					Else 0
			   End as PaymentMethodID
			, t.VAT
			, t.VATRate
			, t.ProcessDate AS SourceAddedDate
			, t.ID AS SourceID
			, @SourceTypeID AS SourceTypeID
			, 2 AS SourceSystemID
			, @RunDateTime AS CreatedDateTime
		FROM  #Types as tt
		inner hash join SLC_Report.dbo.Trans as t with (nolock)
			on tt.ItemID = t.ItemID 
			and tt.TransactionTypeID = t.TypeID
		inner join #Customer_Temp as c
			on t.FanID = c.fanid
		Left Outer join SLC_Report.dbo.Pan as p
			on t.PanID = p.ID
		Left Outer join SLC_Report..PaymentCard as pc
			on p.PaymentCardID = pc.ID
		Where t.VectorMajorID is not null 
			and t.VectorMinorID is not null
			AND t.ID > @CheckpointValue
			AND t.Date between '2021-01-01' and '2021-01-31'
	
		Truncate Table #Customer_Temp
	
		Set @RowNo = @RowNo+@ChunkSize

	End


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
			, t.SourceSystemID
			, t.CreatedDateTime
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
