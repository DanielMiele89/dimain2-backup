/*
Migration CJM 01/09/2021 comment out create columnstore index
*/
CREATE PROCEDURE [Staging].[PartitionSwitching_CreateShadowTable_MyRewards] 
	(@strPartition VARCHAR(3), @ThisPartitionStartDate DATE, @NextPartitionStartDate DATE, @filegroup_name VARCHAR(100), @data_compression_desc VARCHAR(200))
	WITH EXECUTE AS OWNER
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

--DECLARE @data_compression_desc VARCHAR(200) = 'NONE'
DECLARE @data_compression_clause VARCHAR(200) = CASE WHEN @data_compression_desc = 'NONE' THEN '' ELSE 'DATA_COMPRESSION = PAGE, ' END

DECLARE @ShadowTable VARCHAR(200) = '[Relational].[ConsumerTransaction_MyRewards_p' + @strPartition + '_Stage]'
	
IF EXISTS(SELECT 1 FROM SYS.TABLES WHERE [Name] = 'ConsumerTransaction_MyRewards_p' + @StrPartition + '_Stage')
	EXEC('DROP TABLE ' + @ShadowTable)


--------------------------------------------------------------------------------------------------------------------------
-- Create the shadow table in the correct filegroup
--------------------------------------------------------------------------------------------------------------------------
EXEC ('
	CREATE TABLE ' + @ShadowTable + ' (
		[FileID] [int] NOT NULL,
		[RowNum] [int] NOT NULL,
		[ConsumerCombinationID] [int] NOT NULL,
		[CardholderPresentData] [tinyint] NOT NULL,
		[TranDate] [date] NOT NULL,
		[CINID] [int] NOT NULL,
		[Amount] [money] NOT NULL,
		[IsOnline] [bit] NOT NULL,
		[PaymentTypeID] [tinyint] NOT NULL,
		CONSTRAINT [PK_ConsumerTransaction_MyRewards_Stage_' + @strPartition + '] PRIMARY KEY NONCLUSTERED ([FileID] ASC, [RowNum] ASC, [TranDate] ASC) WITH (' + @data_compression_clause + 'FILLFACTOR = 80) ON [' + @filegroup_name + ']
	) ON [' + @filegroup_name + ']
')

--------------------------------------------------------------------------------------------------------------------------
-- Partition integrity constraint (shadow table only) - this ensures that rows inserted into the shadow table
-- are compatible with the destination partition. 
--------------------------------------------------------------------------------------------------------------------------
IF @StrPartition = '1' EXEC('ALTER TABLE ' + @ShadowTable + ' ADD CONSTRAINT CheckTranDate_R_p1 CHECK (TranDate < ''20110701'')')
IF @StrPartition > '1' EXEC('ALTER TABLE ' + @ShadowTable + ' ADD CONSTRAINT CheckTranDate_R_p' + @StrPartition + ' CHECK (TranDate >= ''' + @ThisPartitionStartDate + ''' AND TranDate < ''' + @NextPartitionStartDate + ''')')


--------------------------------------------------------------------------------------------------------------------------
-- Nonclustered indexes
--------------------------------------------------------------------------------------------------------------------------

EXEC('CREATE CLUSTERED INDEX [cx_CT] ON ' + @ShadowTable + ' ([TranDate] ASC,[CINID] ASC,[ConsumerCombinationID] ASC) WITH (' + @data_compression_clause + 'FILLFACTOR = 85)')
EXEC('CREATE INDEX [ix_Stuff01] ON ' + @ShadowTable + ' ([TranDate] ASC,[ConsumerCombinationID] ASC) INCLUDE ([Amount],[IsOnline],[CINID]) WITH (' + @data_compression_clause + 'FILLFACTOR = 80)')
EXEC('CREATE INDEX [ix_Stuff03] ON ' + @ShadowTable + ' ([ConsumerCombinationID] ASC, [TranDate] ASC) INCLUDE ([Amount],[IsOnline],[CINID]) WITH (' + @data_compression_clause + 'FILLFACTOR = 80)')

--EXEC('CREATE COLUMNSTORE INDEX [csx_Stuff] ON ' + @ShadowTable + ' ([TranDate], [CINID], [ConsumerCombinationID], [Amount], [IsOnline], paymenttypeid) WITH (DROP_EXISTING = OFF)')


RETURN 0