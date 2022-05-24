-- =============================================
-- Author:		JEA
-- Create date: 05/02/2018
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE Staging.RetailerAccountManager_Clear
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE Relational.RetailerAccountManager

END
GO
GRANT EXECUTE
    ON OBJECT::[Staging].[RetailerAccountManager_Clear] TO [BIDIMAINETLUser]
    AS [dbo];

