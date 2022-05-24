-- =============================================================================
-- Author:		Shaun H
-- Create date: 7th June 2018
-- Description:	Create the cardholder table used in the MVP Forecasting tool
-- =============================================================================
CREATE PROCEDURE [Prototype].[MVP_Cardholders_Calculate]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF OBJECT_ID('Warehouse.Prototype.MVP_Cardholders') IS NOT NULL DROP TABLE Warehouse.Prototype.MVP_Cardholders
	CREATE TABLE Warehouse.Prototype.MVP_Cardholders
		(
			Program VARCHAR(50),
			ForecastWeek DATE,
			ActivationForecast INT,
			NewJoiners INT		
		)

	INSERT INTO	Warehouse.Prototype.MVP_Cardholders
		SELECT	*
		FROM	(
				SELECT		'MyRewards' as Program,
							DATEADD(d,3,a.WeekstartDate) as ForecastWeek,
							a.ActivationForecast,
							a.ActivationForecast - b.ActivationForecast as NewJoiners
				FROM		Warehouse.MI.CBPActivationsProjections_Weekly a
				INNER JOIN	Warehouse.MI.CBPActivationsProjections_Weekly b on a.WeekStartDate = DATEADD(d,7,b.Weekstartdate)
			) a
		ORDER BY Program
			,Forecastweek
END