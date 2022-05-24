/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description: Updates the PackageLog table after a Source has been completed

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Monitor].[PackageLog_Update] (
	@RunID INT
  , @SourceID UNIQUEIDENTIFIER
  , @RowCnt INT
  , @PackageID UNIQUEIDENTIFIER
)
AS
BEGIN
	SET NOCOUNT ON

	----------------------------------------------------------------------
	-- Get the Run ID from log table for the package
	----------------------------------------------------------------------
	--SELECT
	--	@RunID = max(LatestRunID)
	--FROM Monitor.vw_PackageLog_LatestRunID
	--WHERE PackageID = @PackageID

	----------------------------------------------------------------------
	-- Update the log for this source
	----------------------------------------------------------------------
	;
	WITH LatestLog
	AS
	(
		SELECT TOP 1
			*
		FROM Monitor.Package_Log pls
		WHERE [pls].[RunID] = @RunID
			AND [pls].[SourceID] = @SourceID
			AND pls.PackageID = @PackageID
		ORDER BY pls.RunStartDateTime DESC
	)
	UPDATE LatestLog
	SET [Monitor].[Package_Log].[RunEndDateTime] = GETDATE()
	  , [Monitor].[Package_Log].[RowCnt] = NULLIF(@RowCnt, -1)
	WHERE [Monitor].[Package_Log].[RunID] = @RunID
		AND [Monitor].[Package_Log].[SourceID] = @SourceID
		AND [Monitor].[Package_Log].[PackageID] = @PackageID
		AND [Monitor].[Package_Log].[RunEndDateTime] IS NULL

	RETURN -1 -- Sets logging rowcount to -1 so that steps that do not require rowcount logging are set to NULL rather than 0

END