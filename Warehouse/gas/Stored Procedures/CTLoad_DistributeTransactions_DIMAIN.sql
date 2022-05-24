-- =============================================
-- Author:		RF
-- Create date: 2020-06-18
-- Description:	Distributes new transactions to either ConsumerTransactionHolding or CTLoad_MIDIHolding
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_DistributeTransactions_DIMAIN]
AS
BEGIN
	
	SET NOCOUNT ON;

	--Unresolved
    INSERT INTO [Staging].[CTLoad_MIDIHolding] (FileID
											  , RowNum
											  , BankID
											  , MID
											  , Narrative
											  , LocationAddress
											  , LocationCountry
											  , CardholderPresentData
											  , TranDate
											  , CINID
											  , Amount
											  , IsOnline
											  , IsRefund
											  , OriginatorID
											  , MCCID
											  , PostStatusID
											  , LocationID
											  , ConsumerCombinationID
											  , SecondaryCombinationID
											  , InputModeID
											  , PaymentTypeID)
	SELECT FileID
		 , RowNum
		 , BankID
		 , MID
		 , Narrative
		 , LocationAddress
		 , LocationCountry
		 , CardholderPresentData
		 , TranDate
		 , CINID
		 , Amount
		 , IsOnline
		 , IsRefund
		 , OriginatorID
		 , MCCID
		 , PostStatusID
		 , LocationID
		 , ConsumerCombinationID
		 , SecondaryCombinationID
		 , InputModeID
		 , PaymentTypeID
	FROM [Staging].[CTLoad_InitialStage]
	WHERE CINID IS NOT NULL
	AND (ConsumerCombinationID IS NULL OR LocationID IS NULL)
	
	--	Ready
	INSERT INTO [Relational].[ConsumerTransactionHolding] (FileID
														 , RowNum
														 , ConsumerCombinationID
														 , SecondaryCombinationID
														 , BankID
														 , LocationID
														 , CardholderPresentData
														 , TranDate
														 , CINID
														 , Amount
														 , IsRefund
														 , IsOnline
														 , InputModeID
														 , PostStatusID
														 , PaymentTypeID)
    SELECT FileID
		 , RowNum
		 , ConsumerCombinationID
		 , SecondaryCombinationID
		 , BankID
		 , LocationID
		 , CardholderPresentData
		 , TranDate
		 , CINID
		 , Amount
		 , IsRefund
		 , IsOnline
		 , InputModeID
		 , PostStatusID
		 , PaymentTypeID
	FROM [Staging].[CTLoad_InitialStage]
	WHERE CINID IS NOT NULL
	AND ConsumerCombinationID IS NOT NULL
	AND LocationID IS NOT NULL

END