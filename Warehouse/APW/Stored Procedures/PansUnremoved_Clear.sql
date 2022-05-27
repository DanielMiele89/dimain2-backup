-- =============================================
-- Author:		JEA
-- Create date: 15/02/2017
-- Description:	Truncates the AWP.PansUnremoved table for repopulation
-- =============================================
CREATE PROCEDURE APW.PansUnremoved_Clear 

AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE APW.PansUnremoved

END
