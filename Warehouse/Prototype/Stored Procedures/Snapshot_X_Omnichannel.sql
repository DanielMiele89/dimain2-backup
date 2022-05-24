-- =============================================
-- Author:		<Shaun Hide>
-- Create date: <26th January 2018>
-- Description:	<Allow the user to pull omnichannel segment with limited involement>
-- =============================================
CREATE PROCEDURE	Prototype.Snapshot_X_Omnichannel
	(
		@BrandID INT,
		@StartDate DATE,
		@EndDate DATE,
		@Pop VARCHAR(100)
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Test
	--DECLARE @BrandID INT = 371
	--DECLARE @StartDate DATE = '2016-12-01'
	--DECLARE @EndDate DATE = '2016-12-31'
	--DECLARE @Pop VARCHAR(100) = 'Warehouse.InsightArchive.SalesVisSuite_FixedBase'

    -- Prepare necessary tables
	
	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT	ConsumerCombinationID
	INTO	#CC
	FROM	Warehouse.Relational.ConsumerCombination
	WHERE	BrandID = @BrandID

	CREATE CLUSTERED INDEX cix_ConsumerCombinationID ON #CC(ConsumerCombinationID)

	IF OBJECT_ID('tempdb..#Population') IS NOT NULL DROP TABLE #Population
	CREATE TABLE #Population
		(
			CINID INT
		)

	INSERT INTO #Population
		EXEC (' SELECT CINID FROM ' + @Pop + '')

	CREATE CLUSTERED INDEX cix_CINID ON #Population(CINID)

	-- Pull Transactions
	IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
	SELECT	ct.CINID
			,ct.Amount
			,ct.IsOnline
			,ct.TranDate
	INTO	#Trans
	FROM	Warehouse.Relational.ConsumerTransaction ct WITH (NOLOCK)
	JOIN	#CC cc
		ON	ct.ConsumerCombinationID = cc.ConsumerCombinationID
	JOIN	#Population pop
		ON	ct.CINID = pop.CINID
		WHERE  @StartDate <= ct.TranDate AND ct.TranDate <= @EndDate
			AND 0 < ct.Amount

	CREATE CLUSTERED INDEX cix_CINID ON #Trans(CINID)

	-- Create shopper groups
	IF OBJECT_ID('tempdb..#ShopperList') IS NOT NULL DROP TABLE #ShopperList
	SELECT	DISTINCT CINID, IsOnline
	INTO	#ShopperList
	FROM	#Trans

	CREATE CLUSTERED INDEX cix_CINID ON #ShopperList(CINID)
	CREATE NONCLUSTERED INDEX cix_IsOnline ON #ShopperList(IsOnline)

	IF OBJECT_ID('tempdb..#OfflineOnly') IS NOT NULL DROP TABLE #OfflineOnly
	SELECT	DISTINCT CINID
	INTO	#OfflineOnly
	FROM	#ShopperList a
	WHERE	IsOnline = 0
		AND NOT EXISTS	(	SELECT	1
							FROM	#ShopperList b
							WHERE	IsOnline = 1
								AND	a.CINID = b.CINID)

	CREATE CLUSTERED INDEX cix_CINID ON #OfflineOnly(CINID)

	IF OBJECT_ID('tempdb..#OnlineOnly') IS NOT NULL DROP TABLE #OnlineOnly
	SELECT	DISTINCT CINID
	INTO	#OnlineOnly
	FROM	#ShopperList a
	WHERE	IsOnline = 1
		AND NOT EXISTS	(	SELECT	1
							FROM	#ShopperList b
							WHERE	IsOnline = 0
								AND	a.CINID = b.CINID)

	CREATE CLUSTERED INDEX cix_CINID ON #OnlineOnly(CINID)

	IF OBJECT_ID('tempdb..#Omnichannel') IS NOT NULL DROP TABLE #Omnichannel
	SELECT	DISTINCT CINID
	INTO	#Omnichannel
	FROM	#ShopperList a
	WHERE	NOT EXISTS	(	SELECT	1
							FROM	#OfflineOnly b
							WHERE	a.CINID = b.CINID)
		AND	NOT EXISTS	(	SELECT	1
							FROM	#OnlineOnly c
							WHERE	a.CINID = c.CINID)

	CREATE CLUSTERED INDEX cix_CINID ON #Omnichannel(CINID)

	-- Pull Output
	SELECT  a.ShopperGroup,
			a.Shoppers,
			a.Sales,
			a.Transactions,
			COALESCE(1.0*a.Shoppers/NULLIF(1.0*b.Shoppers,0),0) AS ProportionShoppers,
			COALESCE(1.0*a.Sales/NULLIF(1.0*b.Sales,0),0) AS ProportionSales,
			COALESCE(1.0*a.Transactions/NULLIF(1.0*b.Transactions,0),0) AS ProportionTransactions
	FROM	(
				SELECT	'Offline Only' AS ShopperGroup,
						COUNT(DISTINCT a.CINID) AS Shoppers,
						SUM(ct.Amount) AS Sales,
						COUNT(1) AS Transactions
				FROM	#OfflineOnly a
				JOIN	#Trans ct
					ON	a.CINID = ct.CINID
				UNION
				SELECT	'Omnichannel' AS ShopperGroup,
						COUNT(DISTINCT a.CINID) AS Shoppers,
						SUM(ct.Amount) AS Sales,
						COUNT(1) AS Transactions
				FROM	#Omnichannel a
				JOIN	#Trans ct
					ON	a.CINID = ct.CINID
				UNION
				SELECT	'Online Only' AS ShopperGroup,
						COUNT(DISTINCT a.CINID) AS Shoppers,
						SUM(ct.Amount) AS Sales,
						COUNT(1) AS Transactions
				FROM	#OnlineOnly a
				JOIN	#Trans ct
					ON	a.CINID = ct.CINID
			) a
	CROSS JOIN
			(	SELECT  COUNT(DISTINCT CINID) AS Shoppers,
						SUM(Amount) AS Sales,
						COUNT(1) AS Transactions
				FROM	#Trans
			) b	
END