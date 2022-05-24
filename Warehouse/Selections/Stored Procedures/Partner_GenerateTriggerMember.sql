
/*
Title:   Partner Trigger Member Generation Code
Purpose: To automatically generate a list of customers who have shopped with
	 predefined brands during a certain period of time.
Date:	 09-04-2014
Author:  Suraj Chahal

Before Running this Code please make sure you have entries for in the following tables:
	Relational.PartnerTrigger_Campaigns
	Relational.PartnerTrigger_Brands
*/

CREATE PROCEDURE [Selections].[Partner_GenerateTriggerMember]
			(
			@CampaignID INT
			)
WITH EXECUTE AS OWNER
AS

BEGIN

	/*--------------------------------------------------------------*/
	---------------------Declaring the Variables---------------------
	/*--------------------------------------------------------------*/

	DECLARE	@DaysWorthTransactions INT
				
	SET @DaysWorthTransactions = (SELECT DaysWorthTransactions FROM Relational.PartnerTrigger_Campaigns WHERE CampaignID = @CampaignID) 

	/*------------------------------------------------------------*/
	---------------Find the activated Emailable Base---------------
	/*------------------------------------------------------------*/

	IF OBJECT_ID ('tempdb..#ActiveEmailableBase') IS NOT NULL DROP TABLE #ActiveEmailableBase
	SELECT c.FanID
		 , cl.CINID
	INTO #ActiveEmailableBase
	FROM Relational.Customer c
	INNER JOIN Relational.CINList cl
		ON cl.CIN = c.SourceUID
	INNER JOIN Relational.CustomerPaymentMethodsAvailable cpm
		ON c.FanID = cpm.FanID
		AND cpm.EndDate IS NULL
		AND cpm.PaymentMethodsAvailableID <> 3
	WHERE	c.CurrentlyActive = 1

	CREATE CLUSTERED INDEX CIN_Idx ON #ActiveEmailableBase (CINID)

	/*------------------------------------------------------------*/
	------------------Finding the Brands to Track-------------------
	/*------------------------------------------------------------*/

	IF OBJECT_ID ('tempdb..#Brands') IS NOT NULL DROP TABLE #Brands
	SELECT BrandID
		 , BrandName
	INTO #Brands 
	FROM Relational.Brand
	WHERE BrandID IN (SELECT BrandID FROM Relational.PartnerTrigger_Brands WHERE CampaignID = @CampaignID)

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
	FROM Relational.ConsumerTransaction_MyRewards ct (NOLOCK)
	INNER JOIN #CCombIDs cc
		ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
	INNER JOIN #ActiveEmailableBase aeb
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
	INNER JOIN #ActiveEmailableBase aeb
		ON ct.CINID = aeb.CINID
	WHERE TranDate BETWEEN DATEADD(DD,-@DaysWorthTransactions-3,CAST(GETDATE() AS DATE)) AND CAST(GETDATE() AS DATE)

	IF OBJECT_ID ('tempdb..#Customers3') IS NOT NULL DROP TABLE #Customers3
	SELECT	DISTINCT
		aeb.FanID
	INTO #Customers3
	FROM Relational.ConsumerTransaction_CreditCardHolding ct (NOLOCK)
	INNER JOIN #CCombIDs cc
		ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
	INNER JOIN #ActiveEmailableBase aeb
		ON ct.CINID = aeb.CINID
	WHERE TranDate BETWEEN DATEADD(DD,-@DaysWorthTransactions-3,CAST(GETDATE() AS DATE)) AND CAST(GETDATE() AS DATE)

	/*-------------------------------------------------------------*/
	--------------------Collating the Results------------------------
	/*-------------------------------------------------------------*/

	ALTER INDEX IDX_FanID ON Relational.PartnerTrigger_Members DISABLE
	ALTER INDEX IDX_CampID ON Relational.PartnerTrigger_Members DISABLE

	DELETE FROM Relational.PartnerTrigger_Members WHERE CampaignID = @CampaignID

	INSERT INTO Relational.PartnerTrigger_Members
	SELECT	DISTINCT
		  FanID
		, @CampaignID as CampaignID
	FROM	(
		SELECT	FanID
		FROM #Customers1
		UNION
		SELECT	FanID
		FROM #Customers2
		UNION
		SELECT	FanID
		FROM #Customers3
		) a

	ALTER INDEX IDX_FanID ON Relational.PartnerTrigger_Members REBUILD
	ALTER INDEX IDX_CampID ON Relational.PartnerTrigger_Members REBUILD

END



