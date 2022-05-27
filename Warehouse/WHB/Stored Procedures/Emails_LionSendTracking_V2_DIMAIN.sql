CREATE PROCEDURE [WHB].[Emails_LionSendTracking_V2_DIMAIN]
as
Begin

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

/*******************************************************************************************************************************************
	1. Find most recent Email Send Date
*******************************************************************************************************************************************/

	DECLARE @Today DATE = GETDATE()
	DECLARE @EmailSendDate DATE = (SELECT MAX(EmailSendDate) FROM [Staging].[R_0183_LionSendVolumesCheck] WHERE EmailSendDate < @Today)

	IF OBJECT_ID('tempdb..#LionSendID') IS NOT NULL DROP TABLE #LionSendID
	SELECT DISTINCT
		   LionSendID
	INTO #LionSendID
	FROM [Staging].[R_0183_LionSendVolumesCheck] ls
	WHERE EmailSendDate = @EmailSendDate

	IF NOT EXISTS (	SELECT 1
					FROM [Lion].[LionSend_Customers] lsc
					WHERE @EmailSendDate = lsc.EmailSendDate
					AND EXISTS (SELECT 1
								FROM #LionSendID ls
								WHERE lsc.LionSendID = ls.LionSendID))

		BEGIN

			IF OBJECT_ID('tempdb..#LionSend') IS NOT NULL DROP TABLE #LionSend
			SELECT ls.LionSendID
				 , @EmailSendDate AS EmailSendDate
				 , ls.CompositeID
				 , ls.TypeID
				 , ls.ItemID
				 , ls.ItemRank
			INTO #LionSend
			FROM [Lion].[NominatedLionSendComponent] ls
			WHERE EXISTS (	SELECT 1
							FROM #LionSendID lsi
							WHERE ls.LionSendID = lsi.LionSendID)
			UNION
			SELECT ls.LionSendID
				 , @EmailSendDate AS EmailSendDate
				 , ls.CompositeID
				 , ls.TypeID
				 , ls.ItemID
				 , ls.ItemRank
			FROM [Lion].[NominatedLionSendComponent_RedemptionOffers] ls
			WHERE EXISTS (	SELECT 1
							FROM #LionSendID lsi
							WHERE ls.LionSendID = lsi.LionSendID)

			IF OBJECT_ID('tempdb..#LionSend_Customers') IS NOT NULL DROP TABLE #LionSend_Customers
			SELECT DISTINCT
				   ls.LionSendID
				 , ls.EmailSendDate
				 , ls.CompositeID
				 , cu.FanID
				 , cu.ClubID
				 , CASE WHEN CustomerSegment LIKE '%v%' THEN 1 ELSE 0 END AS IsLoyalty
			INTO #LionSend_Customers
			FROM #LionSend ls
			INNER JOIN [Relational].[Customer] cu
				ON ls.CompositeID = cu.CompositeID
			INNER JOIN [Relational].[Customer_RBSGSegments] rbsg
				ON cu.FanID = rbsg.FanID
				AND rbsg.EndDate IS NULL
			WHERE NOT EXISTS (	SELECT 1
								FROM [Lion].[LionSend_Customers] lsc
								WHERE ls.LionSendID = lsc.LionSendID
								AND ls.CompositeID = lsc.CompositeID)

			IF OBJECT_ID('tempdb..#LionSend_Offers') IS NOT NULL DROP TABLE #LionSend_Offers
			SELECT ls.LionSendID
				 , ls.EmailSendDate
				 , ls.CompositeID
				 , cu.FanID
				 , ls.TypeID
				 , ls.ItemID
				 , ls.ItemRank
			INTO #LionSend_Offers
			FROM #LionSend ls
			INNER JOIN [Relational].[Customer] cu
				ON ls.CompositeID = cu.CompositeID
			WHERE NOT EXISTS (	SELECT 1
								FROM [Lion].[LionSend_Offers] lso
								WHERE ls.LionSendID = lso.LionSendID
								AND ls.CompositeID = lso.CompositeID)
				  
			DROP INDEX [CSX_LionSendOffers_All] ON [Lion].[LionSend_Offers]
			DROP INDEX [CSX_LionSendCustomers_All] ON [Lion].[LionSend_Customers]
			Alter Index IX_LionSendCustomers_LionCampaignClubLoyaltyFan ON [Lion].[LionSend_Customers] Disable

			-- Initial populatiON of tables

			Insert INTO [Lion].[LionSend_Customers] (LionSendID
														, EmailSendDate
														, CompositeID
														, FanID
														, ClubID
														, IsLoyalty)
			SELECT LionSendID
				 , EmailSendDate
				 , CompositeID
				 , FanID
				 , ClubID
				 , IsLoyalty
			FROM #LionSend_Customers


			Insert INTO [Lion].[LionSend_Offers] (LionSendID
													 , EmailSendDate
													 , CompositeID
													 , FanID
													 , TypeID
													 , ItemID
													 , OfferSlot)
			SELECT LionSendID
				 , EmailSendDate
				 , CompositeID
				 , FanID
				 , TypeID
				 , ItemID
				 , ItemRank
			FROM #LionSend_Offers

			Alter Index IX_LionSendCustomers_LionCampaignClubLoyaltyFan ON [Lion].[LionSend_Customers] REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212

			-- update campaign key info

			IF OBJECT_ID('tempdb..#EmailCampaign') IS NOT NULL DROP TABLE #EmailCampaign
			SELECT ec.CampaignKey
				 , CampaignName
				 , SendDate
				 , Case
					WHEN CampaignName LIKE '%NWC%' Or CampaignName LIKE '%NatWest%' THEN 132
					WHEN CampaignName LIKE '%NWP%' Or CampaignName LIKE '%NatWest%' THEN 132
					WHEN CampaignName LIKE '%RBSC%' Or CampaignName LIKE '%RBS%' THEN 138
					WHEN CampaignName LIKE '%RBSP%' Or CampaignName LIKE '%RBS%' THEN 138
				   END AS ClubID
				 , Case
					WHEN CampaignName LIKE '%NWC%' Or CampaignName LIKE '%Core%' THEN 0
					WHEN CampaignName LIKE '%NWP%' Or CampaignName LIKE '%Private%' THEN 1
					WHEN CampaignName LIKE '%RBSC%' Or CampaignName LIKE '%Core%' THEN 0
					WHEN CampaignName LIKE '%RBSP%' Or CampaignName LIKE '%Private%' THEN 1
				   END AS IsLoyalty
				 , CASE WHEN PatIndex('%LSID%', CampaignName) > 0 THEN Substring(CampaignName, PatIndex('%LSID%', CampaignName) + 4, 3) ELSE Null END AS LionSendID
			INTO #EmailCampaign
			FROM Relational.EmailCampaign ec
			WHERE CampaignName LIKE '%Newsletter_LSID[0-9][0-9][0-9]_[0-9]%'
			AND CampaignName NOT LIKE 'TEST%'

			Update ls
			Set ls.CampaignKey = ec.CampaignKey
			FROM [Lion].[LionSend_Customers] ls
			INNER JOIN #EmailCampaign ec
				ON ls.LionSendID = ec.LionSendID
				AND ls.IsLoyalty = ec.IsLoyalty
				AND ls.ClubID = ec.ClubID
			WHERE ls.CampaignKey IS NULL
	

			-- update sent & opened
	
			IF OBJECT_ID('tempdb..#EmailNotSent') IS NOT NULL DROP TABLE #EmailNotSent
			SELECT lsc.CampaignKey
				 , lsc.FanID
			INTO #EmailNotSent
			FROM [Lion].[LionSend_Customers] lsc
			WHERE lsc.EmailSent = 0

			Create Clustered Index CIX_EmailNotSent_FanID ON #EmailNotSent (CampaignKey, FanID)
	

			IF OBJECT_ID('tempdb..#EmailSent') IS NOT NULL DROP TABLE #EmailSent
			SELECT DISTINCT
				   ee.CampaignKey
				 , ee.FanID
			INTO #EmailSent
			FROM #EmailNotSent ens
			INNER JOIN Relational.EmailEvent ee
				ON ens.FanID = ee.FanID
				AND ens.CampaignKey = ee.CampaignKey

			Update lsc
			Set EmailSent = 1
			FROM [Lion].[LionSend_Customers] lsc
			INNER JOIN #EmailSent es
				ON lsc.CampaignKey = es.CampaignKey
				AND lsc.FanID = es.FanID
			WHERE EmailSent = 0
	
			IF OBJECT_ID('tempdb..#EmailNotOpened') IS NOT NULL DROP TABLE #EmailNotOpened
			SELECT lsc.CampaignKey
				 , lsc.FanID
			INTO #EmailNotOpened
			FROM [Lion].[LionSend_Customers] lsc
			WHERE lsc.EmailOpened = 0

			Create Clustered Index CIX_EmailNotOpened_CampaignKeyFanID ON #EmailNotOpened (CampaignKey, FanID)


			IF OBJECT_ID('tempdb..#EmailOpens') IS NOT NULL DROP TABLE #EmailOpens
			SELECT ee.CampaignKey
				 , ee.FanID
				 , Min(EventDate) AS EventDate
			INTO #EmailOpens
			FROM #EmailNotOpened eno
			INNER JOIN Relational.EmailEvent ee
				ON eno.CampaignKey = ee.CampaignKey
				AND eno.FanID = ee.FanID
			WHERE ee.EmailEventCodeID = 1301
			Group by ee.CampaignKey
				   , ee.FanID

			Update lsc
			Set EmailOpened = 1
			  , EmailOpenedDate = EventDate
			FROM [Lion].[LionSend_Customers] lsc
			INNER JOIN #EmailOpens eo
				ON lsc.CampaignKey = eo.CampaignKey
				AND lsc.FanID = eo.FanID
			WHERE EmailOpened = 0
		

			CREATE NONCLUSTERED COLUMNSTORE INDEX [CSX_LionSendOffers_All] ON [Lion].[LionSend_Offers] ([LionSendID], [EmailSendDate], [CompositeID], [FanID], [TypeID], [ItemID], [OfferSlot])  ON Warehouse_Columnstores
			CREATE NONCLUSTERED COLUMNSTORE INDEX [CSX_LionSendCustomers_All] ON [Lion].[LionSend_Customers] ([LionSendID], [EmailSendDate], [CampaignKey], [CompositeID], [FanID], [ClubID], [IsLoyalty], [EmailSent], [EmailOpened], [EmailOpenedDate])  ON Warehouse_Columnstores

		End	--	If NOT EXISTS (SELECT 1 FROM Lion.LionSend_Customers WHERE LionSendID = @LionSendID) AND @EmailSendDate Is NOT Null AND DateDiff(day, @EmailSendDate, Convert(Date, GetDate())) = 1
 
	RETURN 0; -- normal exit here

