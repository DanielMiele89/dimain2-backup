

CREATE PROCEDURE [Relational].[Archived_CTDDL_InsertToFinalTable]
AS
BEGIN

	SET NOCOUNT ON

	/*******************************************************************************************************************************************
		1. Declare variables
	*******************************************************************************************************************************************/
	 
			BEGIN TRY

					INSERT INTO [Relational].[ConsumerTransaction_DD] ([FileID]
																	 , [RowNum]
																	 , [ConsumerCombinationID_DD]
																	 , [TranDate]
																	 , [BankAccountID]
																	 , [FanID]
																	 , [Amount])
					SELECT [FileID]
						 , [RowNum]
						 , [ConsumerCombinationID_DD]
						 , [TranDate]
						 , [BankAccountID]
						 , [FanID]
						 , [Amount]
					FROM [Staging].[ConsumerTransaction_DD_Holding]

					INSERT INTO [Relational].[ConsumerTransaction_DD_MyRewards] ([FileID]
																			   , [RowNum]
																			   , [ConsumerCombinationID_DD]
																			   , [TranDate]
																			   , [BankAccountID]
																			   , [FanID]
																			   , [Amount])
					SELECT [FileID]
						 , [RowNum]
						 , [ConsumerCombinationID_DD]
						 , [TranDate]
						 , [BankAccountID]
						 , [FanID]
						 , [Amount]
					FROM [Staging].[ConsumerTransaction_DD_Holding] ct
					WHERE EXISTS (SELECT 1
								  FROM [SLC_Report].[dbo].[IssuerBankAccount] iba
								  INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
									ON iba.IssuerCustomerID = ic.ID
								  INNER JOIN Relational.Customer cu
									ON ic.SourceUID = cu.SourceUID
								  WHERE iba.CustomerStatus = 1
								  AND ct.BankAccountID = iba.BankAccountID)
	
			END TRY

			BEGIN CATCH

				IF OBJECT_ID('tempdb..#FileIDs') IS NOT NULL DROP TABLE #FileIDs
				SELECT DISTINCT
					   FileID
				INTO #FileIDs
				FROM Staging.ConsumerTransaction_DD_Holding ct

				CREATE CLUSTERED INDEX CIX_FileID ON #FileIDs (FileID)

				DELETE ct
				FROM [Relational].[ConsumerTransaction_DD] ct
				WHERE EXISTS (SELECT 1
							  FROM #FileIDs fi
							  WHERE ct.FileID = fi.FileID)

				DELETE ct
				FROM [Relational].[ConsumerTransaction_DD_MyRewards] ct
				WHERE EXISTS (SELECT 1
							  FROM #FileIDs fi
							  WHERE ct.FileID = fi.FileID)
			END CATCH


END


