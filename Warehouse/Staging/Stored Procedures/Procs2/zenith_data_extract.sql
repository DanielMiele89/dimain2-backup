/*
1. NatWest (Marketable by Email) 
2. NatWest customers who have earned the minimum Rewards balance to be able to redeem (Marketable by Email) 
*/


CREATE procedure staging.zenith_data_extract as 

IF OBJECT_ID ('tempdb..#NatWestA') IS NOT NULL DROP TABLE #NatWestA
SELECT	TOP 50 PERCENT 
	*
INTO #NatWestA
FROM	(
	SELECT	c.Email 
	FROM Warehouse.Relational.Customer c
	INNER JOIN SLC_Report.dbo.fan f
		ON c.FanID = f.ID
	WHERE	c.CurrentlyActive = 1
		AND c.MarketableByEmail = 1
		AND c.ClubID = 132
	)a
--(527076 row(s) affected)


IF OBJECT_ID ('tempdb..#NatWestB') IS NOT NULL DROP TABLE #NatWestB
SELECT	c.Email 
INTO #NatWestB
FROM Warehouse.Relational.Customer c
INNER JOIN SLC_Report.dbo.fan f
	ON c.FanID = f.ID
LEFT OUTER JOIN #NatWestA n
	ON c.Email = n.Email
WHERE	c.CurrentlyActive = 1
	AND c.MarketableByEmail = 1
	AND c.ClubID = 132
	AND n.Email IS NULL
--(527076 row(s) affected)

--Checking
--SELECT	COUNT(1)
--FROM #NatWestA a
--INNER JOIN #NatWestB b
--	ON a.Email = b.Email
--0

--SELECT COUNT(1),COUNT(DISTINCT Email) FROM #NatWestA

--SELECT COUNT(1),COUNT(DISTINCT Email) FROM #NatWestB

-----------------------------------------------------------------------------------------------------
--2

SELECT * FROM #NatWestA

SELECT * FROM #NatWestB

SELECT	c.Email 
FROM Warehouse.Relational.Customer c
INNER JOIN SLC_Report.dbo.fan f
	ON c.FanID = f.ID
WHERE	c.CurrentlyActive = 1
	AND c.MarketableByEmail = 1
	AND c.ClubID = 132
	AND f.ClubCashAvailable >= 5


-------------------------------------------------------------------------------------
--RBS Files

SELECT	c.Email 
FROM Warehouse.Relational.Customer c
INNER JOIN SLC_Report.dbo.fan f
	ON c.FanID = f.ID
WHERE	c.CurrentlyActive = 1
	AND c.MarketableByEmail = 1
	AND c.ClubID = 138



SELECT	c.Email 
FROM Warehouse.Relational.Customer c
INNER JOIN SLC_Report.dbo.fan f
	ON c.FanID = f.ID
WHERE	c.CurrentlyActive = 1
	AND c.MarketableByEmail = 1
	AND c.ClubID = 138
	AND f.ClubCashAvailable >= 5