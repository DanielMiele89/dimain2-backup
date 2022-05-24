
CREATE PROCEDURE [Selections].[MGD003_PreSelection_sProc]
AS
BEGIN


/*******************************************************************************************************************************************
	1. Fetch Customers on new UX
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb.dbo.#NewUXFans') is not null drop table #NewUXFans;
	CREATE TABLE #NewUXFans (FanID INT);
	INSERT INTO #NewUXFans (FanID) VALUES (2166488 );
	INSERT INTO #NewUXFans (FanID) VALUES (26257164);
	INSERT INTO #NewUXFans (FanID) VALUES (23385232);
	INSERT INTO #NewUXFans (FanID) VALUES (1922585 );
	INSERT INTO #NewUXFans (FanID) VALUES (3999379 );
	INSERT INTO #NewUXFans (FanID) VALUES (21844458);
	INSERT INTO #NewUXFans (FanID) VALUES (21999556);
	INSERT INTO #NewUXFans (FanID) VALUES (8564776 );
	INSERT INTO #NewUXFans (FanID) VALUES (6595012 );
	INSERT INTO #NewUXFans (FanID) VALUES (22344661);
	INSERT INTO #NewUXFans (FanID) VALUES (22638675);
	INSERT INTO #NewUXFans (FanID) VALUES (11872540);
	INSERT INTO #NewUXFans (FanID) VALUES (24105721);
	INSERT INTO #NewUXFans (FanID) VALUES (7211329 );
	INSERT INTO #NewUXFans (FanID) VALUES (3807974 );
	INSERT INTO #NewUXFans (FanID) VALUES (14825118);
	INSERT INTO #NewUXFans (FanID) VALUES (14713304);
	INSERT INTO #NewUXFans (FanID) VALUES (25192721);
	INSERT INTO #NewUXFans (FanID) VALUES (3577363 );
	INSERT INTO #NewUXFans (FanID) VALUES (8014840 );
	INSERT INTO #NewUXFans (FanID) VALUES (4738198 );
	INSERT INTO #NewUXFans (FanID) VALUES (4984611 );
	INSERT INTO #NewUXFans (FanID) VALUES (7571068 );
	INSERT INTO #NewUXFans (FanID) VALUES (14948395);
	INSERT INTO #NewUXFans (FanID) VALUES (5366171 );
	INSERT INTO #NewUXFans (FanID) VALUES (12809132);
	INSERT INTO #NewUXFans (FanID) VALUES (4045473 );
	INSERT INTO #NewUXFans (FanID) VALUES (1923729 );
	INSERT INTO #NewUXFans (FanID) VALUES (6271270 );
	INSERT INTO #NewUXFans (FanID) VALUES (24172951);
	INSERT INTO #NewUXFans (FanID) VALUES (1923715 );
	INSERT INTO #NewUXFans (FanID) VALUES (6583698 );
	INSERT INTO #NewUXFans (FanID) VALUES (6694065 );
	INSERT INTO #NewUXFans (FanID) VALUES (12476983);
	INSERT INTO #NewUXFans (FanID) VALUES (1923724 );
	INSERT INTO #NewUXFans (FanID) VALUES (19383788);
	INSERT INTO #NewUXFans (FanID) VALUES (13685352);
	INSERT INTO #NewUXFans (FanID) VALUES (14657604);
	INSERT INTO #NewUXFans (FanID) VALUES (6044524 );
	INSERT INTO #NewUXFans (FanID) VALUES (5487967 );
	INSERT INTO #NewUXFans (FanID) VALUES (4143948 );
	INSERT INTO #NewUXFans (FanID) VALUES (17489595);
	INSERT INTO #NewUXFans (FanID) VALUES (23650785);
	INSERT INTO #NewUXFans (FanID) VALUES (17070373);
	INSERT INTO #NewUXFans (FanID) VALUES (23442122);
	INSERT INTO #NewUXFans (FanID) VALUES (5399003 );
	INSERT INTO #NewUXFans (FanID) VALUES (13685352);
	INSERT INTO #NewUXFans (FanID) VALUES (4404762 );
	INSERT INTO #NewUXFans (FanID) VALUES (7549789 );
	INSERT INTO #NewUXFans (FanID) VALUES (7489457 );
	INSERT INTO #NewUXFans (FanID) VALUES (1923727 );
	INSERT INTO #NewUXFans (FanID) VALUES (22369237);
	INSERT INTO #NewUXFans (FanID) VALUES (23049726);
	INSERT INTO #NewUXFans (FanID) VALUES (18396983);
	INSERT INTO #NewUXFans (FanID) VALUES (4702176 );
	INSERT INTO #NewUXFans (FanID) VALUES (25345467);
	INSERT INTO #NewUXFans (FanID) VALUES (4626203 );
	INSERT INTO #NewUXFans (FanID) VALUES (7846534);
	INSERT INTO #NewUXFans (FanID) VALUES (22906604);
	INSERT INTO #NewUXFans (FanID) VALUES (16229205);
	INSERT INTO #NewUXFans (FanID) VALUES (5675362);
	INSERT INTO #NewUXFans (FanID) VALUES (6488757);
	INSERT INTO #NewUXFans (FanID) VALUES (20382881);
	INSERT INTO #NewUXFans (FanID) VALUES (4548485);
	INSERT INTO #NewUXFans (FanID) VALUES (17760339);
	INSERT INTO #NewUXFans (FanID) VALUES (27123412);
	INSERT INTO #NewUXFans (FanID) VALUES (5589811);

/*******************************************************************************************************************************************
	1. Fetch NatWest Customers
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
	SELECT	cu.FanID
	INTO #Customers
	FROM [Relational].[Customer] cu
	WHERE ClubID = 132
	AND NOT EXISTS (SELECT 1
					FROM #NewUXFans nux
					WHERE cu.FanID = nux.FanID)
	
	
/***********************************************************************************************************************
	2.	Assign Customers
***********************************************************************************************************************/

	If Object_ID('Warehouse.Selections.MGD003_PreSelection') IS NOT NULL DROP TABLE Warehouse.Selections.MGD003_PreSelection
	SELECT *
	INTO Warehouse.Selections.MGD003_PreSelection
	FROM #Customers
					
END