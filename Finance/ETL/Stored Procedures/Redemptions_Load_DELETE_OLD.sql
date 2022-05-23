CREATE PROC [ETL].[Redemptions_Load_DELETE_OLD]
		@RunID BIGINT = NULL,
		@RowCnt INT = -1 OUTPUT
AS
BEGIN

	 SET XACT_ABORT ON
	----------------------------------------------------------------------
	-- System Variables
	----------------------------------------------------------------------
	DECLARE @RunDateTime DATETIME2 = GETDATE()

	----------------------------------------------------------------------
	-- Load Staging table
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#Redemptions') IS NOT NULL 
		DROP TABLE #Redemptions

	CREATE TABLE #Redemptions
	(
		RedemptionID INT NOT NULL
		, SourceSystemID INT NOT NULL 
		, CustomerID INT NOT NULL
		, RedeemOfferID INT NULL
		, RedemptionTypeID INT NULL
		, RedemptionValue MONEY NOT NULL
		, RedemptionWorth MONEY NOT NULL
		, RedemptionDate DATE NOT NULL
		, CreatedDateTime DATETIME2 NOT NULL
	)

	INSERT INTO #Redemptions
	(
		RedemptionID		
		, SourceSystemID	
		, CustomerID		
		, RedeemOfferID		
		, RedemptionValue	
		, RedemptionWorth
		, RedemptionDate	
		, CreatedDateTime	
	)
	SELECT
		r.TranID AS RedemptionID
		, 1 AS SourceSystemID
		, r.FanID AS CustomerID
		, COALESCE(ro.RedeemOfferID, -1) AS RedeemOfferID
		, r.CashbackUsed AS RedemptionValue
		, COALESCE(r.TradeUp_Value, r.CashbackUsed) AS RedemptionWorth
		, r.RedeemDate
		, @RunDateTime
	FROM Warehouse.Relational.Redemptions r
	LEFT JOIN SLC_Report..Trans t
		ON r.TranID = t.ID
	LEFT JOIN dbo.RedeemOffer ro
		ON t.ItemID = ro.RedeemOfferID
	WHERE NOT EXISTS (
		SELECT 1
		FROM dbo.Redemptions dr
		WHERE r.TranID = dr.RedemptionID
	)

	CREATE CLUSTERED INDEX CIX ON #Redemptions (RedemptionID)

	ALTER TABLE dbo.Redemptions NOCHECK CONSTRAINT ALL

	INSERT INTO dbo.Redemptions
	(
		RedemptionID		
		, SourceSystemID	
		, CustomerID		
		, RedeemOfferID		
		, RedemptionValue	
		, RedemptionWorth
		, RedemptionDate	
		, isCancelled
		, CreatedDateTime	
	)
	SELECT
		RedemptionID		
		, SourceSystemID	
		, CustomerID		
		, RedeemOfferID		
		, RedemptionValue	
		, RedemptionWorth
		, RedemptionDate	
		, 0 AS IsCancelled
		, CreatedDateTime
	FROM #Redemptions

	SET @RowCnt = @@ROWCOUNT

	ALTER TABLE dbo.Redemptions WITH CHECK CHECK CONSTRAINT ALL

	UPDATE r
	SET isCancelled = 1
		, CancelledDate = t.Date
	FROM dbo.Redemptions r
	JOIN SLC_REPL..Trans t
		ON r.RedemptionID = t.ItemID
		AND t.TypeID = 4
  END
