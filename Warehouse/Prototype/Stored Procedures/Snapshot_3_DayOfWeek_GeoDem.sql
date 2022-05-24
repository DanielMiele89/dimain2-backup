-- =============================================
-- Author:		<Snapshot - 364 Days of Week>
-- Create date: <30-10-2017>
-- Description:	<SP to get the data>
-- =============================================
CREATE PROCEDURE [Prototype].[Snapshot_3_DayOfWeek_GeoDem]
	(
		@Population VARCHAR(100),
		@Trans VARCHAR(100),
		@CC VARCHAR(100),
		@EndDate DATE
	)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ChildStartDate DATE = DATEADD(DAY,2,DATEADD(YEAR,-1,@EndDate))
	DECLARE @EndDateVARCHAR VARCHAR(10) = CAST(@EndDate AS VARCHAR(10))
	DECLARE @ChildStartDateVARCHAR VARCHAR(10) = CAST(@ChildStartDate AS VARCHAR(10))

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

	IF OBJECT_ID('tempdb..#PopulationGeodem') IS NOT NULL DROP TABLE #PopulationGeodem
	SELECT		DISTINCT pop.CINID
				,c.Gender
				,CASE	
					WHEN c.AgeCurrent < 18 OR c.AgeCurrent IS NULL THEN '99. Unknown'
					WHEN c.AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
					WHEN c.AgeCurrent BETWEEN 25 AND 29 THEN '02. 25 to 29'
					WHEN c.AgeCurrent BETWEEN 30 AND 39 THEN '03. 30 to 39'
					WHEN c.AgeCurrent BETWEEN 40 AND 49 THEN '04. 40 to 49'
					WHEN c.AgeCurrent BETWEEN 50 AND 59 THEN '05. 50 to 59'
					WHEN c.AgeCurrent BETWEEN 60 AND 64 THEN '06. 60 to 64'
					WHEN c.AgeCurrent >= 65 THEN '07. 65+' 
				 END AS AgeBand
				,ISNULL(camg.Social_Class,'U') AS SocialClass
				,ISNULL(camg.CAMEO_CODE_GROUP + '-' + camg.CAMEO_CODE_GROUP_Category,'99 - Unknown') AS CameoCode
	INTO		#PopulationGeodem
	FROM		#CINID pop
	JOIN		Warehouse.Relational.CINList cin
			ON	pop.CINID = cin.CINID
	JOIN		Warehouse.Relational.Customer c
			ON	cin.CIN = c.SourceUID
	LEFT JOIN	Warehouse.Relational.CAMEO cam
			ON	c.PostCode = cam.Postcode
	LEFT JOIN	Warehouse.Relational.CAMEO_CODE_GROUP camg
			ON	camg.CAMEO_CODE_GROUP = cam.CAMEO_CODE_GROUP

	CREATE CLUSTERED INDEX cix_CINID ON #PopulationGeodem(CINID)

	IF OBJECT_ID('tmepdb..#PopulationFinal') IS NOT NULL DROP TABLE #PopulationFinal
	SELECT	*
	INTO	#PopulationFinal
	FROM	#PopulationGeodem pop
	WHERE	NOT EXISTS	(	SELECT	*
							FROM	(
										SELECT	CINID
												,COUNT(*) AS CINIDCount
										FROM	#PopulationGeodem
										GROUP BY CINID
										HAVING	COUNT(*) > 1
									) a
							WHERE a.CINID = pop.CINID
						)

	CREATE CLUSTERED INDEX cix_CINID ON #PopulationFinal(CINID)

	SET DATEFIRST 1

	SELECT		*
	FROM		(
					SELECT		DATENAME(dw,TranDate) AS TranDayOfWeek
								,BrandName
								,Gender
								,AgeBand
								,SocialClass
								,SUM(ct.Amount) as Sales
								,COUNT(1) as Transactions
								,COUNT(DISTINCT ct.CINID) as Shoppers
					FROM		#PopulationFinal	fb
					JOIN		#Transactions ct with (nolock)
							ON	fb.CINID = ct.CINID
					JOIN		#ConsumerCombinationIDs cc 
							ON	cc.ConsumerCombinationID = ct.ConsumerCombinationID
					GROUP BY	DATENAME(dw,TranDate)
								,BrandName
								,Gender
								,AgeBand
								,SocialClass
				) a
	ORDER BY	1,2,3,4,5

END