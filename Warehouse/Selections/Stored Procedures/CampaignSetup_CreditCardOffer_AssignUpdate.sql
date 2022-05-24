

/****************************************************************************************************
Author:		Rory Francis
Date:		2020-12-23
Purpose:	Assign the credit card promotion offer to all customers without a credit card & remove
			it from those that have one

Modified Log:

Change No:	Name:			Date:			Description of change:
											
****************************************************************************************************/

CREATE PROCEDURE [Selections].[CampaignSetup_CreditCardOffer_AssignUpdate] (@EmailDate DATE)
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	/*******************************************************************************************************************************************
		1.	Prepare parameters for sProc to run
	*******************************************************************************************************************************************/

		--DECLARE @EmailDate DATE = '2020-12-31'
		DECLARE	@Time DATETIME = GETDATE()
			,	@Msg VARCHAR(2048)
			,	@SSMS BIT = NULL

		DECLARE	@RBSOffer INT = (SELECT ID FROM [SLC_REPL].[dbo].[IronOffer] WHERE Name LIKE '%Credit%Card%Open%Promotion%RBS%' AND (EndDate > @EmailDate OR EndDate IS NULL))
			,	@NatwestOffer INT = (SELECT ID FROM [SLC_REPL].[dbo].[IronOffer] WHERE Name LIKE '%Credit%Card%Open%Promotion%Natwest%' AND (EndDate > @EmailDate OR EndDate IS NULL))

		--SELECT @RBSOffer, @NatwestOffer

		DECLARE	@Start DATETIME = @EmailDate
			,	@End DATETIME = DATEADD(SECOND, -1, CONVERT(DATETIME, @EmailDate))
			,	@Today DATETIME  = GETDATE()
			,	@HasProcesAlreadyRun BIT = 0
							
		SELECT @Msg = '1.	Prepare parameters for sProc to run'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT


	/*******************************************************************************************************************************************
		2.	Check whether this process has already run this selection
	*******************************************************************************************************************************************/

		SELECT	DISTINCT
				@HasProcesAlreadyRun =  1
		FROM [iron].[OfferProcessLog] opl
		WHERE opl.IronOfferID IN (@RBSOffer, @NatwestOffer)
		AND (opl.ProcessedDate IS NULL OR opl.ProcessedDate > DATEADD(WEEK, -1, @EmailDate))
							
		SELECT @Msg = '2.	Check whether this process has already run this selection'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT


	/*******************************************************************************************************************************************
		3.	If process has already run this selection then end here
	*******************************************************************************************************************************************/

		SELECT @Msg = '3.	If process has already run this selection then end here'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT

		IF @HasProcesAlreadyRun = 1 RETURN
							

	/*******************************************************************************************************************************************
		4.	Fetch all currently live customers
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#CurrentlyLiveCustomers') IS NOT NULL DROP TABLE #CurrentlyLiveCustomers
		SELECT	cu.FanID
			,	cu.CompositeID
			,	cu.ClubID
		INTO #CurrentlyLiveCustomers
		FROM [Relational].[Customer] cu
		WHERE cu.CurrentlyActive = 1

		CREATE CLUSTERED INDEX CIX_FanComp ON #CurrentlyLiveCustomers (FanID, CompositeID, ClubID)
							
		SELECT @Msg = '4.	Fetch all currently live customers'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT

	/*******************************************************************************************************************************************
		5.	Fetch all customers that currently have a credit card
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#CreditCardCustomers_Current') IS NOT NULL DROP TABLE #CreditCardCustomers_Current
		SELECT cu.FanID
			 , cu.CompositeID
			 , pa.AdditionDate
			 , pa.RemovalDate
			 , pc.Date
			 , pc.CardTypeID
		INTO #CreditCardCustomers_Current
		FROM [SLC_REPL].[dbo].[Pan] pa
		INNER JOIN #CurrentlyLiveCustomers cu
			ON pa.UserID = cu.FanID
		INNER JOIN [SLC_REPL].[dbo].[PaymentCard] pc
			ON pa.PaymentCardID = pc.ID
		WHERE pc.CardTypeID = 1
		AND RemovalDate IS NULL
							
		SELECT @Msg = '5.	Fetch all customers that currently have a credit card'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT
			

	/*******************************************************************************************************************************************
		6.	Fetch all customers currently on the offer
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#CurrentlyOnOffer') IS NOT NULL DROP TABLE #CurrentlyOnOffer
		SELECT CompositeID
			 , IronOfferID
			 , StartDate
		INTO #CurrentlyOnOffer
		FROM [SLC_REPL].[dbo].[IronOfferMember]
		WHERE IronOfferID IN (@RBSOffer, @NatwestOffer)
		AND EndDate IS NULL
							
		SELECT @Msg = '6.	Fetch all customers currently on the offer'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT
			

	/*******************************************************************************************************************************************
		7.	Fetch all customers that are on the offer but have since opened a credit card
	*******************************************************************************************************************************************/

			/***********************************************************************************************************************
				7.1.	Fetch all customers that are on the offer but have since opened a credit card
			***********************************************************************************************************************/

				IF OBJECT_ID('tempdb..#CustomersToRemove') IS NOT NULL DROP TABLE #CustomersToRemove
				SELECT CompositeID
					 , IronOfferID
					 , StartDate
				INTO #CustomersToRemove
				FROM #CurrentlyOnOffer coo
				WHERE EXISTS (SELECT 1
							  FROM #CreditCardCustomers_Current cc
							  WHERE coo.CompositeID = cc.CompositeID)
							
				SELECT @Msg = '7.1.	Fetch all customers that are on the offer but have since opened a credit card'
				EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT


			/***********************************************************************************************************************
				7.2.	Fetch all customers that are on the offer but have are no longer currently active
			***********************************************************************************************************************/

				INSERT INTO #CustomersToRemove
				SELECT CompositeID
					 , IronOfferID
					 , StartDate
				FROM #CurrentlyOnOffer coo
				WHERE NOT EXISTS (SELECT 1
								  FROM #CurrentlyLiveCustomers clc
								  WHERE coo.CompositeID = clc.CompositeID)
				AND NOT EXISTS (SELECT 1
								FROM #CustomersToRemove ctr
								WHERE coo.CompositeID = ctr.CompositeID)
							
				SELECT @Msg = '7.2.	Fetch all customers that are on the offer but have are no longer currently active'
				EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT

			

	/*******************************************************************************************************************************************
		8.	Fetch all customers that are currently live, do not have a credit card and are not on the offer
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#CustomersToAdd') IS NOT NULL DROP TABLE #CustomersToAdd
		SELECT FanID
			 , CompositeID
		INTO #CustomersToAdd
		FROM #CurrentlyLiveCustomers clc
		WHERE NOT EXISTS (SELECT 1
						  FROM #CurrentlyOnOffer coo
						  WHERE clc.CompositeID = coo.CompositeID)
		AND NOT EXISTS (SELECT 1
						FROM #CreditCardCustomers_Current cc
						WHERE clc.CompositeID = cc.CompositeID)
							
		SELECT @Msg = '8.	Fetch all customers that are currently live, do not have a credit card and are not on the offer'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT
			

	/*******************************************************************************************************************************************
		9.	Insert new customers to OfferMemberAdditions
	*******************************************************************************************************************************************/

		DECLARE @GETDATE DATETIME = GETDATE()

		INSERT INTO [iron].[OfferMemberAddition] (	CompositeID
												,	IronOfferID
												,	StartDate
												,	EndDate
												,	Date
												,	IsControl)
		SELECT cta.CompositeID
			 , CASE
					WHEN ClubID = 132 THEN @NatwestOffer
					WHEN ClubID = 138 THEN @RBSOffer
					ELSE NULL
			   END AS IronOfferID
			 , @Start AS StartDate
			 , NULL AS EndDate
			 , @GETDATE AS Date
			 , 0 AS IsControl
		FROM #CustomersToAdd cta 
		INNER JOIN #CurrentlyLiveCustomers cu
			on cta.CompositeID = cu.CompositeID
							
		SELECT @Msg = '9.	Insert new customers to OfferMemberAdditions'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT
			

	/*******************************************************************************************************************************************
		10.	EndDate customers already on offer that have taken out a credit card
	*******************************************************************************************************************************************/


		INSERT INTO [iron].[OfferMemberClosure] (	EndDate
												,	IronOfferID
												,	CompositeID
												,	StartDate)
		SELECT @End
			 , IronOfferID
			 , CompositeID
			 , StartDate
		FROM #CustomersToRemove
							
		SELECT @Msg = '10.	EndDate customers already on offer that have taken out a credit card'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT
			

	/*******************************************************************************************************************************************
		11.	Push offers through V&C
	*******************************************************************************************************************************************/

		INSERT INTO [iron].[OfferProcessLog] (IronOfferID
											, IsUpdate
											, Processed
											, ProcessedDate)
		SELECT IronOfferID
			 , IsUpdate
			 , Processed
			 , ProcessedDate
		FROM (SELECT @NatwestOffer AS IronOfferID
		  		   , 0 AS Processed
		  		   , NULL as ProcessedDate
			  UNION
			  SELECT @RBSOffer AS IronOfferID
		  		   , 0 AS Processed
		  		   , NULL as ProcessedDate) iof
		CROSS JOIN (SELECT 0 AS IsUpdate
					UNION
					SELECT 1 AS IsUpdate) iu
							
		SELECT @Msg = '11.	Push offers through V&C'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT

END