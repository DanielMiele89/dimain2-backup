-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE Prototype.RetailerHeader_Refresh 
AS
BEGIN

	SET NOCOUNT ON;

	INSERT INTO Prototype.RetailerHeader(RetailerID, Header)
	SELECT RetailerID, LEFT(Header,500) AS Header
	FROM Prototype.RetailerHeaderStage

END
GO
GRANT EXECUTE
    ON OBJECT::[Prototype].[RetailerHeader_Refresh] TO [SmartEmailClickUser]
    AS [dbo];

