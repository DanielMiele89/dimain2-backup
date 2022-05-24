-- =============================================
-- Author:		JEA
-- Create date: 19/10/2014
-- Description:	Clears contactless table
-- =============================================
CREATE PROCEDURE MI.RBSContactlessCashback_Clear 
	WITH EXECUTE AS OWNER 

AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE MI.RBSContactlessTrans

END
