

CREATE PROCEDURE [Prototype].[ConsumerTransaction_DD_Population]
AS
BEGIN

		SET NOCOUNT ON

		DECLARE	@FileID INT
			  , @LoopNumber INT = 1
			  , @FinalLoopNumber VARCHAR(10) = (SELECT COUNT(*) FROM Warehouse.Prototype.OINI_FileIDs WHERE AddedToFinalTable = 0)
			  , @StartDate DATE = GETDATE()
			  , @msg VARCHAR(250)
			  , @RowCount BIGINT
			  , @Start DATETIME
			  , @Seconds VARCHAR(10)
	
		WHILE EXISTS (SELECT 1 FROM Warehouse.Prototype.OINI_FileIDs WHERE AddedToFinalTable = 0 AND FileID < 14743) AND (SELECT CONVERT(DATE, GETDATE())) = @StartDate
		BEGIN
	
			SET @FileID = (SELECT MIN(FileID) FROM Prototype.OINI_FileIDs WHERE AddedToFinalTable = 0)
			SET @Start = GETDATE()
		
			INSERT INTO [Relational].[ConsumerTransaction_DD] ([FileID]
															 , [RowNum]
															 , [ConsumerCombinationID_DD]
															 , [TranDate]
															 , [BankAccountID]
															 , [FanID]
															 , [Amount])
			SELECT FileID
				 , RowNum
				 , ConsumerCombo_DD
				 , [Date]
				 , BankAccountID
				 , FanID
				 , Amount
			FROM Prototype.OINI_Trans dd
			WHERE FileID = @FileID	--	20391

			SET @RowCount = @@ROWCOUNT

			UPDATE Prototype.OINI_FileIDs
			SET AddedToFinalTable = 1
			WHERE FileID = @FileID

			SET @Seconds = CONVERT(VARCHAR(10), DATEDIFF(second, @Start, GETDATE()))
			SET @msg = LEFT(CONVERT(VARCHAR(10), @LoopNumber) + '   ', 4) + ' of ' +  @FinalLoopNumber + ' - ' + LEFT(CONVERT(VARCHAR(10), @RowCount) + '       ', 7) + ' rows inserted in ' + LEFT(CONVERT(VARCHAR(10), @Seconds) + '   ', 4) + ' seoconds'

			raiserror(@msg,0,1) with nowait

			SET @LoopNumber = @LoopNumber + 1

		END
	
		SET NOCOUNT OFF

END