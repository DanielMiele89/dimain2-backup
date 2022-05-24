-- =============================================
-- Author:		<Snapshot - 13 Months SVS with Customer Count>
-- Create date: <30-10-2017>
-- Description:	<SP to get the data>
-- =============================================
CREATE PROCEDURE [Prototype].[Snapshot_1_SalesVisSuite]
	(
		@Trans	 VARCHAR(100),
		@CC		 VARCHAR(100),
		@EndDate DATE
	)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ChildStartDate DATE = DATEADD(MONTH,-13,DATEADD(DAY,1,@EndDate))
	DECLARE @EndDateVARCHAR VARCHAR(10) = CAST(@EndDate AS VARCHAR(10))
	DECLARE @ChildStartDateVARCHAR VARCHAR(10) = CAST(@ChildStartDate AS VARCHAR(10))

	IF OBJECT_ID('tempdb..#Transactions') IS NOT NULL DROP TABLE #Transactions
	CREATE TABLE #Transactions 
		(
			CINID INT,
			ConsumerCombinationID INT,
			Amount MONEY,
			IsOnline BIT,
			TranDate DATE
		)
	EXEC	('	
				INSERT INTO #Transactions
					SELECT	CINID,
							ConsumerCombinationID,
							Amount,
							IsOnline,
							TranDate
					FROM	' + @Trans + '
					-- WHERE	''' + @ChildStartDateVARCHAR + ''' <= TranDate AND TranDate <= ''' + @EndDateVARCHAR + '''
			')

	CREATE CLUSTERED INDEX CIX_Trans_TranDate ON #Transactions(TranDate)
	CREATE NONCLUSTERED INDEX NIX_Trans_TranDateCINID ON #Transactions(TranDate) INCLUDE (CINID)
	CREATE NONCLUSTERED INDEX NIX_Trans_ConsumerCombinationIDCINID ON #Transactions(ConsumerCombinationID) INCLUDE (CINID)

	IF OBJECT_ID('tempdb..#ConsumerCombinationIDs') IS NOT NULL DROP TABLE #ConsumerCombinationIDs
	CREATE TABLE #ConsumerCombinationIDs
		(
			BrandID INT,
			BrandName VARCHAR(50),
			ConsumerCombinationID INT
		)
	EXEC	('
				INSERT INTO #ConsumerCombinationIDs
					SELECT	BrandID,
							BrandName,
							ConsumerCombinationID
					FROM	' + @CC + '
			')

	SELECT		*
	
	FROM		(
					SELECT		DATEPART(MM,TranDate) as MonthNum
								,DATEPART(YYYY,TranDate) as Year
								,CAST(LEFT(CONVERT(VARCHAR,TranDate,112),6) AS NUMERIC) as YYYYMM
								,BrandName
								,'Total' AS Channel 
								,SUM(ct.Amount) as Sales
								,COUNT(*) as Transactions
								,COUNT(DISTINCT ct.CINID) as Shoppers
					FROM		#Transactions ct
					JOIN		#ConsumerCombinationIDs cc 
							ON	cc.ConsumerCombinationID = ct.ConsumerCombinationID
					GROUP BY	DATEPART(MM,TranDate)
								,DATEPART(YYYY,TranDate)
								,CAST(LEFT(CONVERT(VARCHAR,TranDate,112),6) AS NUMERIC)
								,BrandName
				UNION
					SELECT		DATEPART(MM,TranDate) as MonthNum
								,DATEPART(YYYY,TranDate) as Year
								,CAST(LEFT(CONVERT(VARCHAR,TranDate,112),6) AS NUMERIC) as YYYYMM
								,BrandName
								,CASE 
									WHEN IsOnline = 0 THEN 'Offline'
									ELSE 'Online'
									END AS Channel 
								,SUM(ct.Amount) as Sales
								,COUNT(*) as Transactions
								,COUNT(DISTINCT ct.CINID) as Shoppers
					FROM		#Transactions ct
					JOIN		#ConsumerCombinationIDs cc 
							ON	cc.ConsumerCombinationID = ct.ConsumerCombinationID
					GROUP BY	DATEPART(MM,TranDate)
								,DATEPART(YYYY,TranDate)
								,CAST(LEFT(CONVERT(VARCHAR,TranDate,112),6) AS NUMERIC)
								,BrandName
								,IsOnline
				) a
	ORDER BY	4,3,5

END