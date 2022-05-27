-- =============================================
-- Author:		<Snapshot - 364 Days of Week>
-- Create date: <30-10-2017>
-- Description:	<SP to get the data>
-- =============================================
CREATE PROCEDURE [Prototype].[Snapshot_2_DayOfWeek]
	(
		@Trans	 VARCHAR(100),
		@CC		 VARCHAR(100),
		@EndDate DATE
	)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ChildStartDate DATE = DATEADD(DAY,-363,@EndDate)
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
					WHERE	''' + @ChildStartDateVARCHAR + ''' <= TranDate AND TranDate <= ''' + @EndDateVARCHAR + '''
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

	SET DATEFIRST 1

	SELECT		*
	FROM		(
						SELECT		TranDate
									,DATENAME(dw,TranDate) AS TranDayOfWeek
									,DATEPART(WK,TranDate) AS WeekNum
									,DATEPART(MM,TranDate) AS MonthNum
									,DATEPART(YYYY,TranDate) AS Year
									,BrandName
									,'Total' AS Channel 
									,SUM(ct.Amount) as Sales
									,COUNT(1) as Transactions
									,COUNT(DISTINCT ct.CINID) as Shoppers
						FROM		#Transactions ct with (nolock)
						JOIN		#ConsumerCombinationIDs cc 
								ON	cc.ConsumerCombinationID = ct.ConsumerCombinationID
						GROUP BY	TranDate
									,DATENAME(dw,TranDate)
									,DATEPART(WK,TranDate)
									,DATEPART(MM,TranDate)
									,DATEPART(YYYY,TranDate)
									,BrandName
					UNION
						SELECT		TranDate
									,DATENAME(dw,TranDate)
									,DATEPART(WK,TranDate)
									,DATEPART(MM,TranDate)
									,DATEPART(YYYY,TranDate)
									,BrandName
									,CASE 
										WHEN IsOnline = 0 THEN 'Offline'
										ELSE 'Online'
									 END AS Channel 
									,SUM(ct.Amount) as Sales
									,COUNT(1) as Transactions
									,COUNT(DISTINCT ct.CINID) as Shoppers
						FROM		#Transactions ct with (nolock)
						JOIN		#ConsumerCombinationIDs cc 
								ON	cc.ConsumerCombinationID = ct.ConsumerCombinationID
						GROUP BY	TranDate
									,DATENAME(dw,TranDate)
									,DATEPART(WK,TranDate)
									,DATEPART(MM,TranDate)
									,DATEPART(YYYY,TranDate)
									,BrandName
									,IsOnline
				) a
	ORDER BY	6,1,7

END
