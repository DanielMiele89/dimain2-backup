
/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description: Inserts rows into the PackageLog when a new SSIS task is started

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Monitor].[PackageLog_Insert] (
	@RunID INT 
  , @SourceID UNIQUEIDENTIFIER -- The sourceID as given from SSIS; the ID of the SSIS element
  , @SourceName NVARCHAR(100) -- The name of the source as written in the package
  , @PackageName NVARCHAR(100) -- The name of the Package to identify if the source is the package 
  , @PackageID UNIQUEIDENTIFIER -- The ID of the Package that initiated the run
)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @SourceTypeID INT

	----------------------------------------------------------------------
	-- When the SourceName and PackageName are the same, it means that this is
	-- the first step of the package i.e. it has just started so create a new RunID
	----------------------------------------------------------------------
	IF @SourceName = @PackageName
	BEGIN
		SELECT
			@RunID = NEXT VALUE FOR Monitor.Package_Log_RunID

		SET @SourceTypeID = 1

	END
	ELSE
	BEGIN
		-- Else get the source type id based on the name of the source
		--SELECT
		--	@RunID = MAX(LatestRunID)
		--FROM Monitor.vw_PackageLog_LatestRunID
		--WHERE PackageID = @PackageID

		SELECT @SourceTypeID = SourceTypeID
		FROM Monitor.Package_SourceType
		WHERE @SourceName LIKE MatchString

		SET @SourceTypeID = COALESCE(@SourceTypeID, 3) -- If doesn't match any string, set to Task type id

	END

	----------------------------------------------------------------------
	-- Insert
	----------------------------------------------------------------------
	INSERT INTO Monitor.Package_Log
	(
		RunID
	  , PackageID
	  , SourceID
	  , SourceName
	  , RunStartDateTime
	  , RunEndDateTime
	  , isError
	  , SourceTypeID
	  , RowCnt
	)

	 SELECT
		 @RunID
	   , @PackageID
	   , @SourceID
	   , @SourceName
	   , GETDATE()
	   , NULL
	   , 0
	   , @SourceTypeID
	   , NULL


	RETURN @RunID

END