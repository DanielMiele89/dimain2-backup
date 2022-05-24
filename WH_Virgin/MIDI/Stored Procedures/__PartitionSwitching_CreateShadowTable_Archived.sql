CREATE PROCEDURE [MIDI].[__PartitionSwitching_CreateShadowTable_Archived] 
	(@NewPartition INT, @ThisPartitionStartDate DATE, @NextPartitionStartDate DATE, @NewMonthName VARCHAR(6))
	WITH EXECUTE AS OWNER
AS

BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	--------------------------------------------------------------------------------------------------------------------------
	-- Create the shadow table in the correct filegroup
	--------------------------------------------------------------------------------------------------------------------------
		CREATE TABLE [Trans].[ConsumerTransaction_p_Stage] (
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
		 CONSTRAINT [PK_Relational_ConsumerTransaction_p_Stage] PRIMARY KEY CLUSTERED 
		(
			[FileID] ASC,
			[RowNum] ASC,
			[TranDate] ASC
		) WITH (DATA_COMPRESSION = PAGE)
		) ON [fg_ConsumerTrans]
	
	
	--------------------------------------------------------------------------------------------------------------------------
	-- Partition integrity constraint (shadow table only) - this ensures that rows inserted into the shadow table
	-- are compatible with the destination partition. 
	--------------------------------------------------------------------------------------------------------------------------
	IF @NewPartition = '1' 
		ALTER TABLE [Trans].[ConsumerTransaction_p_Stage] ADD CONSTRAINT CheckTranDate_p CHECK (TranDate < '20110701')

	IF @NewPartition > '1' 
		EXEC('ALTER TABLE [Trans].[ConsumerTransaction_p_Stage] ADD CONSTRAINT CheckTranDate_p CHECK (TranDate >= ''' + @ThisPartitionStartDate + ''' AND TranDate < ''' + @NextPartitionStartDate + ''')')


	--------------------------------------------------------------------------------------------------------------------------
	-- Ordinary constraints
	--------------------------------------------------------------------------------------------------------------------------
	ALTER TABLE [Trans].[ConsumerTransaction_p_Stage] ADD  CONSTRAINT [DF_Relational_ConsumerTransaction_p_Stage_PaymentTypeID]  DEFAULT ((1)) FOR [PaymentTypeID]

	--EXEC('ALTER TABLE ' + @ShadowTable + ' WITH NOCHECK ADD  CONSTRAINT [FK_Relational_ConsumerTransaction_p' + @NewPartition + '_Stage_CardInputMode] FOREIGN KEY([InputModeID])
	--	REFERENCES [Relational].[CardInputMode] ([InputModeID])')
	--EXEC('ALTER TABLE ' + @ShadowTable + ' CHECK CONSTRAINT [FK_Relational_ConsumerTransaction_p' + @NewPartition + '_Stage_CardInputMode]')

	ALTER TABLE [Trans].[ConsumerTransaction_p_Stage] WITH NOCHECK ADD  CONSTRAINT [FK_Relational_ConsumerTransaction_p_Stage_Combination] FOREIGN KEY([ConsumerCombinationID])
		REFERENCES [Trans].[ConsumerCombination] ([ConsumerCombinationID])
	ALTER TABLE [Trans].[ConsumerTransaction_p_Stage] CHECK CONSTRAINT [FK_Relational_ConsumerTransaction_p_Stage_Combination]

	--EXEC('ALTER TABLE ' + @ShadowTable + ' WITH NOCHECK ADD  CONSTRAINT [FK_Relational_ConsumerTransaction_p' + @NewPartition + '_Stage_PostStatus] FOREIGN KEY([PostStatusID])
	--	REFERENCES [Relational].[PostStatus] ([PostStatusID])')
	--EXEC('ALTER TABLE ' + @ShadowTable + ' CHECK CONSTRAINT [FK_Relational_ConsumerTransaction_p' + @NewPartition + '_Stage_PostStatus]')


	--------------------------------------------------------------------------------------------------------------------------
	-- Nonclustered indexes
	--------------------------------------------------------------------------------------------------------------------------
	CREATE INDEX [IX_Relational_ConsumerTransaction_CINIDTranDateIncl_ForMissingTranQuery] ON [Trans].[ConsumerTransaction_p_Stage]
		(CINID ASC, TranDate ASC) INCLUDE (FileID, RowNum, ConsumerCombinationID, LocationID, Amount, IsOnline) WITH (DATA_COMPRESSION = PAGE)

	CREATE INDEX [IX_ConsumerTransaction_MainCover] ON [Trans].[ConsumerTransaction_p_Stage]
		(ConsumerCombinationID, TranDate, CINID, IsOnline, IsRefund, BankID, CardholderPresentData) INCLUDE (Amount) WITH (DATA_COMPRESSION = PAGE)

	CREATE COLUMNSTORE INDEX csx_Stuff ON [Trans].[ConsumerTransaction_p_Stage]
		(TranDate, CINID, ConsumerCombinationID, BankID, LocationID, Amount, IsRefund, IsOnline, CardholderPresentData, FileID, RowNum)

END

RETURN 0