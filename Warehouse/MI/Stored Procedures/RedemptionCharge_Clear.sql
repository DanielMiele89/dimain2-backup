-- =============================================
-- Author:		JEA
-- Create date: 30/07/2013
-- Description:	Truncates the RedemptionCharge table
-- =============================================
CREATE PROCEDURE MI.RedemptionCharge_Clear 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    TRUNCATE TABLE MI.RedemptionCharge;

END
