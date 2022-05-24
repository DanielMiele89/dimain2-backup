
-- =============================================
--	Author:			Rory Francis
--	Create date:	Jan 1st 2021
--	Description:	To Build the Customer table first to a staging table for changes between yesterdays data to be record, then after a series of WHB SPs, load to Derived.Customer
					
--	Updates:		

-- =============================================

CREATE PROCEDURE [WHB].[Customer_CustomerStaging]

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
			1.	Find customers who have hard bounced or unsubscribed
		*******************************************************************************************************************************************/

			/***************************************************************************************************************************************
				1.1.	Find customers who have hard bounced
			***************************************************************************************************************************************/

				/***********************************************************************************************************************************
					1.1.1.	Find customers who have ever had a hard bounce event
				***********************************************************************************************************************************/

					IF OBJECT_ID('tempdb..#HardbounceCustomers_AllTime') IS NOT NULL DROP TABLE #HardbounceCustomers_AllTime
					SELECT	DISTINCT
							FanID
					INTO #HardbounceCustomers_AllTime
					FROM [Derived].[EmailEvent] ee
					WHERE EmailEventCodeID IN (702)	--	Hard bounce
	
					CREATE CLUSTERED INDEX CIX_FanID ON #HardbounceCustomers_AllTime (FanID)

				/***********************************************************************************************************************************
					1.1.2.	Fetch customers whose most recent email event was a hard bounce
				***********************************************************************************************************************************/

					IF OBJECT_ID('tempdb..#HardbounceCustomers') IS NOT NULL DROP TABLE #HardbounceCustomers
					SELECT	FanID
						,	MAX(EventDate) AS HardBounceDate
						,	1 AS HardBounced
					INTO #HardbounceCustomers
					FROM [Derived].[EmailEvent] ee
					WHERE EXISTS (	SELECT 1
									FROM #HardbounceCustomers_AllTime hb
									WHERE ee.FanID = hb.FanID)
					GROUP BY FanID
					HAVING MAX(EventDate) = MAX(CASE WHEN EmailEventCodeID = 702 THEN EventDate ELSE NULL END)

					CREATE CLUSTERED INDEX CIX_FanID ON #HardbounceCustomers (FanID)

				/***********************************************************************************************************************************
					1.1.3.	Remove customers who have changed their registered email address since hard bouncing
				***********************************************************************************************************************************/
				
					DELETE hb
					FROM #HardbounceCustomers hb
					INNER JOIN [Derived].[Customer_EmailAddressChanges] eac
						ON hb.FanID = eac.FanID
					WHERE eac.DateChanged > hb.HardBounceDate

			/***************************************************************************************************************************************
				1.2.	Find customers who have unsubscribe through their email provider
			***************************************************************************************************************************************/

				IF OBJECT_ID('tempdb..#Unsubscribed') IS NOT NULL DROP TABLE #Unsubscribed
				SELECT	DISTINCT
						FanID
					,	1 AS Unsubscribed
				INTO #Unsubscribed
				FROM [Derived].[EmailEvent] ee
				WHERE EmailEventCodeID IN (301)	--	Unsubscribe

				CREATE CLUSTERED INDEX CIX_FanID ON #Unsubscribed (FanID)


		/*******************************************************************************************************************************************
			2.	Build the customer table from SLC, updating missing values for:
					Current Age
					Email validity
					Postcode Sectors
					Customer regions
					Hardbounce events
					Unsubscribe events
		*******************************************************************************************************************************************/
		
			/***************************************************************************************************************************************
				2.1.	Build intial customer table, updating missing values for:
							Current Age
							Current Age Band
							Email validity
							Tidying postcodes
							Post Code District
							Hardbounce events
							Unsubscribe events
			***************************************************************************************************************************************/

				IF OBJECT_ID('tempdb..#Customer_LookupFanID') IS NOT NULL DROP TABLE #Customer_LookupFanID
				SELECT	DISTINCT
						CustomerID AS CustomerGUID
					,	FanID
				INTO #Customer_LookupFanID
				FROM [WH_AllPublishers].[Derived].[CustomerIDs] ci
				WHERE ci.CustomerIDTypeID = 2
				AND ci.PublisherID = 182
	
				DECLARE @AgeCurrentDate INT = CONVERT(CHAR(8), GETDATE(), 112)

				IF OBJECT_ID('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer;
				SELECT	ROW_NUMBER() OVER (ORDER BY cu.CustomerID) AS ID
					,	cu.CustomerGUID
					,	FanID = clu.FanID
					,	182 AS ClubID
					,	clu.FanID - 10000000 AS CompositeID
					,	CONVERT(VARCHAR(64),  cu.CustomerGUID) AS SourceUID
					,	cu.EmailAddress AS Email
					,	[WH_AllPublishers].[dbo].[IsEmailStructureValid](cu.EmailAddress) AS EmailStructureValid
					,	NULL AS MobileTelephone	--	COALESCE(fa.MobileTelephone, '')
					,	NULL AS Title	--	fa.Title
					,	cu.Forename AS FirstName
					,	cu.Surname AS LastName
					,	CONVERT(VARCHAR(50), NULL) AS Address1	--	fa.Address1
					,	CONVERT(VARCHAR(50), NULL) AS Address2	--	fa.Address2
					,	CONVERT(VARCHAR(50), NULL) AS City		--	fa.City
					,	CONVERT(VARCHAR(50), NULL) AS County		--	fa.County
					,	cu2.Postcode AS Postcode
					,	CONVERT(VARCHAR(30), '') AS Region
					,	CASE 
							WHEN cu2.Postcode IS NULL THEN ''
							WHEN cu2.PostcodeSpacePosition = 0 THEN LEFT(cu2.PostCode, 4) 
							ELSE CONVERT(VARCHAR(4), LEFT(cu2.PostCode, cu2.PostcodeSpacePosition - 1))
						END AS PostCodeDistrict
					,	CASE 
							WHEN cu2.Postcode IS NULL THEN ''
							WHEN cu2.PostCode LIKE '[A-Z][0-9]%' THEN LEFT(cu2.PostCode, 1) 
							ELSE LEFT(cu2.PostCode, 2)
						END AS PostArea
					,	CONVERT(VARCHAR(6), '') AS PostalSector
					,	cu.DateOfBirth AS DOB
					,	CASE
							WHEN cu2.AgeCurrent <= 0 THEN 0
							ELSE cu2.AgeCurrent
						END AS AgeCurrent
					,	CASE
							WHEN cu2.AgeCurrent BETWEEN 18 AND 24 THEN '18 to 24'
							WHEN cu2.AgeCurrent BETWEEN 25 AND 34 THEN '25 to 34'
							WHEN cu2.AgeCurrent BETWEEN 35 AND 44 THEN '35 to 44'
							WHEN cu2.AgeCurrent BETWEEN 45 AND 54 THEN '45 to 54'
							WHEN cu2.AgeCurrent BETWEEN 55 AND 64 THEN '55 to 64'
							WHEN cu2.AgeCurrent BETWEEN 65 AND 80 THEN '65 to 80'
							WHEN cu2.AgeCurrent BETWEEN 81 AND 110 THEN '81+'
							ELSE 'Unknown'
						END AS AgeCurrentBandText
					,	COALESCE(cu.Gender, 'U') AS Gender
					,	COALESCE(bal.CashbackAvailable, 0) AS CashbackAvailable
					,	COALESCE(bal.CashbackPending, 0) AS CashbackPending
					,	COALESCE(bal.CashbackLifeTimeValue, 0) AS CashbackLTV
					,	COALESCE(hb.HardBounced, 0) AS Hardbounced
					,	CASE
							WHEN uns.Unsubscribed IS NOT NULL THEN 1
							WHEN cu.MarketableByEmail = 0 THEN 1
							WHEN cu.MarketableByEmail IS NULL THEN 0
							ELSE 0
						END AS Unsubscribed
					,	CASE
						--	WHEN hb.HardBounced IS NOT NULL THEN 0
						--	WHEN cu2.EmailStructureValid = 0 THEN 0
							WHEN cu.DateOfBirth IS NULL THEN 0		--	Where customers data has not been enriched & we haven't actually received marketing details for them set this to false
							WHEN uns.Unsubscribed IS NOT NULL THEN 0
							WHEN cu.MarketableByEmail = 0 THEN 0
							WHEN cu.MarketableByEmail IS NULL THEN 0
							WHEN cu.MarketableByEmail = 1 THEN 1
							ELSE 0
						END AS MarketableByEmail
					,	CASE
							WHEN cu.EmailTracking = 1 THEN 1
							ELSE 0
						END AS EmailTracking
					,	CASE
							WHEN cu.MarketableByPush = 1 THEN 1
							ELSE 0
						END AS MarketableByPush
					,	CASE
							WHEN cu.ClosedDate IS NOT NULL THEN 0
							WHEN cu.OptOutDate IS NOT NULL THEN 0
							WHEN cu.CustomerStatusID = 2 THEN 0	--	WHEN cu.DeactivatedDate IS NOT NULL THEN 0
							WHEN cu.DeactivatedDate < DATEADD(DAY, -15, GETDATE()) AND cu.CustomerStatusID = 6 THEN 0
							ELSE 1
						END AS CurrentlyActive
					,	cu.RegistrationDate
					,	cu.ClosedDate
					,	CASE
							WHEN cu.OptOutDate <= cu.DeactivatedDate THEN cu.OptOutDate
							WHEN cu.DeactivatedDate <= cu.OptOutDate THEN cu.DeactivatedDate
							ELSE COALESCE(cu.DeactivatedDate, cu.OptOutDate)
						END AS DeactivatedDate
				INTO #Customer
				FROM [WHB].[Inbound_Customers] cu
				LEFT JOIN #Customer_LookupFanID clu
					ON cu.CustomerGUID = clu.CustomerGUID
				LEFT JOIN [WHB].[Inbound_Balances] bal
					ON cu.CustomerGUID = bal.CustomerGUID
				LEFT JOIN #HardbounceCustomers hb
					ON clu.FanID = hb.FanID
				LEFT JOIN #Unsubscribed uns
					ON clu.FanID = uns.FanID
				CROSS APPLY (	SELECT	LTRIM(RTRIM(cu.Postcode)) AS Postcode
									,	CHARINDEX(' ', LTRIM(RTRIM(cu.Postcode))) AS PostcodeSpacePosition
									,	(@AgeCurrentDate - CONVERT(CHAR(8), cu.DateOfBirth, 112)) / 10000 AS AgeCurrent) cu2
								
				CREATE CLUSTERED INDEX CIX_CustomerGUID ON #Customer (CustomerGUID)
				CREATE NONCLUSTERED INDEX IX_PostArea ON #Customer (PostArea)
				CREATE NONCLUSTERED INDEX IX_PostCode ON #Customer (PostCode)


			/***************************************************************************************************************************************
				2.2.	Build intial customer table, updating missing values for:
							Gender
			***************************************************************************************************************************************/

				UPDATE cu
				SET cu.Gender = ngd.InferredGender
				FROM #Customer cu
				INNER JOIN [Derived].[NameGenderDictionary] ngd
					ON cu.FirstName = ngd.FirstName
					AND ngd.EndDate IS NULL
				WHERE Gender IS NULL
				OR Gender = 'U'
				OR Gender = 'O'


			/***************************************************************************************************************************************
				2.3.	Build intial customer table, updating missing values for:
							Post Code Sector
							Region
			***************************************************************************************************************************************/
	
				UPDATE cu
				SET cu.PostalSector = CASE
											WHEN REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', '') LIKE '[a-z][0-9][0-9][a-z][a-z]'
															THEN LEFT(REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', ''), 2) + ' ' + RIGHT(LEFT(REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', ''), 3), 1)
											WHEN REPLACE(REPLACE(PostCode, CHAR(160),''),' ','') LIKE '[a-z][0-9][0-9][0-9][a-z][a-z]'
															THEN LEFT(REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', ''), 3) + ' ' + RIGHT(Left(REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', ''), 4), 1)
											WHEN REPLACE(REPLACE(PostCode, CHAR(160),''),' ','') LIKE '[a-z][a-z][0-9][0-9][a-z][a-z]'
															THEN LEFT(REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', ''), 3) + ' ' + RIGHT(Left(REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', ''), 4), 1)
											WHEN REPLACE(REPLACE(PostCode, CHAR(160),''),' ','') LIKE '[a-z][0-9][a-z][0-9][a-z][a-z]'
															THEN LEFT(REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', ''), 3) + ' ' + RIGHT(Left(REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', ''), 4), 1)
											WHEN REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', '') LIKE '[a-z][a-z][0-9][0-9][0-9][a-z][a-z]'
															THEN LEFT(REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', ''), 4) + ' ' + RIGHT(Left(REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', ''), 5), 1)
											WHEN REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', '') LIKE '[a-z][a-z][0-9][a-z][0-9][a-z][a-z]'
															THEN LEFT(REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', ''), 4) + ' ' + RIGHT(Left(REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', ''), 5), 1)
											ELSE ''
									  END 
				  , cu.Region = pa.Region
				FROM #Customer cu
				INNER JOIN [Warehouse].[Staging].[PostArea] pa
					ON cu.PostArea = pa.PostAreaCode


					
				UPDATE cu
				SET cu.City = pd.town
				,	cu.County = pd.region
				FROM #Customer cu
				INNER JOIN [Warehouse].[Staging].[PostcodeDistrict] pd
					ON cu.PostCodeDistrict = pd.UK_PDIST


		/*******************************************************************************************************************************************
			3.	Find customer Account Types
		*******************************************************************************************************************************************/
			
			IF OBJECT_ID('tempdb..#AccountsOpen') IS NOT NULL DROP TABLE #AccountsOpen
			SELECT	DISTINCT
					AccountType = CONVERT(VARCHAR(10), 'AccountType')
				,	CustomerGUID = bacl.CustomerGUID
			INTO #AccountsOpen
			FROM [WHB].[Inbound_BankAccounts] ba
			INNER JOIN [WHB].[Inbound_BankAccountCustomerLinks] bacl
				ON ba.BankAccountGUID = bacl.BankAccountGUID
			WHERE ba.ClosedDate IS NULL
			AND bacl.EndDate IS NULL

			IF OBJECT_ID('tempdb..#AccountsClosed') IS NOT NULL DROP TABLE #AccountsClosed
			SELECT	DISTINCT
					AccountType = CONVERT(VARCHAR(10), 'AccountType')
				,	CustomerGUID = bacl.CustomerGUID
			INTO #AccountsClosed
			FROM [WHB].[Inbound_BankAccounts] ba
			INNER JOIN [WHB].[Inbound_BankAccountCustomerLinks] bacl
				ON ba.BankAccountGUID = bacl.BankAccountGUID
			WHERE ba.ClosedDate IS NOT NULL
			AND bacl.EndDate IS NULL

			IF OBJECT_ID('tempdb..#AccountTypes_Open') IS NOT NULL DROP TABLE #AccountTypes_Open
			SELECT	CustomerGUID = ac.CustomerGUID
				,	AccountType = STUFF((	SELECT ', ' + AccountType
											FROM #AccountsOpen ac2
											WHERE ac.CustomerGUID = ac2.CustomerGUID
											FOR XML PATH('')), 1, 1, '')
			INTO #AccountTypes_Open
			FROM #AccountsOpen ac

			CREATE CLUSTERED INDEX CIX_CustomerGUID ON #AccountTypes_Open (CustomerGUID)

			IF OBJECT_ID('tempdb..#AccountTypes_Closed') IS NOT NULL DROP TABLE #AccountTypes_Closed
			SELECT	CustomerGUID = ac.CustomerGUID
				,	AccountType = STUFF((	SELECT ', ' + AccountType
											FROM #AccountsClosed ac2
											WHERE ac.CustomerGUID = ac2.CustomerGUID
											FOR XML PATH('')), 1, 1, '')
			INTO #AccountTypes_Closed
			FROM #AccountsClosed ac

			CREATE CLUSTERED INDEX CIX_CustomerID ON #AccountTypes_Closed (CustomerGUID)

			IF OBJECT_ID('tempdb..#AccountTypes') IS NOT NULL DROP TABLE #AccountTypes
			SELECT	CustomerGUID = CustomerGUID
				,	AccountType = CONVERT(VARCHAR(50), RTRIM(LTRIM(AccountType)))
			INTO #AccountTypes
			FROM #AccountTypes_Open ato
			UNION ALL
			SELECT	CustomerGUID = CustomerGUID
				,	AccountType = CONVERT(VARCHAR(50), RTRIM(LTRIM(AccountType)))
			FROM #AccountTypes_Closed atc
			WHERE NOT EXISTS (	SELECT 1
								FROM #AccountTypes_Open ato
								WHERE atc.CustomerGUID = ato.CustomerGUID)

			CREATE CLUSTERED INDEX CIX_CustomerGUID ON #AccountTypes (CustomerGUID, AccountType)


		/***************************************************************************************************************************************
			4.	Temporary fix for Account Closure not feeding through to customer Closure
		***************************************************************************************************************************************/
		
			--UPDATE cu
			--SET	cu.ClosedDate = cu.RegistrationDate
			--,	cu.CurrentlyActive = 0
			--FROM #Customer cu
			--WHERE cu.CurrentlyActive = 1
			--AND cu.RegistrationDate < DATEADD(DAY, -3, CONVERT(DATE, GETDATE()))
			--AND NOT EXISTS (SELECT 1
			--				FROM #AccountsOpen ao
			--				WHERE cu.CustomerGUID = ao.CustomerGUID)
																		   

		/***************************************************************************************************************************************
			4.	Temporary fix for Account Closure not feeding through to customer Closure
		***************************************************************************************************************************************/
		
			IF OBJECT_ID('tempdb..#CAMEO') IS NOT NULL DROP TABLE #CAMEO
			SELECT	ca.Postcode
				,	ca.CAMEO_CODE
			INTO #CAMEO
			FROM [Warehouse].[Relational].[CAMEO] ca
			WHERE EXISTS (	SELECT 1
							FROM #Customer cu
							WHERE ca.Postcode = cu.Postcode)

			CREATE CLUSTERED INDEX CIX_CustomerGUID ON #CAMEO (Postcode, CAMEO_CODE)

		/*******************************************************************************************************************************************
			5.	Populate [WHB].[Customer] with the created table
		*******************************************************************************************************************************************/

			TRUNCATE TABLE [WHB].[Customer]
			INSERT INTO [WHB].[Customer] (	CustomerGUID
										,	FanID
										,	ClubID
										,	CompositeID
										,	SourceUID
										,	AccountType
										,	Email
										,	EmailStructureValid
										,	MobileTelephone
										,	Title
										,	FirstName
										,	LastName
										,	Address1
										,	Address2
										,	City
										,	County
										,	Postcode
										,	Region
										,	PostalSector
										,	PostCodeDistrict
										,	PostArea
										,	CAMEOCode
										,	Gender
										,	DOB
										,	AgeCurrent
										,	AgeCurrentBandText
										,	CashbackPending
										,	CashbackAvailable
										,	CashbackLTV
										,	Unsubscribed
										,	Hardbounced
										,	MarketableByEmail
										,	EmailTracking
										,	MarketableByPush
										,	CurrentlyActive
										,	RegistrationDate
										,	ClosedDate
										,	DeactivatedDate)
			SELECT	DISTINCT
					cu.CustomerGUID
				,	cu.FanID
				,	cu.ClubID
				,	cu.CompositeID
				,	cu.SourceUID
				,	act.AccountType
				,	cu.Email
				,	cu.EmailStructureValid
				,	cu.MobileTelephone
				,	cu.Title
				,	cu.FirstName
				,	cu.LastName
				,	cu.Address1
				,	cu.Address2
				,	cu.City
				,	cu.County
				,	cu.Postcode
				,	cu.Region
				,	cu.PostalSector
				,	cu.PostCodeDistrict
				,	cu.PostArea
				,	cam.CAMEO_CODE CAMEOCode
				,	cu.Gender
				,	cu.DOB
				,	cu.AgeCurrent
				,	cu.AgeCurrentBandText
				,	cu.CashbackPending
				,	cu.CashbackAvailable
				,	cu.CashbackLTV
				,	cu.Unsubscribed
				,	cu.Hardbounced
				,	cu.MarketableByEmail
				,	cu.EmailTracking
				,	cu.MarketableByPush
				,	cu.CurrentlyActive
				,	cu.RegistrationDate
				,	cu.ClosedDate
				,	cu.DeactivatedDate
			FROM #Customer cu
			LEFT JOIN #AccountTypes act
				ON cu.CustomerGUID = act.CustomerGUID
			LEFT JOIN #CAMEO cam
				ON cu.Postcode = cam.Postcode

		SET @RowsAffected = @@ROWCOUNT; SET @msg = 'Loaded rows to [WHB].[Customer] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
		EXEC [Monitor].[ProcessLog_Insert] 'Customer_CustomerStaging', @msg
		
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
