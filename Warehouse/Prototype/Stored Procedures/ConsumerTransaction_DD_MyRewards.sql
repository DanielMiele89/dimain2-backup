

CREATE PROCEDURE [Prototype].[ConsumerTransaction_DD_MyRewards]
AS
BEGIN

		SET NOCOUNT ON

		DECLARE	@FileID INT
			  , @LoopID INT
			  , @LoopNumber INT = 1
			  , @FinalLoopNumber VARCHAR(10) = (SELECT COUNT(DISTINCT LoopID) FROM Warehouse.Prototype.OINI_Files WHERE AddedToTable = 0)
			  , @StartDate DATE = GETDATE()
			  , @msg VARCHAR(250)
			  , @RowCount BIGINT
			  , @Start DATETIME
			  , @Seconds VARCHAR(10)

		WHILE EXISTS (SELECT 1 FROM Warehouse.Prototype.OINI_Files WHERE AddedToTable = 0) AND (SELECT CONVERT(DATE, GETDATE())) = @StartDate
		BEGIN
	
			SET @Start = GETDATE()
			SET @LoopID = (SELECT MAX(LoopID) FROM Prototype.OINI_Files WHERE AddedToTable = 0)
			
			IF OBJECT_ID('tempdb..#FileIDs') IS NOT NULL DROP TABLE #FileIDs
			SELECT FileID
			INTO #FileIDs
			FROM Prototype.OINI_Files
			WHERE AddedToTable = 0
			AND LoopID = @LoopID

			CREATE CLUSTERED INDEX CIX_File ON #FileIDs (FileID)


			--	DECLARE	@FileID INT = 20028

			IF OBJECT_ID('tempdb..#TransactionHistory') IS NOT NULL DROP TABLE #TransactionHistory
			SELECT [FileID]
				 , [RowNum]
				 , [Amount]
				 , [TranDate]
				 , [BankAccountID]
				 , [FanID]
				 , [ConsumerCombinationID_DD]
			INTO #TransactionHistory
			FROM [Relational].[ConsumerTransaction_DD] ct
			WHERE EXISTS (SELECT 1
						  FROM #FileIDs fi
						  WHERE ct.[FileID] = fi.[FileID])
			AND EXISTS (SELECT 1
						FROM Prototype.OINI_MyRewardsBankAccounts mr
						WHERE ct.BankAccountID = mr.BankAccountID)

			SET @RowCount = @@ROWCOUNT

			INSERT INTO #TransactionHistory
			SELECT [FileID]
				 , [RowNum]
				 , [Amount]
				 , [Date]
				 , [BankAccountID]
				 , [FanID]
				 , [ConsumerCombinationID_DD]
			FROM [Staging].[ConsumerTransaction_DD_EntriesMissingFanID] ct
			WHERE EXISTS (SELECT 1
						  FROM #FileIDs fi
						  WHERE ct.[FileID] = fi.[FileID])
			AND EXISTS (SELECT 1
						FROM Prototype.OINI_MyRewardsBankAccounts mr
						WHERE ct.BankAccountID = mr.BankAccountID)

			SET @RowCount = @RowCount + @@ROWCOUNT

			INSERT INTO [Relational].[ConsumerTransaction_DD_MyRewards]
			SELECT DISTINCT
				   [FileID]
				 , [RowNum]
				 , [Amount]
				 , [TranDate]
				 , [BankAccountID]
				 , [FanID]
				 , [ConsumerCombinationID_DD]
			FROM #TransactionHistory th

			UPDATE Prototype.OINI_Files
			SET AddedToTable = 1
			WHERE FileID IN (SELECT FileID FROM  #FileIDs)

			SET @Seconds = CONVERT(VARCHAR(10), DATEDIFF(second, @Start, GETDATE()))
			SET @msg = LEFT(CONVERT(VARCHAR(10), @LoopNumber) + '   ', 4) + ' of ' +  @FinalLoopNumber + ' - ' + LEFT(CONVERT(VARCHAR(10), @RowCount) + '       ', 7) + ' rows updated in ' + LEFT(CONVERT(VARCHAR(10), @Seconds) + '   ', 4) + ' seconds'

			raiserror(@msg,0,1) with nowait

			SET @LoopNumber = @LoopNumber + 1

		END
	
		SET NOCOUNT OFF

END