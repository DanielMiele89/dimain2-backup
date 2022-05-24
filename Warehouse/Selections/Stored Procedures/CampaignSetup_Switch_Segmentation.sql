-- =============================================
-- Author:		<William Allen>
-- Create date: <20/10/2021>
-- Description:	<Segmentation for MyRewards Switch Programme>
-- =============================================
CREATE PROCEDURE Selections.CampaignSetup_Switch_Segmentation

AS
BEGIN
	
	SET NOCOUNT ON;


	/*******************************************************************************************************************************************
	--Prepare parameters for sProc to run
	*******************************************************************************************************************************************/
		
	DECLARE @OfferID INT = 9999

	DECLARE @StartDate DATE = (SELECT MIN(EmailDate) FROM warehouse.[Selections].[CampaignSetup_POS] WHERE GETDATE() < EmailDate)

	DECLARE @EndDate DATE =  DATEADD(DAY, 13, @StartDate) 
		
	DECLARE @HasProcesAlreadyRun BIT = 0

	DECLARE	@Time DATETIME = GETDATE()

	DECLARE	@Msg VARCHAR(2048)

	DECLARE	@SSMS BIT = NULL

	/*******************************************************************************************************************************************
	--Check whether this process has already run this selection
	*******************************************************************************************************************************************/

	SELECT	DISTINCT
			@HasProcesAlreadyRun =  1
	FROM Warehouse.[iron].[OfferProcessLog] opl
	WHERE opl.IronOfferID = @OfferID
	AND (opl.ProcessedDate IS NULL OR opl.ProcessedDate > DATEADD(WEEK, -1, @StartDate))
						
	SELECT @Msg = '2.	Check whether this process has already run this selection'
	EXEC Warehouse.[dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT


	/*******************************************************************************************************************************************
	--If process has already run this selection then end here
	*******************************************************************************************************************************************/

		SELECT @Msg = '3.	If process has already run this selection then end here'
		EXEC Warehouse.[dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT

		IF @HasProcesAlreadyRun = 1 RETURN



	/**************************************************************
	--Customers with a bank account (i.e. no credit card customers) and those that live outside NI should be added to the offer
	--BT is the Area for Northern Ireland
	--Blank Postcode seems to be for outside UK 
	--Customers to exclude FROM the cycle as they have an offer assigned within the last 10 months
	**************************************************************/

	
	--Table C
	If Object_ID('tempdb..#CustomersToExclude') IS NOT NULL 
		Drop table #CustomersToExclude
	SELECT	fanId
		,	max(createdDateTime) createdDateTime
	INTO #CustomersToExclude
	FROM Sandbox.WilliamA.SwitchUptake su
	WHERE createdDateTime >=  DATEADD(m, -10, GETDATE()) AND status = 'Completed'
	GROUP BY FANID

	CREATE CLUSTERED INDEX CIX_FANID  ON #CustomersToExclude (FanID)


	IF OBJECT_ID('tempdb..#CustomersWithBankAccount') IS NOT NULL DROP TABLE #CustomersWithBankAccount
	SELECT	cu.FanID
		,	cu.CompositeID
		,	cu.SourceUID
		,	cu.ClubID
	INTO #CustomersWithBankAccount
	FROM Warehouse.[Relational].[Customer] cu
	WHERE cu.CurrentlyActive = 1
	AND EXISTS ( SELECT 1
	FROM [SLC_Repl].[dbo].[IssuerCustomer] ic
	INNER JOIN [SLC_Repl].[dbo].[IssuerBankAccount] iba
	ON ic.ID = iba.IssuerCustomerID
	AND iba.CustomerStatus = 1
	WHERE cu.SourceUID = ic.SourceUID
	AND CONCAT(cu.ClubID, ic.IssuerID) IN (1322, 1381))


	CREATE CLUSTERED INDEX CIX_FANID  ON #CustomersWithBankAccount (FanID)

	--Table A
	If Object_ID('tempdb..#AllEligibleForSwitch') IS NOT NULL 
			Drop table #AllEligibleForSwitch
	SELECT	c.*
	INTO #AllEligibleForSwitch
	FROM Warehouse.relational.customer c
	LEFT join #CustomersToExclude ce
	ON c.FanID = ce.fanId
	JOIN #CustomersWithBankAccount cba
	ON cba.FanID = c.FanID
	WHERE CurrentlyActive = 1
	AND PostArea != 'BT'
	AND PostCode != ''
	AND ce.fanid is null


	CREATE CLUSTERED INDEX CIX_FANID  ON #AllEligibleForSwitch (FanID)

	/******************************************************************************************************************
	--from IronOfferMember, pull a list of customers that are currently on the offer (Table B)
	--Need to update the offer to the correct IronOfferID
	******************************************************************************************************************/

	If Object_ID('tempdb..#currentlyOnSwitchOffer') IS NOT NULL 
		Drop table #currentlyOnSwitchOffer
	SELECT	iom.*
		,	c.FanID
	INTO #currentlyOnSwitchOffer
	FROM Warehouse.Relational.IronOfferMember iom
	JOIN Warehouse.Relational.Customer c
	ON c.CompositeID = iom.CompositeID
	WHERE IronOfferID = @OfferID
	AND iom.EndDate IS NULL


	CREATE NONCLUSTERED INDEX NCIX_currentlyOnSwitchOffer  ON #currentlyOnSwitchOffer (FanID,CompositeID)

	/******************************************************************************************************************
	--Customers that are not currently on the offer but are eligible (In Table A & Not Table B) 
	-- These customers need to be added to OfferMemberAddition to add them
	******************************************************************************************************************/

	
	INSERT INTO Warehouse.iron.OfferMemberAddition	(	CompositeID
													,	IronOfferID
													,	StartDate
													,	EndDate
													,	Date
													,	IsControl	)
	SELECT	AES.CompositeID
		,	@OfferID
		,	@StartDate
		,	NULL
		,	GETDATE()
		,	0
	FROM #AllEligibleForSwitch AES
	LEFT JOIN #currentlyOnSwitchOffer COSO
	ON COSO.FanID = AES.FanID
	WHERE COSO.FanID IS NULL

	/******************************************************************************************************************
	--Customers that are on the offer and have earned (completed) in the last 10 months (In Table B & Table C) 
	--These customers need to be added to OfferMemberClosure to remove them from the offer with an end date of their completed date
	******************************************************************************************************************/


	--Grab the Last start date for every customer on the offer
	If Object_ID('tempdb..#IOMStartDate') IS NOT NULL 
		Drop table #IOMStartDate
	SELECT	COSO.CompositeID
		,	MAX(IOM.StartDate) StartDate
	INTO #IOMStartDate
	FROM Warehouse.Relational.IronOfferMember IOM
	JOIN #currentlyOnSwitchOffer COSO
	ON IOM.CompositeID = COSO.CompositeID
	AND IOM.IronOfferID = @OfferID
	AND IOM.EndDate IS NULL
	GROUP BY COSO.CompositeID

	--Use the start date from above for closure start date
	INSERT INTO warehouse.iron.OfferMemberClosure	(	EndDate
													,	IronOfferID
													,	CompositeID
													,	StartDate	)
	SELECT	@EndDate	
		--cte.createdDateTime
		,	@OfferID
		,	COSO.CompositeID
		,	IOM.StartDate
	FROM #currentlyOnSwitchOffer COSO
	JOIN #CustomersToExclude CTE 
	ON COSO.FanID = CTE.fanId
	JOIN #IOMStartDate iom
	ON iom.CompositeID = COSO.CompositeID

	/******************************************************************************************************************
	--Customers that are on the offer and are no longer eligible where they haven't earned (completed) yet (In Table B & Not Table A & not in table C) 
	--These customers need to be added to OfferMemberClosure to remove them from the offer at the end of the current cycle
	******************************************************************************************************************/


	INSERT INTO warehouse.iron.OfferMemberClosure	(	EndDate
													,	IronOfferID
													,	CompositeID
													,	StartDate	)
	SELECT	@EndDate
		,	@OfferID
		,	COSO.CompositeID
		,	IOM.StartDate
	FROM #currentlyOnSwitchOffer COSO
	LEFT join #AllEligibleForSwitch AES
	ON COSO.FanID = AES.FanID
	LEFT JOIN #CustomersToExclude CTE
	ON COSO.FanID = CTE.fanId
	JOIN #IOMStartDate IOM
	ON IOM.CompositeID = COSO.CompositeID
	WHERE AES.FanID IS NULL
	AND CTE.fanId IS NULL

	/*******************************************************************************************************************************************
	-- Push offers through V&C
	*******************************************************************************************************************************************/

	INSERT INTO Warehouse.[iron].[OfferProcessLog] (IronOfferID
											, IsUpdate
											, Processed
											, ProcessedDate)
		SELECT IronOfferID
			 , IsUpdate
			 , Processed
			 , ProcessedDate
		FROM (SELECT @OfferID AS IronOfferID
		  		   , 0 AS Processed
		  		   , NULL as ProcessedDate) iof
		CROSS JOIN (SELECT 0 AS IsUpdate
					UNION
					SELECT 1 AS IsUpdate) iu
							
		SELECT @Msg = '11.	Push offers through V&C'
		EXEC Warehouse.[dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT





END