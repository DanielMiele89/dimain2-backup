/*
Migration CJM 01/09/2021 comment out create columnstore index
*/
create PROCEDURE [Staging].[PartitionSwitching_CreateShadowTable] 
	(@NewPartition INT, @ThisPartitionStartDate DATE, @NextPartitionStartDate DATE, @NewMonthName VARCHAR(6))
	WITH EXECUTE AS OWNER
AS

BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @ShadowTable VARCHAR(200) = '[Relational].[ConsumerTransaction_p' + CAST(@NewPartition AS VARCHAR(3)) + '_Stage]'


	--------------------------------------------------------------------------------------------------------------------------
	-- Create the shadow table in the correct filegroup
	--------------------------------------------------------------------------------------------------------------------------
	EXEC ('
		CREATE TABLE ' + @ShadowTable + ' (
			[FileID] [int] NOT NULL,
			[RowNum] [int] NOT NULL,
			[ConsumerCombinationID] [int] NOT NULL,
			[SecondaryCombinationID] [int] NULL,
			[BankID] [tinyint] NOT NULL,
			[LocationID] [int] NOT NULL,
			[CardholderPresentData] [tinyint] NOT NULL,
			[TranDate] [date] NOT NULL,
			[CINID] [int] NOT NULL,
			[Amount] [money] NOT NULL,
			[IsRefund] [bit] NOT NULL,
			[IsOnline] [bit] NOT NULL,
			[InputModeID] [tinyint] NOT NULL,
			[PostStatusID] [tinyint] NOT NULL,
			[PaymentTypeID] [tinyint] NOT NULL,
		 CONSTRAINT [PK_Relational_ConsumerTransaction_p' + @NewPartition + '_Stage] PRIMARY KEY CLUSTERED 
		(
			[FileID] ASC,
			[RowNum] ASC,
			[TranDate] ASC
		) WITH (DATA_COMPRESSION = PAGE)
		) ON [fgCTrans' + @NewMonthName + ']
	')


	--------------------------------------------------------------------------------------------------------------------------
	-- Partition integrity constraint (shadow table only) - this ensures that rows inserted into the shadow table
	-- are compatible with the destination partition. 
	--------------------------------------------------------------------------------------------------------------------------
	IF @NewPartition = '1' 
		EXEC('ALTER TABLE ' + @ShadowTable + ' ADD CONSTRAINT CheckTranDate_p1 CHECK (TranDate < ''20110701'')')

	IF @NewPartition > '1' 
		EXEC('ALTER TABLE ' + @ShadowTable + ' ADD CONSTRAINT CheckTranDate_p' + @NewPartition + ' CHECK (TranDate >= ''' + @ThisPartitionStartDate + ''' AND TranDate < ''' + @NextPartitionStartDate + ''')')


	--------------------------------------------------------------------------------------------------------------------------
	-- Ordinary constraints
	--------------------------------------------------------------------------------------------------------------------------
	EXEC('ALTER TABLE ' + @ShadowTable + ' ADD  CONSTRAINT [DF_Relational_ConsumerTransaction_p' + @NewPartition + '_Stage_PaymentTypeID]  DEFAULT ((1)) FOR [PaymentTypeID]')

	EXEC('ALTER TABLE ' + @ShadowTable + ' WITH NOCHECK ADD  CONSTRAINT [FK_Relational_ConsumerTransaction_p' + @NewPartition + '_Stage_CardInputMode] FOREIGN KEY([InputModeID])
		REFERENCES [Relational].[CardInputMode] ([InputModeID])')
	EXEC('ALTER TABLE ' + @ShadowTable + ' CHECK CONSTRAINT [FK_Relational_ConsumerTransaction_p' + @NewPartition + '_Stage_CardInputMode]')

	EXEC('ALTER TABLE ' + @ShadowTable + ' WITH NOCHECK ADD  CONSTRAINT [FK_Relational_ConsumerTransaction_p' + @NewPartition + '_Stage_Combination] FOREIGN KEY([ConsumerCombinationID])
		REFERENCES [Relational].[ConsumerCombination] ([ConsumerCombinationID])')
	EXEC('ALTER TABLE ' + @ShadowTable + ' CHECK CONSTRAINT [FK_Relational_ConsumerTransaction_p' + @NewPartition + '_Stage_Combination]')

	EXEC('ALTER TABLE ' + @ShadowTable + ' WITH NOCHECK ADD  CONSTRAINT [FK_Relational_ConsumerTransaction_p' + @NewPartition + '_Stage_PostStatus] FOREIGN KEY([PostStatusID])
		REFERENCES [Relational].[PostStatus] ([PostStatusID])')
	EXEC('ALTER TABLE ' + @ShadowTable + ' CHECK CONSTRAINT [FK_Relational_ConsumerTransaction_p' + @NewPartition + '_Stage_PostStatus]')


	--------------------------------------------------------------------------------------------------------------------------
	-- Nonclustered indexes
	--------------------------------------------------------------------------------------------------------------------------
	EXEC('CREATE INDEX [IX_Relational_ConsumerTransaction_CINIDTranDateIncl_ForMissingTranQuery] ON ' + @ShadowTable + '
		(CINID ASC, TranDate ASC) INCLUDE (FileID, RowNum, ConsumerCombinationID, LocationID, Amount, IsOnline) WITH (DATA_COMPRESSION = PAGE)')

	EXEC('CREATE INDEX [IX_ConsumerTransaction_MainCover] ON ' + @ShadowTable + '
		(ConsumerCombinationID, TranDate, CINID, IsOnline, IsRefund, BankID, CardholderPresentData) INCLUDE (Amount) WITH (DATA_COMPRESSION = PAGE)')

	--EXEC('CREATE COLUMNSTORE INDEX csx_Stuff ON ' + @ShadowTable + '
	--	(TranDate, CINID, ConsumerCombinationID, BankID, LocationID, Amount, IsRefund, IsOnline, CardholderPresentData, FileID, RowNum)')

END

RETURN 0