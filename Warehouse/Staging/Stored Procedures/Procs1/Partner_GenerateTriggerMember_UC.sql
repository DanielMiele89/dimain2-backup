
/*
Title:   Partner Trigger Member Generation Code
Purpose: To automatically generate a list of customers who have shopped with
	 predefined brands during a certain period of time.
Date:	 06-01-2015
Author:  Suraj Chahal

Before Running this Code please make sure you have entries for in the following tables:
	Relational.PartnerTrigger_UC_Campaigns
	Relational.PartnerTrigger_UC_Brands
*/

CREATE PROCEDURE [Staging].[Partner_GenerateTriggerMember_UC]
			(
			@CampaignID INT
			)
With Execute as owner
AS

BEGIN

/*--------------------------------------------------------------*/
---------------------Declaring the Variables---------------------
/*--------------------------------------------------------------*/
DECLARE	@DaysWorthTransactions INT

SET @DaysWorthTransactions = (SELECT DaysWorthTransactions FROM Relational.PartnerTrigger_UC_Campaigns WHERE CampaignID = @CampaignID) 



/*------------------------------------------------------------*/
---------------Find the activated Emailable Base---------------
/*------------------------------------------------------------*/
IF OBJECT_ID ('tempdb..#UCBase') IS NOT NULL DROP TABLE #UCBase
SELECT	FanID, 
	CINID
INTO #UCBase
FROM Warehouse.Relational.Control_Unstratified
WHERE EndDate IS NULL


CREATE CLUSTERED INDEX CIN_Idx ON #UCBase (CINID)


/*------------------------------------------------------------*/
------------------Finding the Brands to Track-------------------
/*------------------------------------------------------------*/
IF OBJECT_ID ('tempdb..#Brands') IS NOT NULL DROP TABLE #Brands
SELECT	BrandID,
	BrandName
INTO #Brands 
FROM Relational.Brand
WHERE BrandID IN (SELECT BrandID FROM Relational.PartnerTrigger_UC_Brands WHERE CampaignID = @CampaignID)



/*------------------------------------------------------------*/
------------Finding ConsumerCombinationIDs for Brands-----------
/*------------------------------------------------------------*/
IF OBJECT_ID ('tempdb..#CCombIDs') IS NOT NULL DROP TABLE #CCombIDs
SELECT	DISTINCT
	ConsumerCombinationID
INTO #CCombIDs
FROM Relational.ConsumerCombination cc (NOLOCK)
INNER JOIN #Brands b
	ON cc.BrandID = b.BrandID 

CREATE CLUSTERED INDEX CCID_Idx ON #CCombIDs (ConsumerCombinationID)

/*-------------------------------------------------------------*/
----------------Finding Transactions for Brands-----------------
/*-------------------------------------------------------------*/
--ConsumerTrans 
IF OBJECT_ID ('tempdb..#Customers1') IS NOT NULL DROP TABLE #Customers1
SELECT	DISTINCT
	aeb.FanID
INTO #Customers1
FROM Relational.ConsumerTransaction ct (NOLOCK)
INNER JOIN #CCombIDs cc
	ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
INNER JOIN #UCBase aeb
	ON ct.CINID = aeb.CINID
WHERE TranDate BETWEEN DATEADD(DD,-@DaysWorthTransactions-3,CAST(GETDATE() AS DATE)) AND CAST(GETDATE() AS DATE)


--ConsumerCombination
IF OBJECT_ID ('tempdb..#Customers2') IS NOT NULL DROP TABLE #Customers2
SELECT	DISTINCT
	aeb.FanID
INTO #Customers2
FROM Relational.ConsumerTransactionHolding ct (NOLOCK)
INNER JOIN #CCombIDs cc
	ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
INNER JOIN #UCBase aeb
	ON ct.CINID = aeb.CINID
WHERE TranDate BETWEEN DATEADD(DD,-@DaysWorthTransactions-3,CAST(GETDATE() AS DATE)) AND CAST(GETDATE() AS DATE)



/*-------------------------------------------------------------*/
--------------------Collating the Results------------------------
/*-------------------------------------------------------------*/
ALTER INDEX IDX_FanID ON Relational.PartnerTrigger_UC_Members DISABLE
ALTER INDEX IDX_CampID ON Relational.PartnerTrigger_UC_Members DISABLE


DELETE FROM Relational.PartnerTrigger_UC_Members WHERE CampaignID = @CampaignID


INSERT INTO Relational.PartnerTrigger_UC_Members
SELECT	DISTINCT
	FanID,
	@CampaignID as CampaignID
FROM	(
	SELECT	FanID
	FROM #Customers1
	UNION
	SELECT	FanID
	FROM #Customers2
	)a

ALTER INDEX IDX_FanID ON Relational.PartnerTrigger_UC_Members REBUILD
ALTER INDEX IDX_CampID ON Relational.PartnerTrigger_UC_Members REBUILD


END