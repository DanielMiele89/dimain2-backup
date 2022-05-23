/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description: One off load of apple pay historical transactions

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [ETL].[Transactions_AdditionalCashbackAward_CCMonthlyAwards_Load_OLD]
AS
BEGIN

	 SET NOCOUNT ON
	 SET XACT_ABORT ON

	----------------------------------------------------------------------
	-- Checkpoint Variables
	----------------------------------------------------------------------
	DECLARE @CheckpointTypeID INT = 10
		, @StoredProcName VARCHAR(100) = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)
	DECLARE @CheckpointValue INT = ETL.getTableCheckpoint(@CheckpointTypeID, @StoredProcName, 1, 0)

	----------------------------------------------------------------------
	-- System Variables
	----------------------------------------------------------------------
	DECLARE @RunDateTime DATETIME2 = GETDATE()
		, @SourceTypeID INT = 2

	EXEC ETL.SourceType_CheckID @SourceTypeID, 'AdditionalCashbackAward'

	----------------------------------------------------------------------
	-- Build Lookups
	----------------------------------------------------------------------
	if object_id('tempdb..#Types') is not null drop table #Types
	Select aca.*,tt.Multiplier
	Into #Types
	From Warehouse.Relational.[AdditionalCashbackAwardType] as aca
	inner join SLC_Report.dbo.TransactionType as tt with (Nolock)
		on	aca.TransactionTypeID = tt.ID

	----------------------------------------------------------------------
	-- Build Staging Table
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#MonthlyAwards') IS NOT NULL 
		DROP TABLE #MonthlyAwards

	select	  
		t.FanID
		, -1 AS IronOfferID
		, -1 AS PartnerID
		, 132 AS PublisherID
		, t.price AS Spend
		, t.ClubCash*tt.Multiplier as Earnings
		, t.Date as TranDate
		, t.TypeID AS TransactionTypeID
		, tt.AdditionalCashbackAwardTypeID
		, -1 AS AdditionalCashbackAdjustmentTypeID
		, -1 AS AdditionalCashbackAdjustmentCategoryID
		, 1 AS PaymentMethodID
		, t.VAT
		, t.VATRate
		, t.ProcessDate AS SourceAddedDate
		, t.ID AS SourceID
		, @SourceTypeID AS SourceTypeID
		, 1 AS SourceSystemID
		, @RunDateTime AS CreatedDateTime
		, a.RowNum AS CheckpointID
	INTO #MonthlyAwards
	from Warehouse.Relational.Customer as c with (nolock)
	JOIN SLC_Report.DBO.Trans as t with (nolock)
		on t.FanID = c.fanid
	JOIN #Types as tt
		on tt.ItemID = t.ItemID and
			tt.TransactionTypeID = t.TypeID          
	JOIN Warehouse.Staging.RBSGFundedCreditCardMonthlyOffers as a
		on t.ID = a.TranID
	WHERE RowNum > @CheckpointValue

	----------------------------------------------------------------------
	-- Perform Load
	----------------------------------------------------------------------
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
		FROM #MonthlyAwards

		INSERT INTO ETL.TableCheckpoint (
			CheckpointTypeID,
			CheckpointValue1
		)
		SELECT 
			@CheckpointTypeID
			, MAX(CheckpointID)
		FROM #MonthlyAwards

	COMMIT


END
