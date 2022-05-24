-- =============================================
-- Author:		JEA
-- Create date: 19/06/2017
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE ExcelQuery.ROCEFT_Cardholders_ETLInsightStore_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT Program
		, ForecastWeek
		, ActivationForecast
		, NewJoiners
	FROM ExcelQuery.ROCEFT_Cardholders

END
GO
GRANT EXECUTE
    ON OBJECT::[ExcelQuery].[ROCEFT_Cardholders_ETLInsightStore_Fetch] TO [BIDIMAINETLUser]
    AS [dbo];

