-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE APW.ROCEFT_Publishers_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT PublisherID, PublisherName
	FROM ExcelQuery.ROCEFT_Publishers
	WHERE PublisherID IS NOT NULL
	AND PublisherName IS NOT NULL

END