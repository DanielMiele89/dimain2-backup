-- =============================================
-- Author:		JEA
-- Create date: 12/07/2013
-- Description:	Clears the SchemeDataParams table
-- =============================================
CREATE PROCEDURE MI.SchemeDateParams_Clear 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    TRUNCATE TABLE MI.SchemeDateParams;

END
