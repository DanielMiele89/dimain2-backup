-- =============================================
-- Author:		JEA
-- Create date: 24/03/2014
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[SchemeUpliftTrans_LoadedFileID_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT ISNULL(MAX(FileID),0) AS FileID
	FROM Relational.SchemeUpliftTrans

END
