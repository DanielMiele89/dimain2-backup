-- =============================================
-- Author:		<Snapshot - 13 Months SVS with Customer Count>
-- Create date: <30-10-2017>
-- Description:	<SP to get the data>
-- =============================================
CREATE PROCEDURE [Prototype].[Snapshot_5_SalesVisSuite_Quarters_MainBrand]
	(
		@Population VARCHAR(100),
		@Trans VARCHAR(100),
		@CC VARCHAR(100),
		@EndDate DATE,
		@MainBrand INT
	)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ChildStartDate DATE = DATEADD(MONTH,-6,DATEADD(DAY,1,@EndDate))
	DECLARE @EndDateVARCHAR VARCHAR(10) = CAST(@EndDate AS VARCHAR(10))
	DECLARE @ChildStartDateVARCHAR VARCHAR(10) = CAST(@ChildStartDate AS VARCHAR(10))
	DECLARE @MidDate DATE = DATEADD(MONTH,-3,DATEADD(DAY,1,@EndDate))

	IF OBJECT_ID('tempdb..#CINID') IS NOT NULL DROP TABLE #CINID
	CREATE TABLE #CINID 
		(
			CINID INT
		)
	EXEC	('	
				INSERT INTO #CINID
					SELECT	CINID
					FROM	' + @Population +' pop
			')
	CREATE CLUSTERED INDEX cix_CINID ON #CINID(CINID)

	DECLARE @PopnCount INT = (SELECT COUNT(*) FROM #CINID)

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
	CREATE CLUSTERED INDEX cix_ConsumerCombinationID ON #ConsumerCombinationIDs(ConsumerCombinationID)

	
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

	-- Subset the population into Q1 Main Brand Shoppers

	IF OBJECT_ID('tempdb..#MainBrand_Q1') IS NOT NULL DROP TABLE #MainBrand_Q1
	SELECT	DISTINCT CINID
	INTO	#MainBrand_Q1
	FROM	#Transactions ct
	JOIN	#ConsumerCombinationIDs cc
		ON	ct.ConsumerCombinationID = cc.ConsumerCombinationID
	WHERE	@ChildStartDate <= TranDate AND TranDate < @MidDate
		AND	BrandID = @MainBrand

	CREATE CLUSTERED INDEX cix_CINID ON #MainBrand_Q1(CINID)

	-- Subset the population into Q2 Main Brand Shoppers

	IF OBJECT_ID('tempdb..#MainBrand_Q2') IS NOT NULL DROP TABLE #MainBrand_Q2
	SELECT	DISTINCT CINID
	INTO	#MainBrand_Q2
	FROM	#Transactions ct
	JOIN	#ConsumerCombinationIDs cc
		ON	ct.ConsumerCombinationID = cc.ConsumerCombinationID
	WHERE	@MidDate <= TranDate AND TranDate <= @EndDate
		AND	BrandID = @MainBrand

	CREATE CLUSTERED INDEX cix_CINID ON #MainBrand_Q2(CINID)

	DECLARE @MainBrand_Q1Size INT = (SELECT COUNT(*) FROM #MainBrand_Q1)
	DECLARE @MainBrand_Q2Size INT = (SELECT COUNT(*) FROM #MainBrand_Q2)

	SELECT		*
	FROM		(
					SELECT		DATEPART(YYYY,TranDate) as Year
								,DATEPART(QUARTER,TranDate) AS Quarter
								,BrandName
								,'Total' AS Channel 
								,SUM(ct.Amount) as Sales
								,COUNT(1) as Transactions
								,COUNT(DISTINCT ct.CINID) as Shoppers
								,@MainBrand_Q1Size AS Population
					FROM		#MainBrand_Q1	fb
					JOIN		#Transactions ct with (nolock)
							ON	fb.CINID = ct.CINID
					JOIN		#ConsumerCombinationIDs cc 
							ON	cc.ConsumerCombinationID = ct.ConsumerCombinationID
					WHERE		@ChildStartDate <= TranDate and TranDate < @MidDate
					GROUP BY	DATEPART(YYYY,TranDate)
								,DATEPART(QUARTER,TranDate)
								,BrandName
				UNION
					SELECT		DATEPART(YYYY,TranDate) as Year
								,DATEPART(QUARTER,TranDate) AS Quarter
								,BrandName
								,CASE 
									WHEN IsOnline = 0 THEN 'Offline'
									ELSE 'Online'
									END AS Channel 
								,SUM(ct.Amount) as Sales
								,COUNT(1) as Transactions
								,COUNT(DISTINCT ct.CINID) as Shoppers
								,@MainBrand_Q1Size AS Population
					FROM		#MainBrand_Q1	fb
					JOIN		#Transactions ct with (nolock)
							ON	fb.CINID = ct.CINID
					JOIN		#ConsumerCombinationIDs cc 
							ON	cc.ConsumerCombinationID = ct.ConsumerCombinationID
					WHERE		@ChildStartDate <= TranDate and TranDate < @MidDate
					GROUP BY	DATEPART(YYYY,TranDate)
								,DATEPART(QUARTER,TranDate)
								,BrandName
								,IsOnline
				) a
		UNION
		SELECT		*
		FROM		(
						SELECT		DATEPART(YYYY,TranDate) as Year
									,DATEPART(QUARTER,TranDate) AS Quarter
									,BrandName
									,'Total' AS Channel 
									,SUM(ct.Amount) as Sales
									,COUNT(1) as Transactions
									,COUNT(DISTINCT ct.CINID) as Shoppers
									,@MainBrand_Q2Size AS Population
						FROM		#MainBrand_Q2	fb
						JOIN		#Transactions ct with (nolock)
								ON	fb.CINID = ct.CINID
						JOIN		#ConsumerCombinationIDs cc 
								ON	cc.ConsumerCombinationID = ct.ConsumerCombinationID
						WHERE		@MidDate <= TranDate and TranDate <= @EndDate
						GROUP BY	DATEPART(YYYY,TranDate)
									,DATEPART(QUARTER,TranDate)
									,BrandName
					UNION
						SELECT		DATEPART(YYYY,TranDate) as Year
									,DATEPART(QUARTER,TranDate) AS Quarter
									,BrandName
									,CASE 
										WHEN IsOnline = 0 THEN 'Offline'
										ELSE 'Online'
										END AS Channel 
									,SUM(ct.Amount) as Sales
									,COUNT(1) as Transactions
									,COUNT(DISTINCT ct.CINID) as Shoppers
									,@MainBrand_Q2Size AS Population
						FROM		#MainBrand_Q2	fb
						JOIN		#Transactions ct with (nolock)
								ON	fb.CINID = ct.CINID
						JOIN		#ConsumerCombinationIDs cc 
								ON	cc.ConsumerCombinationID = ct.ConsumerCombinationID
						WHERE		@MidDate <= TranDate and TranDate <= @EndDate
						GROUP BY	DATEPART(YYYY,TranDate)
									,DATEPART(QUARTER,TranDate)
									,BrandName
									,IsOnline
					) a
	ORDER BY	2,4,3,5
END