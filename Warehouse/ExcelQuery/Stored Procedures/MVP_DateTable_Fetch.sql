-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE ExcelQuery.MVP_DateTable_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT ID, CycleStart, CycleEnd, Seasonality_CycleID, FlaggedDate
	FROM ExcelQuery.MVP_DateTable

END