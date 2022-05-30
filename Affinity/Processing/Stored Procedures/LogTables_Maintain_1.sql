
/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 23/09/2020
-- Description: Maintains the RowNum_Log table so that they do not grow too large.
				
				Removes fileids based on a cutoff time of when they were added
------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[LogTables_Maintain]
AS
BEGIN


	SET XACT_ABORT ON
	SET NOCOUNT ON
	----------------------------------------------------------------------
	-- Handle NFI Transactions
	-- Remove transaction ids before the cutoff
		-- the min transactionid after the cutoff could be kept, however, 
		-- nfi transactions are small in volume in comparison to FI
		-- so for consistency, they are kept so that the same logic can be
		-- used when querying for both types of transactions
	----------------------------------------------------------------------
	BEGIN TRANSACTION

	DECLARE @nFIRowsToRetain INT = 20000000 -- Number of Nfi Rows to retain for logging (20m based on 1 year of transactions)
		  , @MaxNFIRowNum INT -- The highest rownum available for nFI files to determine how much to remove
		  , @CutoffNFIRowNum INT -- The nFI RowNum to delete rows before


	SELECT
		@MaxNFIRowNum = MAX(RowNum)
	FROM Processing.RowNum_Log rnl
	WHERE rnl.FileID = -1


	IF @MaxNFIRowNum IS NOT NULL
	BEGIN
		SET @CutoffNFIRowNum = @MaxNFIRowNum - @nFIRowsToRetain

		DELETE
		FROM Processing.RowNum_Log
		WHERE FileID = -1
			AND RowNum < @CutoffNFIRowNum
	END

	COMMIT TRANSACTION

	----------------------------------------------------------------------
	-- Handle FI Transactions
		-- These NEED to be kept to maintain a log of FileID/RowNum that have been seen
		-- due to these being able to appear at any time 
		-- so only clear a subset of fileids according to cutoff logic
	----------------------------------------------------------------------

	DECLARE @FileWindow DATE = DATEADD(YEAR, -1, GETDATE()) -- the cut off point for file added dates
		  , @LoopIncrement INT = 20 -- how many files should be deleted in a batch
		  , @MinFileID INT -- The lowest fileid available after the cut off point
		  , @RowCount INT = 0 -- Number of files that were deleted

	-- Get FileIDs that are stored and are before the cut off point
	IF OBJECT_ID('tempdb..#RemovalFiles') IS NOT NULL
		DROP TABLE #RemovalFiles

	CREATE TABLE #RemovalFiles
	(
		ID	   INT IDENTITY (1, 1) NOT NULL
	  , FileID INT
	)

	INSERT INTO #RemovalFiles
	 SELECT DISTINCT
		 FileID
	 FROM Processing.RowNum_Log rnl
	 WHERE FileID < @MinFileID

	SELECT @RowCount = @@rowcount

	----------------------------------------------------------------------
	-- Loops to delete in the event that a large number of fileids ever need
	-- to be deleted due to this proc not being run
	----------------------------------------------------------------------
	DECLARE @LoopID INT = 1
		  , @LoopEnd INT

	SELECT
		@LoopEnd = MAX(ID)
	FROM #RemovalFiles rf

	WHILE @LoopID <= @LoopEnd
	BEGIN

		BEGIN TRANSACTION;

		DECLARE @LoopLimit INT = @LoopID + @LoopIncrement - 1

		IF OBJECT_ID('tempdb..#LoopFiles') IS NOT NULL
			DROP TABLE #LoopFiles

		SELECT
			rf.FileID
		INTO #LoopFiles
		FROM #RemovalFiles rf
		WHERE rf.ID BETWEEN @LoopID AND @LoopLimit

		DELETE rnl
		FROM Processing.RowNum_Log rnl
		JOIN #LoopFiles rf
			ON rnl.FileID = rf.FileID

		COMMIT TRANSACTION;

		CHECKPOINT;

		SET @LoopID = @LoopLimit + 1

	END

	RETURN @RowCount
END
