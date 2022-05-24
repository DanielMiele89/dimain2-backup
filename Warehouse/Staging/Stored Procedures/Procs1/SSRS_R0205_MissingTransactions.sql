
CREATE PROCEDURE [Staging].[SSRS_R0205_MissingTransactions] (@CIN VARCHAR(50)
														  , @SDate DATE
														  , @EDate DATE)
AS
BEGIN

	SET NOCOUNT ON;

	/*******************************************************************************************************************************************
		1. Declare variables and fetch customer CINID
	*******************************************************************************************************************************************/

		--DECLARE @CIN VARCHAR(50) = '1281853414'
		--	  , @SDate DATE = '2019-05-01'
		--	  , @EDate DATE = GETDATE()

			 
		DECLARE @SourceUID VARCHAR(50) = @CIN
			  , @StartDate DATE = @SDate
			  , @EndDate DATE = @EDate
			  , @CINID BIGINT

		SELECT @CINID = CINID
		FROM [Relational].[CINList] cl
		WHERE NOT EXISTS (SELECT 1 FROM [Staging].[Customer_DuplicateSourceUID] cdsu WHERE cl.CIN != @SourceUID)
		AND cl.CIN = @SourceUID


	/*******************************************************************************************************************************************
		2. Fetch all transactions
	*******************************************************************************************************************************************/

		/***********************************************************************************************************************
			2.1. Fetch all debit transactions
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#ConsumerTrans_Debit') IS NOT NULL DROP TABLE #ConsumerTrans_Debit
			SELECT *
			INTO #ConsumerTrans_Debit
			FROM [Relational].[ConsumerTransaction]
			WHERE CINID = @CINID
			AND TranDate BETWEEN @StartDate AND @EndDate


		/***********************************************************************************************************************
			2.2. Fetch all credit transactions
		***********************************************************************************************************************/

			IF OBJECT_ID('tempdb..#ConsumerTrans_Credit') IS NOT NULL DROP TABLE #ConsumerTrans_Credit
			SELECT *
			INTO #ConsumerTrans_Credit
			FROM [Relational].[ConsumerTransaction_CreditCard]
			WHERE CINID = @CINID
			AND TranDate BETWEEN @StartDate AND @EndDate


		/***********************************************************************************************************************
			2.3. Combine both transaction types
		***********************************************************************************************************************/
		
			IF OBJECT_ID('tempdb..#ConsumerTrans') IS NOT NULL DROP TABLE #ConsumerTrans
			SELECT FileID
				 , RowNum
				 , ConsumerCombinationID
				 , CINID
				 , Amount
				 , 'Debit' AS TransactionType
			INTO #ConsumerTrans
			FROM #ConsumerTrans_Debit
			UNION ALL
			SELECT FileID
				 , RowNum
				 , ConsumerCombinationID
				 , CINID
				 , Amount
				 , 'Credit' AS TransactionType
			FROM #ConsumerTrans_Credit

			CREATE CLUSTERED INDEX CIX_CCID ON #ConsumerTrans (ConsumerCombinationID)

			



END