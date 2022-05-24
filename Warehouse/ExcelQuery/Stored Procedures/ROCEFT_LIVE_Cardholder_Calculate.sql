﻿-- =============================================================================
-- Author:		Shaun H
-- Description:	Create the cardholder table used in the new ROC Forecasting Tool
-- =============================================================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_LIVE_Cardholder_Calculate]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF OBJECT_ID('Warehouse.ExcelQuery.ROCEFT_Cardholders') IS NOT NULL DROP TABLE Warehouse.ExcelQuery.ROCEFT_Cardholders
	SELECT	*
	INTO	Warehouse.ExcelQuery.ROCEFT_Cardholders
	FROM	(
			SELECT	-- Hack due to poor design choices
					CASE 
						WHEN PublisherName = 'Avios Collinson Group' THEN 'Collinson - Avios'
						WHEN PublisherName = 'British Airways Collinson' THEN 'Collinson - BAA'
						WHEN PublisherName = 'VAA Collinson Group' THEN 'Collinson - Virgin'
						WHEN PublisherName = 'RBS' THEN 'MyRewards'
						WHEN PublisherName = 'Gobsmack More Than' THEN 'Gobsmack - More Than'
						WHEN PublisherName = 'Mustard Gobsmack' THEN 'Gobsmack - Mustard'
						WHEN PublisherName = 'Admiral Insurance' THEN 'Gobsmack - Admiral'
						WHEN PublisherName = 'Thomas Cook' THEN 'Gobsmack - Thomas Cook'
						ELSE PublisherName
					END AS Program,
					WeekDate AS ForecastWeek,
					CumulativeCardholders AS ActivationForecast,
					AddedCardholders AS NewJoiners
			FROM	Warehouse.Prototype.CardholderProjections
			WHERE	ArchivedDate IS NULL
		) a
	ORDER BY Program
		,Forecastweek
END