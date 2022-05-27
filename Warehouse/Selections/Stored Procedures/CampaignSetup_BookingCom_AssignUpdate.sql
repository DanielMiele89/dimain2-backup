

/****************************************************************************************************
Author:		William Allen
Date:		2022-04-26
Purpose:	Assign Booking.com offer to all active customers
			take bespoke customers for the first 2 cycles 
			5 %
			10 %
			then all customers


Modified Log:

Change No:	Name:			Date:			Description of change:
											
****************************************************************************************************/

CREATE PROCEDURE [Selections].[CampaignSetup_BookingCom_AssignUpdate] (@EmailDate DATE)
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	/*******************************************************************************************************************************************
		1.	Prepare parameters for sProc to run
	*******************************************************************************************************************************************/

		--DECLARE @EmailDate DATE = '2022-05-24'
		DECLARE	@Time DATETIME = GETDATE()
			,	@Msg VARCHAR(2048)
			,	@SSMS BIT = NULL

		DECLARE @BOOKINGCOM INT = 26008


		DECLARE	@Start DATETIME = @EmailDate
			,	@End DATETIME = DATEADD(SECOND, -1, CONVERT(DATETIME, @EmailDate))
			,	@Today DATETIME  = GETDATE()
			,	@HasProcesAlreadyRun BIT = 0
							
		SELECT @Msg = '1. Prepare parameters for sProc to run'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT


	/*******************************************************************************************************************************************
		2.	Check whether this process has already run this selection
	*******************************************************************************************************************************************/

		SELECT	DISTINCT
				@HasProcesAlreadyRun =  1
		FROM [iron].[OfferProcessLog] opl
		WHERE opl.IronOfferID = @BOOKINGCOM
		AND (opl.ProcessedDate IS NULL OR opl.ProcessedDate > DATEADD(WEEK, -1, @EmailDate))
							
		SELECT @Msg = '2. Check whether this process has already run this selection'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT


	/*******************************************************************************************************************************************
		3.	If process has already run this selection then end here
	*******************************************************************************************************************************************/

		SELECT @Msg = '3. If process has already run this selection then end here'
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
							
		SELECT @Msg = '4. Fetch all currently live customers'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT


	/*******************************************************************************************************************************************
		5.	Fetch all customers currently on the offer
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#CurrentlyOnOffer') IS NOT NULL DROP TABLE #CurrentlyOnOffer
		SELECT CompositeID
			 , IronOfferID
			 , StartDate
		INTO #CurrentlyOnOffer
		FROM [SLC_REPL].[dbo].[IronOfferMember]
		WHERE IronOfferID = @BOOKINGCOM
		AND EndDate IS NULL
							
		SELECT @Msg = '5. Fetch all customers currently on the offer'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT
			

	/*******************************************************************************************************************************************
		6.	Fetch all customers that are on the offer but are no longer currently active
	*******************************************************************************************************************************************/
				DROP TABLE IF EXISTS #CustomersToRemove
				SELECT CompositeID
					 , IronOfferID
					 , StartDate
				INTO #CustomersToRemove
				FROM #CurrentlyOnOffer coo
				WHERE NOT EXISTS (SELECT 1
								  FROM #CurrentlyLiveCustomers clc
								  WHERE coo.CompositeID = clc.CompositeID)
				--AND NOT EXISTS (SELECT 1
				--				FROM #CustomersToRemove ctr
				--				WHERE coo.CompositeID = ctr.CompositeID)
							
				SELECT @Msg = '6. Fetch all customers that are on the offer but are no longer currently active'
				EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT


	/*******************************************************************************************************************************************
		7.	Fetch all customers that are currently live and are not on the offer
	*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#CustomersToAdd') IS NOT NULL DROP TABLE #CustomersToAdd
	CREATE TABLE #CustomersToAdd (
				FanID INT
			,	CompositeID BIGINT
			)
			
	IF @EmailDate = '2022-05-24'
		INSERT INTO #CustomersToAdd
		SELECT FanID
			 , CompositeID
		FROM #CurrentlyLiveCustomers clc
		WHERE  EXISTS (SELECT 1
						  FROM sandbox.patrickm.travelselection ts
						  WHERE clc.fanID = ts.FanID
						  and SelectionPlanRollout = 1)
	IF @EmailDate = '2022-06-16'
		INSERT INTO #CustomersToAdd
		SELECT FanID
			 , CompositeID
		FROM #CurrentlyLiveCustomers clc
		WHERE  EXISTS (SELECT 1
						  FROM sandbox.patrickm.travelselection ts
						  WHERE clc.fanID = ts.FanID
						  and (SelectionPlanRollout = 1
						  or SelectionPlanRollout = 2)
						)
	IF @EmailDate = '2022-06-30'
		INSERT INTO #CustomersToAdd
		SELECT FanID
			 , CompositeID
		FROM #CurrentlyLiveCustomers clc
		WHERE  EXISTS (SELECT 1
						  FROM sandbox.patrickm.travelselection ts
						  WHERE clc.fanID = ts.FanID
					)
					
					
		SELECT @Msg = '7. Fetch all customers that are currently live and are not on the offer'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT
			

	/*******************************************************************************************************************************************
		8.	Insert new customers to OfferMemberAdditions
	*******************************************************************************************************************************************/

		DECLARE @GETDATE DATETIME = GETDATE()

		INSERT INTO [iron].[OfferMemberAddition] (	CompositeID
												,	IronOfferID
												,	StartDate
												,	EndDate
												,	Date
												,	IsControl)
		SELECT cta.CompositeID
			 , @BOOKINGCOM AS IronOfferID
			 , @Start AS StartDate
			 , NULL AS EndDate
			 , @GETDATE AS Date
			 , 0 AS IsControl
		FROM #CustomersToAdd cta 
							
		SELECT @Msg = '8. Insert new customers to OfferMemberAdditions'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT
			

	/*******************************************************************************************************************************************
		9.	EndDate customers already on offer that have taken out a credit card
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
							
		SELECT @Msg = '9. EndDate customers already on offer that have taken out a credit card'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT
			

	/*******************************************************************************************************************************************
		10.	Push offers through V&C
	*******************************************************************************************************************************************/

		INSERT INTO [iron].[OfferProcessLog] (IronOfferID
											, IsUpdate
											, Processed
											, ProcessedDate)
		SELECT IronOfferID
			 , IsUpdate
			 , Processed
			 , ProcessedDate
		FROM (SELECT @BOOKINGCOM AS IronOfferID
		  		   , 0 AS Processed
		  		   , NULL as ProcessedDate
			) iof
		CROSS JOIN (SELECT 0 AS IsUpdate
					UNION
					SELECT 1 AS IsUpdate) iu
							
		SELECT @Msg = '10. Push offers through V&C'
		EXEC [dbo].[oo_TimerMessageV2] @Msg, @Time OUTPUT, @SSMS OUTPUT

END
