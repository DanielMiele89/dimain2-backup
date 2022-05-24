-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [Prototype].[RetailerHeaderStage_CheckOutstanding] 
AS
BEGIN

	SET NOCOUNT ON;

	EXEC Prototype.RetailerHeaderStage_Refresh

	SELECT COUNT(*) AS UnresolvedHeaderCount
	FROM Prototype.RetailerHeaderStage

END