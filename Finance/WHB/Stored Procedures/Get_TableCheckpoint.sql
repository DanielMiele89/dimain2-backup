/************************************************************************
Author:     Hayden Reid
Date:       2022-02-02
Purpose:    Gets the stored checkpoint value i.e. the last row that was loaded from a table
			
*************************************************************************/
CREATE PROCEDURE [WHB].[Get_TableCheckpoint]
	@SourceTable VARCHAR(100)
	, @getMaxValue BIT = 1
	, @CastAs VARCHAR(15) = 'VARCHAR(500)'
	, @CheckpointValue VARCHAR(500) OUTPUT
AS
BEGIN

	DECLARE @Aggregate VARCHAR(3) = CASE @getMaxValue WHEN 1 THEN 'MAX' ELSE 'MIN' END
	DECLARE @SQL NVARCHAR(MAX) = '
		SELECT @CheckpointValue = '+@Aggregate+'(TRY_CAST(CheckpointValue AS '+@CastAs+'))
		FROM WHB.TableCheckpoint
		WHERE SourceTable = @SourceTable
	'
	EXEC sp_executesql 
		@SQL
		, N'@SourceTable VARCHAR(100), @CheckpointValue VARCHAR(500) out'
		, @SourceTable = @SourceTable, @CheckpointValue = @CheckpointValue out

END

