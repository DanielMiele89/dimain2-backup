-- =============================================================================
-- Author:		Shaun H
-- Create date: 7th June 2018
-- Description:	Create the cardholder table used in the MVP Forecasting tool
-- =============================================================================
CREATE PROCEDURE [ExcelQuery].[MVP_Cardholders_Calculate]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--IF OBJECT_ID('Warehouse.ExcelQuery.MVP_Cardholders') IS NOT NULL DROP TABLE Warehouse.ExcelQuery.MVP_Cardholders
	--CREATE TABLE Warehouse.Prototype.MVP_Cardholders
	--	(
	--		Program VARCHAR(50),
	--		ForecastWeek DATE,
	--		ActivationForecast INT,
	--		NewJoiners INT		
	--	)
	TRUNCATE TABLE Warehouse.ExcelQuery.MVP_Cardholders

	INSERT INTO	Warehouse.ExcelQuery.MVP_Cardholders
		SELECT	*
		FROM	(
				SELECT
				  'MyRewards' AS Program,
				  DATEADD(DAY,3,ToDate) AS ForecastWeek,
				  Cumulative_Cardholders,
				  Added_Cardholders AS NewJoiners
				FROM	Warehouse.MI.ActivationsProjections_Weekly_RBS a
			) a
		ORDER BY Program
			,Forecastweek
END