CREATE PROCEDURE [Staging].[PartitionSwitching_CreateShadowTable_CJM] 
	(@strPartition VARCHAR(3), @ThisPartitionStartDate DATE, @NextPartitionStartDate DATE, @filegroup_name VARCHAR(100), @data_compression_desc VARCHAR(200))
	WITH EXECUTE AS OWNER
AS

BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @ShadowTable VARCHAR(200) = '[Relational].[ConsumerTransaction_p' + @strPartition + '_Stage]'


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
			[Currency] CHAR(3) NULL,
		 CONSTRAINT [PK_Relational_ConsumerTransaction_p' + @strPartition + '_Stage] PRIMARY KEY CLUSTERED 
		(
			[FileID] ASC,
			[RowNum] ASC,
			[TranDate] ASC
		) WITH (DATA_COMPRESSION = PAGE)
		) ON [' + @filegroup_name + ']
	')


	--------------------------------------------------------------------------------------------------------------------------
	-- Partition integrity constraint (shadow table only) - this ensures that rows inserted into the shadow table
	-- are compatible with the destination partition. 
	--------------------------------------------------------------------------------------------------------------------------
	IF @strPartition = '1' 
		EXEC('ALTER TABLE ' + @ShadowTable + ' ADD CONSTRAINT CheckTranDate_p1 CHECK (TranDate < ''20110701'')')

	IF @strPartition > '1' 
		EXEC('ALTER TABLE ' + @ShadowTable + ' ADD CONSTRAINT CheckTranDate_p' + @strPartition + ' CHECK (TranDate >= ''' + @ThisPartitionStartDate + ''' AND TranDate < ''' + @NextPartitionStartDate + ''')')


	--------------------------------------------------------------------------------------------------------------------------
	-- Ordinary constraints
	--------------------------------------------------------------------------------------------------------------------------
	EXEC('ALTER TABLE ' + @ShadowTable + ' ADD  CONSTRAINT [DF_Relational_ConsumerTransaction_p' + @strPartition + '_Stage_PaymentTypeID]  DEFAULT ((1)) FOR [PaymentTypeID]')

	EXEC('ALTER TABLE ' + @ShadowTable + ' WITH NOCHECK ADD  CONSTRAINT [FK_Relational_ConsumerTransaction_p' + @strPartition + '_Stage_CardInputMode] FOREIGN KEY([InputModeID])
		REFERENCES [Relational].[CardInputMode] ([InputModeID])')
	EXEC('ALTER TABLE ' + @ShadowTable + ' CHECK CONSTRAINT [FK_Relational_ConsumerTransaction_p' + @strPartition + '_Stage_CardInputMode]')

	EXEC('ALTER TABLE ' + @ShadowTable + ' WITH NOCHECK ADD  CONSTRAINT [FK_Relational_ConsumerTransaction_p' + @strPartition + '_Stage_Combination] FOREIGN KEY([ConsumerCombinationID])
		REFERENCES [Relational].[ConsumerCombination] ([ConsumerCombinationID])')
	EXEC('ALTER TABLE ' + @ShadowTable + ' CHECK CONSTRAINT [FK_Relational_ConsumerTransaction_p' + @strPartition + '_Stage_Combination]')

	EXEC('ALTER TABLE ' + @ShadowTable + ' WITH NOCHECK ADD  CONSTRAINT [FK_Relational_ConsumerTransaction_p' + @strPartition + '_Stage_PostStatus] FOREIGN KEY([PostStatusID])
		REFERENCES [Relational].[PostStatus] ([PostStatusID])')
	EXEC('ALTER TABLE ' + @ShadowTable + ' CHECK CONSTRAINT [FK_Relational_ConsumerTransaction_p' + @strPartition + '_Stage_PostStatus]')


	--------------------------------------------------------------------------------------------------------------------------
	-- Nonclustered indexes
	--------------------------------------------------------------------------------------------------------------------------
	EXEC('CREATE INDEX [IX_Relational_ConsumerTransaction_CINIDTranDateIncl_ForMissingTranQuery] ON ' + @ShadowTable + '
		(CINID ASC, TranDate ASC) INCLUDE (FileID, RowNum, ConsumerCombinationID, LocationID, Amount, IsOnline) WITH (DATA_COMPRESSION = PAGE)')

	EXEC('CREATE INDEX [IX_ConsumerTransaction_MainCover] ON ' + @ShadowTable + '
		(ConsumerCombinationID, TranDate, CINID, IsOnline, IsRefund, BankID, CardholderPresentData) INCLUDE (Amount) WITH (DATA_COMPRESSION = PAGE)')

	EXEC('CREATE COLUMNSTORE INDEX csx_Stuff ON ' + @ShadowTable + '
		(TranDate, CINID, ConsumerCombinationID, BankID, LocationID, Amount, IsRefund, IsOnline, CardholderPresentData, FileID, RowNum)')

END

RETURN 0