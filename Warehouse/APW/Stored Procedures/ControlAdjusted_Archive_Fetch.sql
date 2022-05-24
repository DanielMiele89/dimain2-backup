-- =============================================
-- Author:		JEA
-- Create date: 04/01/2017
-- Description:	Retrieves adjusted control group
-- following creation with Month Date for archiving
-- =============================================
CREATE PROCEDURE APW.ControlAdjusted_Archive_Fetch

AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @MonthDate DATE
	SET @MonthDate = DATEADD(MONTH,-1,DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1))

    SELECT CINID, @MonthDate AS MonthDate
	FROM APW.ControlAdjusted

END