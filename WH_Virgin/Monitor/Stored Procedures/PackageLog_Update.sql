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
		WHERE RunID = @RunID
			AND SourceID = @SourceID
			AND pls.PackageID = @PackageID
		ORDER BY pls.RunStartDateTime DESC
	)
	UPDATE LatestLog
	SET RunEndDateTime = GETDATE()
	  , RowCnt = NULLIF(@RowCnt, -1)
	WHERE RunID = @RunID
		AND SourceID = @SourceID
		AND PackageID = @PackageID
		AND RunEndDateTime IS NULL

	RETURN -1 -- Sets logging rowcount to -1 so that steps that do not require rowcount logging are set to NULL rather than 0

END