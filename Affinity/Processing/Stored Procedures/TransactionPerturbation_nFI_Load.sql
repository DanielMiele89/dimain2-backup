

/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description: Perturbates and loads the MyRewards nFI Transactions

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/

CREATE PROCEDURE [Processing].[TransactionPerturbation_nFI_Load](
	@FileDate DATE
  , @FileType VARCHAR(10)
)
AS
BEGIN

	DECLARE @RowCount INT -- Logging row count

	DECLARE @FileID INT = -1 -- nFIs do not have a FileID and are set to -1, TranID then becomes RowNum
		  , @Prefix VARCHAR(3) = 'nFI' -- Used for TransSequence Hashing to seperate systems (FI/nFI)
		, @TransTable [Processing].TransactionPerturbationType -- Table type that has the columns that are required for perturbation


	IF OBJECT_ID('tempdb..#Transactions') IS NOT NULL
		DROP TABLE #Transactions

	SELECT *
	INTO #Transactions
	FROM @TransTable

	SET XACT_ABORT ON

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
		 @FileID
	   , ct.TranID													AS RowNum
	   , cc.ConsumerCombinationID
	   , ct.CardholderPresentData
	   , ct.TranDate
	   , ct.Amount
	   , c.FanID
	   , c.ProxyUserID												AS ProxyUserID
	   , cc.ProxyMIDTupleID												AS ProxyMIDTupleID
	   , 'GBP'														AS CurrencyCode
	   , cp.Recode													AS CardholderPresentFlag
		, CASE WHEN 
			CardTypeID = 2 THEN 
				'D' 
			WHEN CardTypeID = 1 THEN 
				'C' 
			ELSE 'U' 
			END														AS CardType														
	   , c.PostalArea												AS CardholderPostalArea
	   , c.SourceUID												AS SourceUID
	   , c.PostcodeDistrict											AS CardholderPostcodeDistrict
	   , HASHBYTES('SHA2_256', CONCAT(@Prefix, @FileID, ct.TranID)) AS TransSequenceID
	   , @Prefix
	 FROM Processing.ConsumerTransactionHolding_nFI ct
	 INNER JOIN Processing.Customers c
		 ON c.CompositeID = ct.CompositeID
	 INNER JOIN Processing.ConsumerCombination cc
		 ON cc.MID = ct.MerchantID
			 AND cc.BrandID = ct.BrandID
			 AND cc.RowNum = 1
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

	RETURN @Rowcount

END
