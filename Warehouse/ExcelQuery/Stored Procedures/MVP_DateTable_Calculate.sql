-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[MVP_DateTable_Calculate]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF OBJECT_ID('Warehouse.ExcelQuery.MVP_DateTable') IS NOT NULL DROP TABLE Warehouse.ExcelQuery.MVP_DateTable
	CREATE TABLE Warehouse.ExcelQuery.MVP_DateTable
		(
			ID INT NOT NULL PRIMARY KEY
			,CycleStart DATE
			,CycleEnd DATE
			,Seasonality_CycleID INT
			,FlaggedDate BIT
			,EngagementFlaggedDate BIT
		)

	;WITH CTE
	 AS (	
			SELECT	9 AS ID
					,CAST('2015-04-02' AS DATE) AS CycleStart
					,CAST('2015-04-29' AS DATE) AS CycleEnd
					,9 AS Seasonality_CycleID
					,0 AS FlaggedDate
					,0 AS EngagementFlaggedDate
		
			UNION ALL
		
			SELECT	ID + 1
					,CAST(DATEADD(DAY,14,CycleStart) AS DATE)
					,CAST(DATEADD(DAY,14,CycleEnd) AS DATE)
					,CASE
						WHEN Seasonality_CycleID < 26 THEN Seasonality_CycleID + 1
						ELSE Seasonality_CycleID - 25
					 END
					,0
					,0
			FROM	CTE
			WHERE	ID < 156
		)
	INSERT INTO Warehouse.ExcelQuery.MVP_DateTable
		SELECT	* 
		FROM	CTE
	OPTION (MAXRECURSION 156)

	UPDATE	dt
	SET		dt.FlaggedDate = 1
	FROM	Warehouse.ExcelQuery.MVP_DateTable dt
	JOIN	(
				SELECT	TOP 28 *
				FROM	Warehouse.ExcelQuery.MVP_DateTable
				WHERE	CycleEnd < DATEADD(DAY,-7,GETDATE())
				ORDER BY ID DESC
			) b
		ON	dt.ID = b.ID

	-- Engagement Scores can extend a different date range to the spend actuals
	UPDATE dt
	SET		dt.EngagementFlaggedDate = 1
	FROM	Warehouse.ExcelQuery.MVP_DateTable dt
	JOIN	(
				SELECT	*
				FROM	Warehouse.ExcelQuery.MVP_DateTable
				WHERE	CycleStart < GETDATE()
					AND	(SELECT MIN(CycleStart) FROM Warehouse.ExcelQuery.MVP_DateTable WHERE FlaggedDate = 1) <= CycleStart 
			) b
		ON	dt.ID = b.ID

	-- SELECT * FROM Warehouse.ExcelQuery.MVP_DateTable
END
