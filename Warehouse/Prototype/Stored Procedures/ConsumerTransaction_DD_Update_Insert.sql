

CREATE PROCEDURE [Prototype].[ConsumerTransaction_DD_Update_Insert]
AS BEGIN


	DECLARE	@msg VARCHAR(250)
		  , @Start DATETIME
		  , @RowCount BIGINT
		  , @Seconds VARCHAR(10)
		  , @FileDate DATE
		  , @StartDate DATE = GETDATE()
		  , @LoopNumber INT = 1
		  , @FinalLoopNumber VARCHAR(10) = (SELECT COUNT(DISTINCT FileGroup) FROM Prototype.ConsumerTransaction_DD_Missing_RF_FileIDs WHERE Inserted = 0)

		WHILE EXISTS (SELECT 1 FROM Prototype.ConsumerTransaction_DD_Missing_RF_FileIDs WHERE Inserted = 0) AND (SELECT CONVERT(DATE, GETDATE())) = @StartDate
		BEGIN
	
			SET @Start = GETDATE()

			IF OBJECT_ID('tempdb..#FileIDsInsert') IS NOT NULL DROP TABLE #FileIDsInsert
			SELECT FileID
			INTO #FileIDsInsert
			FROM Prototype.ConsumerTransaction_DD_Missing_RF_FileIDs fi
			WHERE fi.FileGroup = @LoopNumber

			CREATE CLUSTERED INDEX CIX_FileID ON #FileIDsInsert (FileID)

			INSERT INTO Relational.ConsumerTransaction_DD
			SELECT *
			FROM Prototype.ConsumerTransaction_DD_Missing_RF ct
			WHERE EXISTS (SELECT 1
						  FROM #FileIDsInsert fi
						  WHERE ct.FileID = fi.FileID)

			SET @RowCount = @@ROWCOUNT


			UPDATE Prototype.ConsumerTransaction_DD_Missing_RF_FileIDs
			SET Inserted = 1
			WHERE FileGroup = @LoopNumber

			SET @Seconds = CONVERT(VARCHAR(10), DATEDIFF(second, @Start, GETDATE()))
			SET @msg = LEFT(CONVERT(VARCHAR(10), @LoopNumber) + ' ', 2) + ' of ' +  @FinalLoopNumber + ' - ' + LEFT(CONVERT(VARCHAR(10), @RowCount) + '       ', 7) + ' rows inserted in ' + LEFT(CONVERT(VARCHAR(10), @Seconds) + '   ', 4) + ' seconds'

			raiserror(@msg,0,1) with nowait

			SET @LoopNumber = @LoopNumber + 1

		END



END