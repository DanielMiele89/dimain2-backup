/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description: Abstract stored procedure that takes a table of transactions and
				returns a perturbated set of transactions according to the specification

				#Transactions AS [Processing].TransactionPerturbationType

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[TransactionPerturbation_Fetch](
	@FileDate DATE -- The date that the file will be marked as produced
	, @FileType VARCHAR(10) -- The type of file that is being produced; no longer required for anything
)
AS
BEGIN

	DECLARE @RowCount INT -- Logging row count
		, @TableCount INT -- Count of rows in input table

	----------------------------------------------------------------------
	-- Log Rows that are to be perturbated (this will catch any duplicates)
		-- duplicates would only really happen if the process was run multiple times
		-- without the transaction tables being cleared between
	----------------------------------------------------------------------
	INSERT INTO Processing.RowNum_Log
	(
		FileID
	  , RowNum
	)

	 SELECT FileID, RowNum FROM #Transactions

	 SELECT @TableCount = @@RowCount

	----------------------------------------------------------------------
	-- Return perturbated rows
	----------------------------------------------------------------------
	;
	WITH MyRewards_Perturbation
	AS
	(
		SELECT
			ct.*
		  , x.PerturbedAmount
		  , q.Variance
		  , q.RandomNumber
		  , pd.PerturbedDate
		  , tid.TransSequenceID_INT
		FROM #Transactions ct
		CROSS APPLY (
			SELECT TOP (1)
				Variance
			  , [RandomNumber] = CAST(RAND(CHECKSUM(NEWID())) AS DECIMAL(6, 5))
			FROM dbo.TransactionVarianceMapping v
			WHERE ABS(ct.Amount) <= v.RangeTop
			ORDER BY RangeTop
		) q
		CROSS APPLY (-- Variance * lnFactor + TranAmount
			SELECT
				[PerturbedAmount] =
				CAST(
				CASE
					WHEN q.RandomNumber <= 0.00001 -- EDGE CASE 
					 THEN q.Variance * LOG(2 * 0.00001) + ct.Amount
					WHEN q.RandomNumber < 0.5
						AND q.RandomNumber > 0.00001 --Smaller than 0.5 - go up
					 THEN q.Variance * LOG(2 * q.RandomNumber) + ct.Amount
					WHEN q.RandomNumber >= 0.5
						AND q.RandomNumber < 0.99999 -- Greater than 0.5 - go down
					 THEN 0 - q.Variance * LOG(2 * (1 - q.RandomNumber)) + ct.Amount
					WHEN q.RandomNumber >= 0.99999 -- EDGE CASE
					 THEN 0 - q.Variance * LOG(2 * 0.00001) + ct.Amount
					ELSE 0
				END AS DECIMAL(15, 8))
		) x
		CROSS APPLY (
			SELECT
				TransSequenceID_INT = ((1.0 * CAST(ct.TransSequenceID AS INT)) % 5000) / 5000
		) tid
		CROSS APPLY (-- Perturbed Date
			SELECT
				[PerturbedDate] =
								 CASE
									 WHEN TransSequenceID_INT >= (1.0 * 5000 - 1) / 5000
									  THEN DATEADD(DAY, 5, TranDate)
									 WHEN TransSequenceID_INT >= (1.0 * 5000 - 50) / 5000
									  THEN DATEADD(DAY, 4, TranDate)
									 WHEN TransSequenceID_INT >= (1.0 * 5000 - 150) / 5000
									  THEN DATEADD(DAY, 3, TranDate)
									 WHEN TransSequenceID_INT >= (1.0 * 5000 - 1450) / 5000
									  THEN DATEADD(DAY, 2, TranDate)
									 WHEN TransSequenceID_INT >= (1.0 * 5000 - 3750) / 5000
									  THEN DATEADD(DAY, 1, TranDate)
									 WHEN TransSequenceID_INT <= -(1.0 * 5000 - 1) / 5000
									  THEN DATEADD(DAY, -5, TranDate)
									 WHEN TransSequenceID_INT <= -(1.0 * 5000 - 50) / 5000
									  THEN DATEADD(DAY, -4, TranDate)
									 WHEN TransSequenceID_INT <= -(1.0 * 5000 - 150) / 5000
									  THEN DATEADD(DAY, -3, TranDate)
									 WHEN TransSequenceID_INT <= -(1.0 * 5000 - 1450) / 5000
									  THEN DATEADD(DAY, -2, TranDate)
									 WHEN TransSequenceID_INT <= -(1.0 * 5000 - 3750) / 5000
									  THEN DATEADD(DAY, -1, TranDate)
									 ELSE TranDate
								 END
		) pd
	)
	 SELECT
		 ct.TransSequenceID			   AS TransSequenceID
	   , ct.ProxyUserID				   AS ProxyUserID
	   , ct.PerturbedDate			   AS PerturbedDate
	   , ct.ProxyMIDTupleID			   AS ProxyMIDTupleID
	   , ct.PerturbedAmount			   AS PerturbedAmount
	   , ct.CurrencyCode			   AS CurrencyCode
	   , ct.CardholderPresentFlag	   AS CardholderPresentFlag
	   , ct.CardType				   AS CardType
	   , ct.CardholderPostalArea	   AS CardholderPostcode
	   , ct.TransSequenceID_INT		   AS REW_TransSequenceID_INT
	   , ct.FanID					   AS REW_FanID
	   , ct.SourceUID				   AS REW_SourceUID
	   , ct.TranDate				   AS REW_TranDate
	   , ct.ConsumerCombinationID	   AS REW_ConsumerCombinationID
	   , ct.Amount					   AS REW_Amount
	   , ct.Variance				   AS REW_Variance
	   , ct.RandomNumber			   AS REW_RandomNumber
	   , ct.FileID					   AS REW_FileID
	   , ct.RowNum					   AS REW_RowNum
	   , ct.Prefix					   AS REW_prefix
	   , ct.CardholderPresentData	   AS REW_CardholderPresentData
	   , ct.CardholderPostcodeDistrict AS REW_CardholderPostcode
	   , @FileType					   AS FileType
	   , @FileDate				       AS FileDate
	 FROM MyRewards_Perturbation ct


	SELECT @RowCount = @@ROWCOUNT

	----------------------------------------------------------------------
	-- Logic to handle cases where rows come in but rows don't go out
	----------------------------------------------------------------------
	IF @TableCount >0 AND @RowCount = 0
		THROW 51234
			, 'The table has rows but it appears that none were perturbated'
			, 1

	IF @TableCount <> @RowCount
		THROW 52345
			, 'The number of rows provided were different to the number of rows that were perturbated.  Only table that is used is the TransactionVarianceMapping, is there a problem with this?'
			, 1

	RETURN @RowCount


END
