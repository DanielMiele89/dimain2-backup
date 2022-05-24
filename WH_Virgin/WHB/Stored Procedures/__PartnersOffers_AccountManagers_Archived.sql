-- =============================================
--	Author:		
--	Create date: 
--	Description:	

--	Updates:
-- =============================================

CREATE PROCEDURE [WHB].[__PartnersOffers_AccountManagers_Archived]
	
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY


	EXEC [Monitor].[ProcessLog_Insert] 'PartnersOffers_AccountManagers', 'Started'

		-- 2.1. Fetch current partner details from [APW].[Retailer]
		IF OBJECT_ID('tempdb..#PartnerAccountManager') IS NOT NULL DROP TABLE #PartnerAccountManager
		SELECT *
		INTO #PartnerAccountManager
		FROM [Selections].[PartnerAccountManager]
		WHERE [Selections].[PartnerAccountManager].[EndDate] IS NULL


		-- 2.2. Fetch partner details from [APW].[Retailer]
		IF OBJECT_ID ('tempdb..#Retailer') IS NOT NULL DROP TABLE #Retailer
		SELECT *
		INTO #Retailer
		FROM Warehouse.[APW].[Retailer]
		WHERE [Warehouse].[APW].[Retailer].[AccountManager] != ''	


		-- 3.	Add missing retailers
		IF OBJECT_ID('tempdb..#MissingRetailer') IS NOT NULL DROP TABLE #MissingRetailer
		SELECT [Warehouse].[APW].[Retailer].[ID] AS RetailerID
				, [Warehouse].[APW].[Retailer].[RetailerName]
				, [Warehouse].[APW].[Retailer].[AccountManager]
		INTO #MissingRetailer
		FROM Warehouse.[APW].[Retailer] re
		WHERE [Warehouse].[APW].[Retailer].[AccountManager] != ''
		AND NOT EXISTS (SELECT 1
						FROM #PartnerAccountManager pam
						WHERE #PartnerAccountManager.[re].ID = pam.PartnerID)	
						
		INSERT INTO #MissingRetailer
		SELECT #MissingRetailer.[pa].ID
				, #MissingRetailer.[pa].Name
				, mr.AccountManager
		FROM #MissingRetailer mr
		INNER JOIN Warehouse.[iron].[PrimaryRetailerIdentification] pri
			ON mr.RetailerID = #MissingRetailer.[pri].PrimaryPartnerID
		INNER JOIN [SLC_Report].[dbo].[Partner] pa
			ON #MissingRetailer.[pri].PartnerID = #MissingRetailer.[pa].ID
		WHERE NOT EXISTS (SELECT 1
							FROM #PartnerAccountManager pam
							WHERE #PartnerAccountManager.[pa].ID = pam.PartnerID)
	
		INSERT INTO [Selections].[PartnerAccountManager]
		SELECT #MissingRetailer.[RetailerID]
				, #MissingRetailer.[RetailerName]
				, #MissingRetailer.[AccountManager]
				, GETDATE()
				, NULL
			FROM #MissingRetailer


		--4.	Update retailers who have changed AM
		IF OBJECT_ID ('tempdb..#UpdatedAccountManagers') IS NOT NULL DROP TABLE #UpdatedAccountManagers
		SELECT pam.ID
				, r.ID AS RetailerID
				, r.RetailerName AS RetailerName
				, pam.AccountManager AS CurrentAccountManager
				, r.AccountManager AS NewAccountManager
		INTO #UpdatedAccountManagers
		FROM #Retailer r
		INNER JOIN #PartnerAccountManager pam
			ON pam.PartnerID = r.ID
			AND r.AccountManager != pam.AccountManager
		WHERE r.AccountManager != 'Nick'
		AND r.AccountManager != 'Nick / Tom'

		INSERT INTO #UpdatedAccountManagers
		SELECT pam.ID
				, pa.ID
				, pa.Name
				, uam.CurrentAccountManager
				, uam.NewAccountManager
		FROM #UpdatedAccountManagers uam
		INNER JOIN Warehouse.[iron].[PrimaryRetailerIdentification] pri
			ON uam.RetailerID = #UpdatedAccountManagers.[pri].PrimaryPartnerID
		INNER JOIN [SLC_Report].[dbo].[Partner] pa
			ON #UpdatedAccountManagers.[pri].PartnerID = #UpdatedAccountManagers.[pa].ID
		INNER JOIN #PartnerAccountManager pam
			ON pa.ID = pam.PartnerID

		UPDATE pam
			SET [Selections].[PartnerAccountManager].[EndDate] = DATEADD(DAY, -1, GETDATE())
		FROM [Selections].[PartnerAccountManager] pam
		INNER JOIN #UpdatedAccountManagers uam
			ON #UpdatedAccountManagers.[pam].ID = uam.ID
	
		INSERT INTO [Selections].[PartnerAccountManager]
		SELECT #UpdatedAccountManagers.[RetailerID]
				, #UpdatedAccountManagers.[RetailerName]
				, #UpdatedAccountManagers.[NewAccountManager]
				, GETDATE()
				, NULL
		FROM #UpdatedAccountManagers


	EXEC [Monitor].[ProcessLog_Insert] 'PartnersOffers_AccountManagers', 'Finished'


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
			
	-- Insert the error into the ErrorLog
	INSERT INTO Staging.ErrorLog ([Staging].[ErrorLog].[ErrorDate], [Staging].[ErrorLog].[ProcedureName], [Staging].[ErrorLog].[ErrorLine], [Staging].[ErrorLog].[ErrorMessage], [Staging].[ErrorLog].[ErrorNumber], [Staging].[ErrorLog].[ErrorSeverity], [Staging].[ErrorLog].[ErrorState])
	VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

	-- Regenerate an error to return to caller
	SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
	RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

	-- Return a failure
	RETURN -1;
END CATCH

RETURN 0; -- should never run

END