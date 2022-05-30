

/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description: Perturbates and loads the MyRewards MIDI Holding Credit Transactions

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[TransactionPerturbation_MIDI_Credit_Load](
	@FileDate DATE -- The date that the file will be marked as produced
	, @FileType VARCHAR(10) -- The type of file that is being produced; no longer required for anything
)
AS
BEGIN

	SET XACT_ABORT ON

	DECLARE @RowCount INT -- Logging row count

	DECLARE @Prefix VARCHAR(2) = 'FI' -- Used for TransSequence Hashing to seperate systems (FI/nFI)
		, @TransTable [Processing].TransactionPerturbationType -- Table type that has the columns that are required for perturbation

	IF OBJECT_ID('tempdb..#Transactions') IS NOT NULL
		DROP TABLE #Transactions

	SELECT *
	INTO #Transactions
	FROM @TransTable

	----------------------------------------------------------------------
	-- First, create staging table of rows by inserting into @Table
	----------------------------------------------------------------------
	INSERT INTO #Transactions
	(
		FileID
	  , RowNum
	  , ConsumerCombinationID
	  , CardholderPresentData
	  , TranDate
	  , Amount
	  , FanID
	  , ProxyUserID
	  , ProxyMIDTupleID
	  , CurrencyCode
	  , CardholderPresentFlag
	  , CardType
	  , CardholderPostalArea
	  , SourceUID
	  , CardholderPostcodeDistrict
	  , TransSequenceID
	  , Prefix
	)
	 SELECT
		 ct.FileID
	   , ct.RowNum
	   , NULL															   AS ConsumerCombinationID
	   , ct.CardholderPresentData
	   , ct.TranDate
	   , ct.Amount
	   , c.FanID
	   , c.ProxyUserID													   AS ProxyUserID
	   , NULL															   AS ProxyMIDTupleID
	   , 'GBP'															   AS CurrencyCode
	   , cp.Recode														   AS CardholderPresentFlag
	   , 'C'															   AS CardType
	   , c.PostalArea													   AS CardholderPostalArea
	   , c.SourceUID													   AS SourceUID
	   , c.PostcodeDistrict												   AS CardholderPostcodeDistrict
	   , HASHBYTES('SHA2_256', CONCAT(@Prefix, ct.FileID, ',', ct.RowNum)) AS TransSequenceID
	   , @Prefix
	 FROM Processing.ConsumerTransactionHolding_MIDI_Credit ct
	 INNER JOIN Processing.Customers c
		 ON c.CINID = ct.CINID
			 AND c.rw = 1
	 INNER JOIN dbo.CardholderPresentData cp
		 ON cp.CardholderPresentData = ct.CardholderPresentData

	----------------------------------------------------------------------
	-- MIDI Transactions require some additional transformations so the output table needs to be created
	----------------------------------------------------------------------
	CREATE TABLE #TransactionPerturbation_Load
	(
		[TransSequenceID]			[BINARY](32)	 NOT NULL
	  , [ProxyUserID]				[BINARY](32)	 NOT NULL
	  , [PerturbedDate]				[DATE]			 NOT NULL
	  , [ProxyMIDTupleID]			[BINARY](32)	 NULL
	  , [PerturbedAmount]			[DECIMAL](15, 8) NOT NULL
	  , [CurrencyCode]				[VARCHAR](3)	 NOT NULL
	  , [CardholderPresentFlag]		[VARCHAR](3)	 NOT NULL
	  , [CardType]					[VARCHAR](10)	 NOT NULL
	  , [CardholderPostcode]		[VARCHAR](10)	 NULL
	  , [REW_TransSequenceID_INT]   [DECIMAL](10, 8) NOT NULL
	  , [REW_FanID]					[INT]			 NOT NULL
	  , [REW_SourceUID]				[VARCHAR](20)	 NOT NULL
	  , [REW_TranDate]				[DATE]			 NOT NULL
	  , [REW_ConsumerCombinationID] [INT]			 NULL
	  , [REW_Amount]				[MONEY]			 NULL
	  , [REW_Variance]				[DECIMAL](12, 5) NOT NULL
	  , [REW_RandomNumber]			[DECIMAL](7, 5)	 NOT NULL
	  , [REW_FileID]				[INT]			 NOT NULL
	  , [REW_RowNum]				[INT]			 NOT NULL
	  , [REW_Prefix]				[VARCHAR](10)	 NULL
	  , [REW_CardholderPresentData] [TINYINT]		 NULL
	  , [REW_CardholderPostcode]	[VARCHAR](5)	 NULL
	  , [FileType]					[VARCHAR](10)	 NOT NULL
	  , [FileDate]					[DATE]			 NOT NULL
	)

	----------------------------------------------------------------------
	-- Then, in a single transaction, log, perturbate and load transactions.
		-- This is to ensure that if there is an error, the tables will not be
		-- left in a half completed state
	----------------------------------------------------------------------
	BEGIN TRAN

		-- Perform insert
		INSERT INTO #TransactionPerturbation_Load
		(
			TransSequenceID
		  , ProxyUserID
		  , PerturbedDate
		  , ProxyMIDTupleID
		  , PerturbedAmount
		  , CurrencyCode
		  , CardholderPresentFlag
		  , CardType
		  , CardholderPostcode
		  , REW_TransSequenceID_INT
		  , REW_FanID
		  , REW_SourceUID
		  , REW_TranDate
		  , REW_ConsumerCombinationID
		  , REW_Amount
		  , REW_Variance
		  , REW_RandomNumber
		  , REW_FileID
		  , REW_RowNum
		  , REW_Prefix
		  , REW_CardholderPresentData
		  , REW_CardholderPostcode
		  , FileType
		  , FileDate
		)
		EXEC @RowCount = Processing.TransactionPerturbation_Fetch @FileDate = @FileDate
															  , @FileType = @FileType

		CREATE UNIQUE CLUSTERED INDEX ucix_tempdb_transpertload ON #TransactionPerturbation_Load (REW_FileID, REW_RowNum)

		-- Perform transformation according to spec and insert
		INSERT INTO Processing.TransactionPerturbation_MIDI
		(
			TransSequenceID
		  , ProxyUserID
		  , PerturbedDate
		  , ProxyMID
		  , MCC
		  , MerchantDescriptor
		  , CountryCode
		  , LocationAddress
		  , OriginatorID
		  , TempProxyMIDTupleID
		  , PerturbedAmount
		  , CurrencyCode
		  , CardholderPresentFlag
		  , CardType
		  , CardholderPostcode
		  , REW_TransSequenceID_INT
		  , REW_FanID
		  , REW_SourceUID
		  , REW_TranDate
		  , REW_Narrative
		  , REW_MID
		  , REW_Amount
		  , REW_Variance
		  , REW_RandomNumber
		  , REW_FileID
		  , REW_RowNum
		  , REW_Prefix
		  , REW_CardholderPresentData
		  , REW_CardholderPostcode
		  , REW_LocationID
		  , FileDate
		)
		 SELECT
			 tpl.TransSequenceID
		   , tpl.ProxyUserID
		   , tpl.PerturbedDate
		   , (
				 SELECT
					 CAST(cthmd.MID AS VARBINARY(MAX))
				 FOR XML PATH (''), BINARY BASE64
			 )
			 AS midbase64
		   , mcc.mcc
		   , LEFT(cthmd.Narrative, CASE WHEN cthmd.Narrative LIKE 'PAYPAL%' THEN 25 ELSE 16 END)
		   , cthmd.LocationCountry
		   , l.LocationAddress
		   , cthmd.OriginatorID
		   , CAST(HASHBYTES('SHA2_256', CONCAT(cthmd.MID, mcc.mcc, cthmd.Narrative, cthmd.LocationCountry, cthmd.OriginatorID)) AS BINARY(32))
		   , tpl.PerturbedAmount
		   , tpl.CurrencyCode
		   , tpl.CardholderPresentFlag
		   , tpl.CardType
		   , tpl.CardholderPostcode
		   , tpl.REW_TransSequenceID_INT
		   , tpl.REW_FanID
		   , tpl.REW_SourceUID
		   , tpl.REW_TranDate
		   , cthmd.Narrative
		   , cthmd.MID
		   , tpl.REW_Amount
		   , tpl.REW_Variance
		   , tpl.REW_RandomNumber
		   , tpl.REW_FileID
		   , tpl.REW_RowNum
		   , tpl.REW_Prefix
		   , tpl.REW_CardholderPresentData
		   , tpl.REW_CardholderPostcode
		   , cthmd.LocationID
		   , tpl.FileDate
		 FROM #TransactionPerturbation_Load tpl
		 JOIN Processing.ConsumerTransactionHolding_MIDI_Credit cthmd
			 ON tpl.REW_FileID = cthmd.FileID
				 AND tpl.REW_RowNum = cthmd.RowNum
		 JOIN Warehouse.Relational.MCCList mcc
			 ON mcc.MCCID = cthmd.MCCID
		 LEFT JOIN Warehouse.Relational.Location l
			 ON cthmd.LocationID = l.LocationID


	COMMIT TRAN


	RETURN @RowCount

END
