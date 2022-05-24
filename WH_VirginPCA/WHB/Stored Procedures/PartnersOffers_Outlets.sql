/*
-- REPLACEs this bunch of stored procedures:
EXEC WHB.PartnersOffers_Outlets

*/
CREATE PROCEDURE [WHB].[PartnersOffers_Outlets]
AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);
	
	DECLARE @StoredProcedureName VARCHAR(100) = OBJECT_NAME(@@PROCID)
		,	@msg VARCHAR(200)
		,	@RowsAffected INT
		,	@Query VARCHAR(MAX)

	EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, 'Started'

	BEGIN TRY

		/*******************************************************************************************************************************************
			1. Fetch all Retail Outlets for Partners on the program
		*******************************************************************************************************************************************/
			
			IF OBJECT_ID('tempdb..#Outlet') IS NOT NULL DROP TABLE #Outlet
			SELECT	ro.PartnerID
				,	ro.ID AS OutletID
				,	ro.MerchantID
				,	ro.Channel	--1 = Online, 2 = Offline
				,	ro.PartnerOutletReference AS OutletReference
				,	LTRIM(RTRIM(fa.Address1)) AS Address1
				,	LTRIM(RTRIM(fa.Address2)) AS Address2
				,	LTRIM(RTRIM(fa.City)) AS City
				,	LTRIM(RTRIM(fa.PostCode)) AS Postcode
				,	CASE
						WHEN REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', '') LIKE '[a-z][0-9][0-9][a-z][a-z]'
							THEN LEFT(REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', ''), 2) + ' ' + RIGHT(LEFT(REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', ''), 3), 1)
						WHEN REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', '') LIKE '[a-z][0-9][0-9][0-9][a-z][a-z]'
							THEN LEFT(REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', ''), 3) + ' ' + RIGHT(LEFT(REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', ''), 4), 1)
						WHEN REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', '') LIKE '[a-z][a-z][0-9][0-9][a-z][a-z]'
							THEN LEFT(REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', ''), 3) + ' ' + RIGHT(LEFT(REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', ''), 4), 1)
						WHEN REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', '') LIKE '[a-z][0-9][a-z][0-9][a-z][a-z]'
							THEN LEFT(REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', ''), 3) + ' ' + RIGHT(LEFT(REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', ''), 4), 1)
						WHEN REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', '') LIKE '[a-z][a-z][0-9][0-9][0-9][a-z][a-z]'
							THEN LEFT(REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', ''), 4) + ' ' + RIGHT(LEFT(REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', ''), 5), 1)
						WHEN REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', '') LIKE '[a-z][a-z][0-9][a-z][0-9][a-z][a-z]'
							THEN LEFT(REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', ''), 4) + ' ' + RIGHT(LEFT(REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', ''), 5), 1)
						ELSE ''
					END AS PostalSector
				,	CASE 
						WHEN PostCode LIKE '[A-Z][0-9]%' THEN LEFT(PostCode, 1)
						ELSE LEFT(PostCode, 2)
					END AS PostArea				 
				,	SUBSTRING(CONVERT(VARCHAR(100), ro.Coordinates), 8, LEN(CONVERT(VARCHAR(100), ro.Coordinates)) - 8) AS Coordinates
			INTO #Outlet
			FROM [SLC_Report].[dbo].[RetailOutlet] ro
			INNER JOIN [SLC_Report].[dbo].[Fan] fa 
				ON ro.FanID = fa.ID
			WHERE EXISTS (	SELECT 1
							FROM [Derived].[Partner] pa
							WHERE ro.PartnerID = pa.PartnerID)

		/*******************************************************************************************************************************************
			2. Insert all Retail Outlets for Partners on the program to [Derived].[Outlet]
		*******************************************************************************************************************************************/

			TRUNCATE TABLE [Derived].[Outlet]
			INSERT INTO [Derived].[Outlet]
			SELECT	o.PartnerID
				,	o.OutletID
				,	o.MerchantID
				,	o.Channel AS ChannelID
				,	CASE
						WHEN o.Channel = 1 THEN 'Online'
						WHEN o.Channel = 2 THEN 'Offline'
						ELSE 'Unknown'
					END AS Channel
				,	o.OutletReference
				,	o.Address1
				,	o.Address2
				,	o.City
				,	o.Postcode
				,	o.PostalSector
				,	o.PostArea
				,	pa.Region
				,	RIGHT(o.Coordinates, LEN(o.Coordinates) -  PATINDEX('% %', o.Coordinates)) AS Latitude
				,	LEFT(o.Coordinates, PATINDEX('% %', o.Coordinates) - 1) AS Longitude
			FROM #Outlet o
			LEFT JOIN [Warehouse].[Staging].[PostArea] pa
				ON o.PostArea = pa.PostAreaCode

			-- log it
			SET @RowsAffected = @@ROWCOUNT;SET @msg = 'Loaded rows to [Derived].[Outlet] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
			EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, @msg

			EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, 'Finished'

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
			INSERT INTO [Monitor].[ErrorLog] (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
			VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

		-- Regenerate an error to return to caller
			SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
			RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

		-- Return a failure
			RETURN -1;

	END CATCH

	RETURN 0; -- should never run

END
