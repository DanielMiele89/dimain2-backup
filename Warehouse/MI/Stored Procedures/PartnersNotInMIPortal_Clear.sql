-- =============================================
-- Author:		JEA
-- Create date: 20/10/2014
-- Description:	Clears absent partner table for reload
-- =============================================
CREATE PROCEDURE MI.PartnersNotInMIPortal_Clear 
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	TRUNCATE TABLE MI.PartnersNotInMIPortal

END
