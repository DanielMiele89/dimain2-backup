CREATE PROCEDURE [dbo].[Trans_CreateShadowTable] 
	 (@BoundaryIn DATE, @BoundaryOut DATE, @FileGroup VARCHAR(100))
	--WITH EXECUTE AS OWNER
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


IF (EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES 
	WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'TransShadow')) EXEC('DROP TABLE dbo.TransShadow');


EXEC('CREATE TABLE dbo.TransShadow (
		[TransSequenceID] [binary](32) NOT NULL,
		[ProxyUserID] [binary](32) NOT NULL,
		[PerturbedDate] [date] NOT NULL,
		[ProxyMIDTupleID] [binary](32) NOT NULL,
		[PerturbedAmount] [decimal](15, 8) NOT NULL,
		[CurrencyCode] [varchar](3) NOT NULL,
		[CardholderPresentFlag] [varchar](3) NOT NULL,
		[CardType] [varchar](10) NOT NULL,
		[CardholderPostcode] [varchar](10) NULL,
		[REW_TransSequenceID_INT] [decimal](10, 8) NOT NULL,
		[REW_FanID] [int] NOT NULL,
		[REW_SourceUID] [varchar](20) NOT NULL,
		[REW_TranDate] [date] NOT NULL,
		[REW_ConsumerCombinationID] [int] NOT NULL,
		[REW_Amount] [money] NULL,
		[REW_Variance] [decimal](12, 5) NOT NULL,
		[REW_RandomNumber] [decimal](7, 5) NOT NULL,
		[REW_FileID] [int] NOT NULL,
		[REW_RowNum] [int] NOT NULL,
		[REW_Prefix] [varchar](10) NULL,
		[REW_CardholderPresentData] [tinyint] NULL,
		[REW_CardholderPostcode] [varchar](5) NULL,
		[FileType] [varchar](10) NOT NULL,
		[FileDate] [date] NOT NULL,
		[CreatedDateTime] [datetime] NOT NULL,
	) ON ' + @FileGroup );

EXEC('CREATE UNIQUE CLUSTERED INDEX [cx_Transactions] ON dbo.TransShadow
	([REW_TranDate], [REW_FileID], [REW_RowNum])
	WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE, FILLFACTOR = 80)');

EXEC('ALTER TABLE dbo.TransShadow ADD CONSTRAINT TransCheckTranDate CHECK (REW_TranDate >= ''' + @BoundaryIn + ''' AND REW_TranDate < ''' + @BoundaryOut + ''')');


RETURN 0