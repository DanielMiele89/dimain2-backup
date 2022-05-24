-- =============================================
-- Author:		JEA
-- Create date: 13/12/2013
-- Description:	Fetches File Rowcount
-- =============================================
CREATE PROCEDURE MI.ConsumerRowCount_Fetch 
	(
		@FileID INT
	)
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT Max(RowNum) AS MaxRowNum
	FROM Relational.CardTransaction with (nolock)
	WHERE FileID = @FileID

END
