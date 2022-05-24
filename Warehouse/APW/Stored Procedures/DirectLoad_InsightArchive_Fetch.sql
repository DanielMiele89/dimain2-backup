-- =============================================
-- Author:		jea
-- Create date: 24/11/2016
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE APW.DirectLoad_InsightArchive_Fetch 

AS
BEGIN

	SET NOCOUNT ON;

    SELECT ID, FANID, [Date], TypeID
	FROM Staging.InsightArchiveData
	WHERE TypeID = 1

END