END TRY
BEGIN CATCH		
		
	-- Grab the error details
	SELECT  
		@ERROR_NUMBER = ERROR_NUMBER(), 
		@ERROR_SEVERITY = ERROR_SEVERITY(), 
		@ERROR_STATE = ERROR_STATE(), 
		@ERROR_PROCEDURE = ERROR_PROCEDURE(),  
		@ERROR_LINE = ERROR_LINE(),   
		@ERROR_MESSAGE = ERROR_MESSAGE();
	SET @ERROR_PROCEDURE = ISNULL(@ERROR_PROCEDURE, OBJECT_NAME(@@PROCID))

	IF @@TRANCOUNT > 0 ROLLBACK TRAN;
			
	-- Insert the error INTO the ErrorLog
	INSERT INTO Staging.ErrorLog (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
	VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

	-- Regenerate an error to return to caller
	SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
	RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

	-- Return a failure
	RETURN -1;
END CATCH

RETURN 0; -- should never run

End





	-- highlighting new offers

	--IF OBJECT_ID('tempdb..#LionSend_PreviousOffers') IS NOT NULL DROP TABLE #LionSend_PreviousOffers
	--SELECT DISTINCT
	--	   TypeID
	--	 , ItemID
	--INTO #LionSend_PreviousOffers
	--FROM [Lion].[LionSend_Offers]
	--WHERE LionSendID < 550


	--IF OBJECT_ID('tempdb..#OfferPrioritisation') IS NOT NULL DROP TABLE #OfferPrioritisation
	--SELECT op.PartnerID
	--	 , op.IronOfferID
	--	 , Case
	--			WHEN op.EmailDate = iof.StartDate THEN 1
	--			Else 0
	--	   END AS NewOffer
	--INTO #OfferPrioritisation
	--FROM Selections.OfferPrioritisatiON op
	--INNER JOIN Relational.IronOffer iof
	--	ON op.IronOfferID = iof.IronOfferID
	--WHERE EmailDate = '2018-11-08'

	--IF OBJECT_ID('tempdb..#LionSend_CurrentOffers') IS NOT NULL DROP TABLE #LionSend_CurrentOffers
	--SELECT DISTINCT
	--	   TypeID
	--	 , ItemID
	--INTO #LionSend_CurrentOffers
	--FROM [Lion].[LionSend_Offers]
	--WHERE LionSendID = 551

	--SELECT op.PartnerID
	--	 , op.IronOfferID
	--	 , op.NewOffer
	--	 , lsp.ItemID
	--	 , lsc.ItemID
	--	 , Case
	--			WHEN op.NewOffer = 1 AND lsc.ItemID IS NULL THEN 1
	--			Else 0
	--	   END AS  NewOfferMissing
	--	 , Case
	--			WHEN op.NewOffer = 0 AND lsc.ItemID IS NULL AND lsp.ItemID Is NOT Null THEN 1
	--			Else 0
	--	   END AS ExistingOfferMissing_InPrevious
	--	 , Case
	--			WHEN op.NewOffer = 0 AND lsc.ItemID IS NULL AND lsp.ItemID IS NULL THEN 1
	--			Else 0
	--	   END AS ExistingOfferMissing_NotInPrevious
	--FROM #OfferPrioritisatiON op
	--Left join #LionSend_PreviousOffers lsp
	--	ON op.IronOfferID = lsp.ItemID
	--	AND lsp.TypeID = 1
	--Left join #LionSend_CurrentOffers lsc
	--	ON op.IronOfferID = lsc.ItemID
	--	AND lsc.TypeID = 1
	--Order by ExistingOfferMissing_NotInPrevious
	--	   , ExistingOfferMissing_InPrevious
	--	   , NewOfferMissing