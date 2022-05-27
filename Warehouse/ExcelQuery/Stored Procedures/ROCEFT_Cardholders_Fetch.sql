CREATE PROCEDURE [ExcelQuery].[ROCEFT_Cardholders_Fetch]
		(@EngagementStart Date
		,@EngagementEnd Date)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT	Program,
			ForecastWeek,
			ActivationForecast,
			NewJoiners
	FROM  (
			SELECT		CASE
						  WHEN Program = 'MyRewards' THEN 1
						  ELSE 2
						END AS Rank
						,Program
						,ForecastWeek
						,ActivationForecast
						,NewJoiners
			FROM		Warehouse.ExcelQuery.ROCEFT_Cardholders
			WHERE		ForecastWeek between  @EngagementStart and @EngagementEnd
		 )  a
	ORDER BY Rank, Program, ForecastWeek
END