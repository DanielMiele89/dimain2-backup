-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE AWSFile.PostCode_LastFileProcessed_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT MAX(FileID)
	FROM AWSFile.PostCode_LastFileProcessed

END
