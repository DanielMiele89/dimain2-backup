-- =============================================
-- Author:		JEA
-- Create date: 19/06/2017
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE ExcelQuery.ROCEFT_ROC_Cycle_Calendar_Extended_ETLInsightStore_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT ID
		, CycleStart
		, CycleEnd
		, Seasonality_CycleID
	FROM ExcelQuery.ROCEFT_ROC_Cycle_Calendar_Extended

END

GO
GRANT EXECUTE
    ON OBJECT::[ExcelQuery].[ROCEFT_ROC_Cycle_Calendar_Extended_ETLInsightStore_Fetch] TO [BIDIMAINETLUser]
    AS [dbo];

