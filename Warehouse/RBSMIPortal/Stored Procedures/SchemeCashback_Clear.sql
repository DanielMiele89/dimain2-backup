-- =============================================
-- Author:		JEA
-- Create date: 17/03/2016
-- Description:	Clears SchemeCashback in preparation for loading
-- =============================================
CREATE PROCEDURE RBSMIPortal.SchemeCashback_Clear 
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE RBSMIPORTAL.SchemeCashback

END
