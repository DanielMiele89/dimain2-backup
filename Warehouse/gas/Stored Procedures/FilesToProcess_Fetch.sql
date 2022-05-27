-- =============================================
-- Author:		JEA
-- Create date: 07/11/2012
-- Description:	Used by Merchant Processing Module.
-- Retrieves the files requiring processing
-- =============================================
CREATE PROCEDURE [gas].[FilesToProcess_Fetch]
	(
		@LastFileID Int
	)
AS
BEGIN

	SET NOCOUNT ON;

    SELECT ID, InDate
	FROM SLC_REPL.dbo.NobleFiles
	WHERE FileType = 'TRANS'
	AND NOT [FileName] LIKE '%RBOW%'
	AND ID > @LastFileID
	ORDER BY ID
	
END
