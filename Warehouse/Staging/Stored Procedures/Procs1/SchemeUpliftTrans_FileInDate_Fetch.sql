-- =============================================
-- Author:		JEA
-- Create date: 03/07/2013
-- Description:	Retrieves indates for SchemeUpliftTrans load
-- =============================================
CREATE PROCEDURE Staging.SchemeUpliftTrans_FileInDate_Fetch 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT ID, CAST(InDate AS Date) AS InDate
	FROM SLC_Report.dbo.NobleFiles
	WHERE FileType = 'TRANS'
	ORDER BY ID

END
