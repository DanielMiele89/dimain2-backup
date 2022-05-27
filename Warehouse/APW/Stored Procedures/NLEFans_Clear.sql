-- =============================================
-- Author:		JEA
-- Create date: 02/08/2016
-- Description:	Clears NLE Fans Table
-- =============================================
CREATE PROCEDURE APW.NLEFans_Clear 

AS
BEGIN

	SET NOCOUNT ON;

	TRUNCATE TABLE APW.NLEFans

END
