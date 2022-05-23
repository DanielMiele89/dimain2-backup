
CREATE PROCEDURE [WHB].[Transactions__Staging_Load]
		@RunID INT = NULL,
		@Continue BIT = 0
AS
BEGIN
	 SET NOCOUNT ON;
	 SET XACT_ABORT ON;

	DECLARE @PartitionNumber INT = 0	
		, @RunDateTime DATETIME2 = GETDATE()
		, @StoredProcedureName VARCHAR(100)

	SET @StoredProcedureName = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)
	----------------------------------------------------------------------
	-- End if no data
	----------------------------------------------------------------------
	IF NOT EXISTS (SELECT TOP 1 1 FROM Staging.Transactions)
		RETURN 0

	IF @RunID IS NULL
		SET @RunID = NEXT VALUE FOR WHB.RunID
	----------------------------------------------------------------------
	-- Fail if shadow table exists
	----------------------------------------------------------------------
	DECLARE @ShadowTableNameStart VARCHAR(100) = 'Staging.Transactions_p'
	DECLARE @shadowTablesExist VARCHAR(MAX)
		, @TableCount INT
		, @ShadowTableSchemaName VARCHAR(100) = LEFT(@ShadowTableNameStart, CHARINDEX('.', @ShadowTableNameStart) - 1)
		, @ShadowTableTableName VARCHAR(100) = RIGHT(@ShadowTableNameStart, CHARINDEX('.', REVERSE(@ShadowTableNameStart))-1)

	SELECT @shadowTablesExist = STRING_AGG(SCHEMA_NAME(t.schema_id) + '.' + t.name, ', ')
		, @TableCount = COUNT(1)
	FROM sys.tables t 
	WHERE t.schema_id = SCHEMA_ID(@ShadowTableSchemaName)
		AND t.[name] like @ShadowTableTableName + '[0-9][0-9][0-9]'

		
	IF @shadowTablesExist IS NOT NULL
	BEGIN
		IF @Continue = 0 OR @TableCount > 1
		BEGIN
			DECLARE @ShadowErr VARCHAR(8000) = 'Following Shadow tables exist: ' + @shadowTablesExist
			;THROW 100000, @ShadowErr, 1
		END
		ELSE
		BEGIN
			SET @PartitionNumber = CAST(RIGHT(@shadowTablesExist, 3) AS INT) - 1
		END
	END
	--SET @PartitionNumber = 112
	----------------------------------------------------------------------
	-- Run Partition Maintennace
	----------------------------------------------------------------------
	EXEC WHB._PartitionMaintenance_Transactions_AddNew

	----------------------------------------------------------------------
	-- Run check constraints on Staging
		-- easier to catch errors here rather than when they get loaded to the main
	----------------------------------------------------------------------
	--ALTER TABLE Staging.Transactions WITH CHECK CHECK CONSTRAINT ALL

	----------------------------------------------------------------------
	-- Get Staging Months to load
	----------------------------------------------------------------------
	DROP TABLE IF EXISTS #StagingMonths

	SELECT DISTINCT
		CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, TranDate), 0)  AS DATE) AS StartDate
		, EOMONTH(TranDate, 0) AS EndDate
	INTO #StagingMonths
	FROM Staging.Transactions

	CREATE CLUSTERED INDEX CIX ON #StagingMonths (StartDate, EndDate)
	----------------------------------------------------------------------
	-- Get Partition Details
	----------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#PartitionDetails') IS NOT NULL
		DROP TABLE #PartitionDetails
		
	SELECT
		*
	INTO #PartitionDetails
	FROM dbo.vw_PartitionInfo_Transactions
	
	DELETE pd
	FROM #PartitionDetails pd
	WHERE NOT EXISTS (
		SELECT 1
		FROM #StagingMonths sm
		WHERE pd.EndDate = sm.EndDate
			OR pd.StartDate = sm.StartDate
	)

	----------------------------------------------------------------------
	-- Initial Partitioning Variables
	----------------------------------------------------------------------

	DECLARE @strPartitionNumber VARCHAR(5) = 0
		, @startDate DATE
		, @endDate DATE
		, @FileGroupName VARCHAR(50)
		, @ShadowTableName VARCHAR(100)
		, @ShadowObjectName VARCHAR(100)
		
	
	WHILE 1=1
	BEGIN
		DECLARE @Inserted BIGINT = 0
			, @Updated INT = 0
			, @Deleted INT = 0

		SET @StartDate = NULL
		SET @EndDate = NULL
		SET @strPartitionNumber = NULL
		SET @FileGroupName = NULL
		SET @ShadowTableName = NULL

		SET @RunDateTime = GETDATE()
		----------------------------------------------------------------------
		-- Set variables
		----------------------------------------------------------------------
		SELECT
			@PartitionNumber = PartitionNumber
			, @startDate = StartDate
			, @endDate = EndDate
			, @strPartitionNumber = PartitionNumber
			, @FileGroupName = PartitionFileGroupName
			, @ShadowTableName = CONCAT(@ShadowTableNameStart, RIGHT('000' + CAST(PartitionNumber AS VARCHAR(3)), 3))
		FROM 
		(
			SELECT TOP 1 *
			FROM #PartitionDetails
			WHERE PartitionNumber > @PartitionNumber
			ORDER BY PartitionNumber
		) x

		IF @StartDate IS NULL
			BREAK

		SET @ShadowObjectName = REPLACE(@ShadowTableName, '.', '_')

		
		----------------------------------------------------------------------
		-- Create Shadow Table
		----------------------------------------------------------------------
		DECLARE @strStartDate VARCHAR(10) = CAST(@StartDate AS VARCHAR(10))
			, @strEndDate VARCHAR(10) = CAST(@EndDate AS VARCHAR(10))

		IF @Continue = 0
		BEGIN
			EXEC('
				CREATE TABLE '+@ShadowTableName+' (
					[TransactionID] [int] NOT NULL,
					CustomerID [int] NOT NULL
						CONSTRAINT [FK_'+@ShadowObjectName+'_CustomerID] FOREIGN KEY
							REFERENCES [dbo].[Customer] ([CustomerID]),
					[OfferID] [int] NOT NULL
						CONSTRAINT [FK_'+@ShadowObjectName+'_OfferID] FOREIGN KEY
							REFERENCES [dbo].Offer(OfferID),
					[EarningSourceID] [smallint] NOT NULL
						CONSTRAINT FK_'+@ShadowObjectName+'_EarningSourceID FOREIGN KEY
							REFERENCES dbo.EarningSource (EarningSourceID),
					[PublisherID] [smallint] NOT NULL
						CONSTRAINT [FK_'+@ShadowObjectName+'_PublisherID] FOREIGN KEY
							REFERENCES [dbo].[Publisher] ([PublisherID]),
					[PaymentCardID] INT NOT NULL
						CONSTRAINT FK_'+@ShadowObjectName+'_PaymentCardID FOREIGN KEY
							REFERENCES dbo.PaymentCard (PaymentCardID),
					[Spend]  DECIMAL(9,2) NULL,
					[Earning]  DECIMAL(9,2) NULL,
					[CurrencyCode] CHAR(3) NOT NULL
						CONSTRAINT FK_'+@ShadowObjectName+'_CurrencyCode FOREIGN KEY
							REFERENCES dbo.CurrencyCode(CurrencyCode),
					[TranDate] [date] NOT NULL
						CONSTRAINT CHK_'+@ShadowObjectName+'_TranDate
							CHECK (TranDate >= '''+@strStartDate+''' AND TranDate <= '''+@strEndDate+'''),
					[TranDateTime] [datetime2](7) NOT NULL,
					[PaymentMethodID] [smallint] NOT NULL
						CONSTRAINT FK_'+@ShadowObjectName+'_PaymentMethodID FOREIGN KEY
							REFERENCES dbo.PaymentMethod (PaymentMethodID),
					[ActivationDays] [int] NULL,
					[EligibleDate] [date] NOT NULL,
					SourceTypeID smallint NOT NULL
						CONSTRAINT FK_'+@ShadowObjectName+'_SourceTypeID FOREIGN KEY
							REFERENCES dbo.SourceType(SourceTypeID),
					SourceID VARCHAR(36) NOT NULL,
					[CreatedDateTime] [datetime2](7) NOT NULL,
					[SourceAddedDateTime] [datetime2] NULL,
					CONSTRAINT [PK_'+@ShadowObjectName+'] PRIMARY KEY CLUSTERED 
					(
						[TransactionID] ASC
						, TranDate ASC
					) WITH (FILLFACTOR = 100, DATA_COMPRESSION = PAGE) ON ['+@FileGroupName+']
				) ON ['+@FileGroupName+']'
			)

			EXEC('
				CREATE UNIQUE NONCLUSTERED INDEX UNIX_'+@ShadowObjectName+'_Source ON '+@ShadowTableName+'
				(
					SourceTypeID
					, SourceID
					, TranDate
				)
				WITH (DATA_COMPRESSION = PAGE, FILLFACTOR=95)
			')

			EXEC('
				CREATE NONCLUSTERED INDEX NIX_'+@ShadowObjectName+'_FIFO_Earnings ON '+@ShadowTableName+'
				(
					[CustomerID] ASC,
					[TranDate] ASC,
					[ActivationDays] ASC,
					[TransactionID] ASC
				)
				INCLUDE([Earning],[PublisherID],[EarningSourceID],[PaymentMethodID],[PaymentCardID]) WITH (FILLFACTOR = 95)
			')

			EXEC ('
				CREATE NONCLUSTERED INDEX [NIX_'+@ShadowObjectName+'_EarningSource_Cover] ON '+@ShadowTableName+'
				(
					[EarningSourceID] ASC
				)
				INCLUDE([CustomerID],[PublisherID],[PaymentCardID],[Spend],[Earning],[PaymentMethodID],[EligibleDate],[SourceAddedDateTime]) WITH (FILLFACTOR = 90)
			')

			EXEC('
				CREATE NONCLUSTERED INDEX [NIX'+@ShadowObjectName+'_Offer_Cover] ON '+@ShadowTableName+'
				(
					[OfferID] ASC
				)
				INCLUDE([CustomerID],[PublisherID],[PaymentCardID],[Spend],[Earning],[PaymentMethodID],[EligibleDate],[SourceAddedDateTime]) WITH (FILLFACTOR = 90)
			')
			----------------------------------------------------------------------
			-- Disable constraints and switch partitions
			----------------------------------------------------------------------
		
			EXEC('ALTER TABLE '+@ShadowTableName+' NOCHECK CONSTRAINT ALL')
			-- EXEC('ALTER INDEX UNIX_'+@ShadowObjectName+'_Source ON Staging.Transactions_Migration DISABLE')


			EXEC('ALTER TABLE dbo.Transactions SWITCH PARTITION ' + @strPartitionNumber + ' TO ' + @ShadowTableName)

		END
		ELSE
		BEGIN
			SET @Continue = 0
		END
		----------------------------------------------------------------------
		-- Insert into shadow table
		----------------------------------------------------------------------
		EXEC('
			INSERT INTO '+@ShadowTableName+' WITH (TABLOCKX)
			(
				TransactionID
				, CustomerID
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
				NEXT VALUE FOR dbo.SEQ_TransactionID OVER (ORDER BY SourceTypeID, SourceID, TranDate) AS TransactionID
				, CustomerID
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
			FROM Staging.Transactions t
			WHERE TranDate >= '''+@strStartDate+''' 
				AND TranDate <= '''+@strEndDate+'''
				AND NOT EXISTS (
					SELECT 1
					FROM '+@ShadowTableName+' tx
					WHERE t.SourceID = tx.SourceID
						AND t.SourceTypeID = tx.SourceTypeID
				)
			ORDER BY TransactionID, TranDate

		')

		SET @Inserted += @@ROWCOUNT

		----------------------------------------------------------------------
		-- Log
		----------------------------------------------------------------------
		
		INSERT INTO WHB.Build_Log (RunID, StartDateTime, EndDateTime, StoredProcName, InsertedRows, UpdatedRows, DeletedRows)
		SELECT
			@RunID
			,@RunDateTime
			,GETDATE()
			,@StoredProcedureName + '_p' + @strPartitionNumber
			,InsertedRows = @Inserted
			,UpdatedRows = @Updated
			,DeletedRows = @Deleted

		----------------------------------------------------------------------
		-- Re-enable constraints and switch partition
		----------------------------------------------------------------------
		EXEC('ALTER TABLE '+@ShadowTableName+' WITH CHECK CHECK CONSTRAINT ALL')
		EXEC('ALTER TABLE '+@ShadowTableName+' SWITCH TO dbo.Transactions PARTITION ' + @strPartitionNumber)

		----------------------------------------------------------------------
		-- Drop Shadow table
		----------------------------------------------------------------------
		EXEC('DROP TABLE '+@ShadowTableName )

	END

	--TRUNCATE TABLE Staging.Transactions
END



