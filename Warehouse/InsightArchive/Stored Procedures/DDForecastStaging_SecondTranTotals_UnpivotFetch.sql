/******************************************************************************
Author: Jason Shipp
Created: 05/12/2019
Purpose: 
	- Unpivots and fetches forecast results for a ForecastID from the Warehouse.InsightArchive.DDForecastStaging_SecondTranTotals table
	- INSERTS unpivoted data inito Warehouse.InsightArchive.Tableau_MFDD_Forecast_Data - Conal Amendment 16/06/20

------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [InsightArchive].[DDForecastStaging_SecondTranTotals_UnpivotFetch] (@ForecastID int)
AS
BEGIN
	
	SET NOCOUNT ON;
	
	WITH Staging1 AS (
		SELECT [Date], Measure, MeasureValue
		FROM (
			SELECT 
				[Date]
				, CAST(f.Weighted_Transactions AS float) AS Weighted_Transactions -- Cast all values as floats so they can be hold in a single column
				, CAST(f.Weighted_AboveThresholdTransactions AS float) AS Weighted_AboveThresholdTransactions
				, CAST(f.Weighted_BelowThresholdTransactions AS float) AS Weighted_BelowThresholdTransactions
				, CAST(f.Weighted_Shoppers_Household AS float) AS Weighted_Shoppers_Household
				, CAST(f.Weighted_Sales AS float) AS Weighted_Sales
				, CAST(f.Weighted_AboveThresholdSales AS float) AS Weighted_AboveThresholdSales
				, CAST(f.Weighted_BelowThresholdSales AS float) AS Weighted_BelowThresholdSales
				, CAST(f.Weighted_AboveThreshold_Investment AS float) AS Weighted_AboveThreshold_Investment
				, CAST(f.Weighted_AboveThreshold_Cashback AS float) AS Weighted_AboveThreshold_Cashback
				, CAST(f.Weighted_AboveThreshold_Override AS float) AS Weighted_AboveThreshold_Override
				, CAST(f.Weighted_BelowThreshold_Investment AS float) AS Weighted_BelowThreshold_Investment
				, CAST(f.Weighted_BelowThreshold_Cashback AS float) AS Weighted_BelowThreshold_Cashback
				, CAST(f.Weighted_BelowThreshold_Override AS float) AS Weighted_BelowThreshold_Override
				, CAST(f.Weighted_Total_Investment AS float) AS Weighted_Total_Investment
				, CAST(f.Weighted_Total_Cashback AS float) AS Weighted_Total_Cashback
				, CAST(f.Weighted_Total_Override AS float) AS Weighted_Total_Override
			FROM Warehouse.InsightArchive.DDForecastStaging_SecondTranTotals f
			WHERE f.ForecastID = @ForecastID
		) d
		UNPIVOT (
			MeasureValue FOR Measure IN ( -- Columns to stack in a single column
				Weighted_Transactions
				, Weighted_AboveThresholdTransactions
				, Weighted_BelowThresholdTransactions
				, Weighted_Shoppers_Household
				, Weighted_Sales
				, Weighted_AboveThresholdSales
				, Weighted_BelowThresholdSales
				, Weighted_AboveThreshold_Investment
				, Weighted_AboveThreshold_Cashback
				, Weighted_AboveThreshold_Override
				, Weighted_BelowThreshold_Investment
				, Weighted_BelowThreshold_Cashback
				, Weighted_BelowThreshold_Override
				, Weighted_Total_Investment
				, Weighted_Total_Cashback
				, Weighted_Total_Override
			) 
		) AS up
	)
	, Staging2 AS ( -- Split measures into threshold Above, Below and Total 
		SELECT 
		s.[Date]
		, s.Measure
		, 'Above' AS MeasureType
		, s.MeasureValue
		FROM Staging1 s
		WHERE s.Measure LIKE '%_Above%'
		UNION ALL
		SELECT 
		s.[Date]
		, s.Measure
		, 'Below' AS MeasureType
		, s.MeasureValue
		FROM Staging1 s
		WHERE s.Measure LIKE '%_Below%'
		UNION ALL
		SELECT 
		s.[Date]
		, s.Measure
		, 'Total' AS MeasureType
		, s.MeasureValue
		FROM Staging1 s
		WHERE s.Measure NOT LIKE '%_Below%' AND s.Measure NOT LIKE '%_Above%'
	) 
	INSERT INTO Warehouse.InsightArchive.Tableau_MFDD_Forecast_Data
	SELECT
		@ForecastID AS ForecastID
		, s2.[Date]
		, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(s2.Measure, 'Weighted', ''), 'Above', ''), 'Below', ''), 'Total', ''), 'Threshold', ''), '_', '') AS Measure -- Clean measure names
		, s2.MeasureType AS [Measure Type]
		, s2.MeasureValue AS [Measure Value]
	FROM Staging2 s2
	ORDER BY
		[ForecastID]
		, s2.[Date]
		, [Measure]
		, s2.MeasureType;

END