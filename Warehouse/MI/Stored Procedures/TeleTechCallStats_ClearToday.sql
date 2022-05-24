-- =============================================
-- Author:		JEA
-- Create date: 09/08/2013
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE MI.TeleTechCallStats_ClearToday
	
AS
BEGIN
	
	SET NOCOUNT ON;

    DECLARE @RunDate DATE
	SET @RunDate = GETDATE()

	DELETE FROM MI.TeleTechCallStats WHERE RunDate = @RunDate
	
END