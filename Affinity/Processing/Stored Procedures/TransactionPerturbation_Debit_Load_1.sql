/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description: Perturbates and loads the MyRewards Debit Transactions

				Final Transactions for: YYYY_MM_DD-Daily.csv

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[TransactionPerturbation_Debit_Load]  
(
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
		, ct.ConsumerCombinationID
		, ct.CardholderPresentData
		, ct.TranDate
		, ct.Amount
		, c.FanID
		, c.ProxyUserID							AS ProxyUserID
		, cc.ProxyMIDTupleID							AS ProxyMIDTupleID
		, 'GBP'									AS CurrencyCode
		, cp.Recode								AS CardholderPresentFlag
		, CASE WHEN 							
			ct.PaymentTypeID = 1 THEN 			
				'D' 						
			WHEN ct.PaymentTypeID = 2 THEN 		
				'C' 						
			ELSE 'U' 						
		END										AS CardType
		, c.PostalArea							AS CardholderPostalArea
		, c.SourceUID							AS SourceUID
		, c.PostcodeDistrict					AS CardholderPostcodeDistrict
		, HASHBYTES('SHA2_256', CONCAT(@Prefix, ct.FileID, ',', ct.RowNum)) AS TransSequenceID
		, @Prefix
	FROM Processing.ConsumerTransactionHolding_Debit ct 
	INNER JOIN Processing.Customers c
		ON c.CINID = ct.CINID
		AND c.rw = 1
	INNER JOIN Processing.ConsumerCombination cc 
		ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
	INNER JOIN dbo.CardholderPresentData cp
		ON cp.CardholderPresentData = ct.CardholderPresentData

	----------------------------------------------------------------------
	-- Then, in a single transaction, log, perturbate and load transactions.
		-- This is to ensure that if there is an error, the tables will not be
		-- left in a half completed state
	----------------------------------------------------------------------
	BEGIN TRAN

		INSERT INTO Processing.TransactionPerturbation
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
		EXEC @Rowcount = Processing.TransactionPerturbation_Fetch @FileDate = @FileDate
															  , @FileType = @FileType

	COMMIT TRAN

	RETURN @RowCount
	 
END 


