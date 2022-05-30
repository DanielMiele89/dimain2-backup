

/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description:	Extracts a manifest file based on the number of rows available and
				the number of rows that should be in each file i.e. 1000 total rows
				in batches of 100 would make a manifest that listed 10 files.

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[FileExtraction_Manifest_Fetch](
	@BatchSize INT -- the size of the batch required
  , @FilePattern VARCHAR(100) -- The main file pattern -- this will be appened with the part
  , @TotalRows INT -- The total number of rows that are available in the file
  , @FileExtension VARCHAR(4) = 'gz' -- the extension to add to the end of each file

)
AS
BEGIN

	SET @FileExtension =
						CASE
							WHEN LEFT(RTRIM(LTRIM(@FileExtension)), 1) <> '.'
							 THEN '.' + @FileExtension
							ELSE @FileExtension
						END

	;
	WITH FileParts
	AS
	(
		SELECT
			0		   AS ID
		  , @TotalRows AS TotalRows

		UNION ALL

		SELECT
			ID + 1
		  , TotalRows - @BatchSize
		FROM FileParts
		WHERE TotalRows > 0
	)
	SELECT
		@FilePattern + '.' + RIGHT('00' + CAST(ID AS VARCHAR(4)), 3) + @FileExtension AS fName
	FROM FileParts
	WHERE ID > 0
END
