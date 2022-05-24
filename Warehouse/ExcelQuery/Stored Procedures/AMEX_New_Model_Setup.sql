-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[AMEX_New_Model_Setup]
	-- Add the parameters for the stored procedure here
@BrandList Varchar(500)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DELETE FROM  Warehouse.Prototype.AMEX_BrandList WHERE CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0

			-- Add the brand to the AMEX BrandList
	Insert Into Warehouse.Prototype.AMEX_BrandList
	Select	BrandID
			,BrandName
	From	Warehouse.Relational.Brand 
	Where	CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0

	----Create Date Table
	IF @BrandList IS NULL
		Begin 	
			IF OBJECT_ID('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates
			CREATE TABLE #Dates
				(
					ID INT NOT NULL PRIMARY KEY
					,CycleStart DATE
					,CycleEnd DATE
					,Seasonality_CycleID INT
				)
			;WITH CTE
			 AS (	
					SELECT	1 AS ID
							,CAST('2015-04-02' AS DATE) AS CycleStart
							,CAST('2015-04-29' AS DATE) AS CycleEnd
							,4 AS Seasonality_CycleID
					UNION ALL
					SELECT	ID + 1
							,CAST(DATEADD(DAY,28,CycleStart) AS DATE)
							,CAST(DATEADD(DAY,28,CycleEnd) AS DATE)
							,CASE
								WHEN Seasonality_CycleID < 13 THEN Seasonality_CycleID + 1
								ELSE Seasonality_CycleID - 12
							 END
					FROM	CTE
					WHERE	ID < 68
				)
			INSERT INTO #Dates
				SELECT	* 
				FROM	CTE
			OPTION (MAXRECURSION 68)

			Truncate Table Warehouse.ExcelQuery.Amex_NewModel_Dates

			Insert INTO Warehouse.ExcelQuery.Amex_NewModel_Dates
			SELECT	b.*
					,ROW_NUMBER() OVER (ORDER BY b.ID ASC) AS DateRow
			FROM	(SELECT	*
					 FROM	#Dates 
					 WHERE	CycleStart <= CAST(DATEADD(DAY,-7,GETDATE()) AS DATE)
						AND CAST(DATEADD(DAY,-7,GETDATE()) AS DATE) <= CycleEnd) a
			JOIN	#Dates b
				ON  a.ID - 14 < b.ID
				AND b.ID < a.ID

		END



END