/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description: Logs errors that occur during a SSIS Package run

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[PackageLog_Errors_Insert] (
	@SourceID UNIQUEIDENTIFIER -- The sourceID as given from SSIS; the ID of the SSIS element
  , @ErrorDetails NVARCHAR(MAX) -- The details as provided by SSIS
  , @PackageID UNIQUEIDENTIFIER -- The ID of the Package that initiated the run
  , @ErrorCode INT -- The Error Code as provided by SSIS
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	DECLARE @RunID INT -- The RunID of this run
		  , @RunStartDateTime DATETIME -- The Start of this run

	----------------------------------------------------------------------
	-- Get the Run ID from log table for the package
	----------------------------------------------------------------------
	SELECT
		@RunID = LatestRunID
	FROM Processing.vw_PackageLog_LatestRunID
	WHERE PackageID = @PackageID

	----------------------------------------------------------------------
	-- Do in a single transaction to ensure the error table and log table match
	----------------------------------------------------------------------
	BEGIN TRAN
		
		-- Get latest RunStart of the souce for cases of loops
		SELECT TOP 1
			@RunStartDateTime = pls.RunStartDateTime
		FROM Processing.Package_Log pls
		WHERE RunID = @RunID
			AND SourceID = @SourceID
			AND pls.PackageID = @PackageID
		ORDER BY pls.RunStartDateTime DESC

		-- Insert into Error table
		INSERT INTO Processing.Package_Errors
		(
			RunID
		  , PackageID
		  , SourceID
		  , RunStartDateTime
		  , ErrorDetails
		  , ErrorCode
		)

		 SELECT
			 @RunID
		   , @PackageID
		   , @SourceID
		   , @RunStartDateTime
		   , @ErrorDetails
		   , @ErrorCode

		-- Update error flag on log table
		UPDATE Processing.Package_Log
		SET isError = 1
		  , RunEndDateTime = GETDATE()
		WHERE RunID = @RunID
			AND SourceID = @SourceID
			AND RunStartDateTime = @RunStartDateTime
			AND PackageID = @PackageID

	COMMIT TRAN


END
