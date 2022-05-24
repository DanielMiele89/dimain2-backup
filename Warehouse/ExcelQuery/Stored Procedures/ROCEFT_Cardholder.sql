-- =============================================================================
-- Author:		Shaun H
-- Create date: 19th June 2017
-- Description:	Create the cardholder table used in the new ROC Forecasting Tool
-- =============================================================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_Cardholder]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF OBJECT_ID('Warehouse.ExcelQuery.ROCEFT_Cardholders') IS NOT NULL DROP TABLE Warehouse.ExcelQuery.ROCEFT_Cardholders
	SELECT	*
	INTO	Warehouse.ExcelQuery.ROCEFT_Cardholders
	FROM	(
			SELECT 'MyRewards' AS Program,
					DATEADD(DAY,3,ToDate) AS ForecastWeek,
					Cumulative_Cardholders AS ActivationForecast,
					Added_Cardholders AS NewJoiners
			FROM	Warehouse.MI.ActivationsProjections_Weekly_RBS
		UNION ALL
			SELECT	Publisher,
					DATEADD(d,3,ToDate),
					Cumulative_Cardholders,
					Added_Cardholders
			FROM Prototype.ActivationsProjections_Weekly_NJ
		UNION ALL 
			SELECT	Publisher,
					DATEADD(d,3,ToDate),
					Cumulative_Cardholders,
					Added_Cardholders
			FROM Prototype.ActivationsProjections_Weekly_AirtimeRewards
		UNION ALL 
			SELECT	
					'Quidco' as Publisher,
					DATEADD(d,3,ToDate),
					Cumulative_Cardholders,
					Added_Cardholders
			FROM Prototype.ActivationsProjections_Weekly_PureQuidco
		UNION ALL 
			SELECT	
					'R4G' as Publisher,
					DATEADD(d,3,ToDate),
					Cumulative_Cardholders,
					Added_Cardholders
			FROM Prototype.ActivationsProjections_Weekly_R4G
		UNION ALL 
			SELECT	
					'Collinson - Virgin' as Publisher,
					DATEADD(d,3,ToDate),
					Cumulative_Cardholders,
					Added_Cardholders
			FROM Prototype.ActivationsProjections_Weekly_CollinsonVirgin
		UNION ALL 
			SELECT	
					'Collinson - Avios' as Publisher,
					DATEADD(d,3,ToDate),
					Cumulative_Cardholders,
					Added_Cardholders
			FROM Prototype.ActivationsProjections_Weekly_CollinsonAvios
		UNION ALL 
			SELECT	
					'Collinson - BAA' as Publisher,
					DATEADD(d,3,ToDate),
					Cumulative_Cardholders,
					Added_Cardholders
			FROM Prototype.ActivationsProjections_Weekly_CollinsonBAA
		UNION ALL
			SELECT  
					'Collinson - UA' as Publisher,
					DATEADD(d,3,ToDate),
					Cumulative_Cardholders,
					Added_Cardholders
			FROM Prototype.ActivationsProjections_Weekly_CollinsonUA
		UNION ALL
			SELECT	
					'Top CashBack' as Publisher,
					DATEADD(d,3,ToDate),
					Cumulative_Cardholders,
					Added_Cardholders
			FROM Prototype.ActivationsProjections_Weekly_TopCashback
		UNION ALL
			SELECT  
					'Gobsmack - More Than' as Publisher,
					DATEADD(d,3,ToDate),
					Cumulative_Cardholders,
					Added_Cardholders
			FROM Prototype.ActivationsProjections_Weekly_Gobsmack_MoreThan
		UNION ALL
			SELECT  
					'Gobsmack - Mustard' as Publisher,
					DATEADD(d,3,ToDate),
					Cumulative_Cardholders,
					Added_Cardholders
			FROM Prototype.ActivationsProjections_Weekly_Gobsmack_Mustard
		UNION ALL
			SELECT  
					'Complete Savings' as Publisher,
					DATEADD(d,3,ToDate),
					Cumulative_Cardholders,
					Added_Cardholders
			FROM Prototype.ActivationsProjections_Weekly_CompleteSavings
		) a
	ORDER BY Program
		,Forecastweek
END