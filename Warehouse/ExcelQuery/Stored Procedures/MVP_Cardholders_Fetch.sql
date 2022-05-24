-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE ExcelQuery.MVP_Cardholders_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT Program, ForecastWeek, ActivationForecast, NewJoiners
	FROM ExcelQuery.MVP_Cardholders

END
