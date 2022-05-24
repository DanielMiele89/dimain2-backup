-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	Used by Merchant Processing Module.
-- Retrieves the files requiring processing
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_FilesToProcess_Fetch]
	(
		@LastFileID Int
	)
AS
BEGIN

	SET NOCOUNT ON;

    SELECT ID, InDate
	FROM SLC_REPL.dbo.NobleFiles
	--WHERE FileType IN ('TRANS', 'CRTRN')
	WHERE FileType = 'TRANS'
	AND ID > @LastFileID
	AND ID != 27429
	ORDER BY ID
	
END