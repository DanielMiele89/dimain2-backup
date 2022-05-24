/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description: Logs errors that occur during a SSIS Package run

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Monitor].[PackageLog_Errors_Insert] (
    @RunID INT
  , @SourceID UNIQUEIDENTIFIER -- The sourceID as given from SSIS; the ID of the SSIS element
  , @ErrorDetails NVARCHAR(MAX) -- The details as provided by SSIS
  , @PackageID UNIQUEIDENTIFIER -- The ID of the Package that initiated the run
  , @ErrorCode INT -- The Error Code as provided by SSIS
)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	DECLARE @RunStartDateTime DATETIME -- The Start of this run

	----------------------------------------------------------------------
	-- Get the Run ID from log table for the package
	----------------------------------------------------------------------
	--SELECT
	--	@RunID = LatestRunID
	--FROM Monitor.vw_PackageLog_LatestRunID
	--WHERE PackageID = @PackageID

	----------------------------------------------------------------------
	-- Do in a single transaction to ensure the error table and log table match
	----------------------------------------------------------------------
	BEGIN TRAN
		
		-- Get latest RunStart of the souce for cases of loops
		SELECT TOP 1
			@RunStartDateTime = pls.RunStartDateTime
		FROM Monitor.Package_Log pls
		WHERE [pls].[RunID] = @RunID
			AND [pls].[SourceID] = @SourceID
			AND pls.PackageID = @PackageID
		ORDER BY pls.RunStartDateTime DESC

		-- Insert into Error table
		INSERT INTO Monitor.Package_Errors
		(
			[Monitor].[Package_Errors].[RunID]
		  , [Monitor].[Package_Errors].[PackageID]
		  , [Monitor].[Package_Errors].[SourceID]
		  , [Monitor].[Package_Errors].[RunStartDateTime]
		  , [Monitor].[Package_Errors].[ErrorDetails]
		  , [Monitor].[Package_Errors].[ErrorCode]
		)

		 SELECT
			 @RunID
		   , @PackageID
		   , @SourceID
		   , @RunStartDateTime
		   , @ErrorDetails
		   , @ErrorCode

		-- Update error flag on log table
		UPDATE Monitor.Package_Log
		SET [Monitor].[Package_Log].[isError] = 1
		  , [Monitor].[Package_Log].[RunEndDateTime] = GETDATE()
		WHERE [Monitor].[Package_Log].[RunID] = @RunID
			AND [Monitor].[Package_Log].[SourceID] = @SourceID
			AND [Monitor].[Package_Log].[RunStartDateTime] = @RunStartDateTime
			AND [Monitor].[Package_Log].[PackageID] = @PackageID
			AND [Monitor].[Package_Log].[RunEndDateTime] IS NULL

	COMMIT TRAN


END
