-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [Prototype].[RetailerHeader_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT h.RetailerID, h.Header
	FROM Prototype.RetailerHeader h

END
GO
GRANT EXECUTE
    ON OBJECT::[Prototype].[RetailerHeader_Fetch] TO [SmartEmailClickUser]
    AS [dbo];

