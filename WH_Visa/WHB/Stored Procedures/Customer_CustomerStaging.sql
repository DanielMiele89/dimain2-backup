
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
				AND ci.PublisherID = 180
	
				DECLARE @AgeCurrentDate INT = CONVERT(CHAR(8), GETDATE(), 112)

				IF OBJECT_ID('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer;
				SELECT	ROW_NUMBER() OVER (ORDER BY cu.CustomerID) AS ID
					,	cu.CustomerGUID
					,	cu.VirginCustomerID
					,	cu.CustomerID AS FanID
					,	180 AS ClubID
					,	cu.CustomerID - 10000000 AS CompositeID
					,	CONVERT(VARCHAR(64),  cu.CustomerGUID) AS SourceUID
					,	cu.EmailAddress AS Email
					,	esv.EmailStructureValid
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
							WHEN cu.OptedOutDate IS NOT NULL THEN 0
							WHEN cu.DeactivatedDate IS NOT NULL THEN 0
							ELSE 1
						END AS CurrentlyActive
					,	cu.RegistrationDate
					,	cu.ClosedDate
					,	CASE
							WHEN cu.OptedOutDate <= cu.DeactivatedDate THEN cu.OptedOutDate
							WHEN cu.DeactivatedDate <= cu.OptedOutDate THEN cu.DeactivatedDate
							ELSE COALESCE(cu.DeactivatedDate, cu.OptedOutDate)
						END AS DeactivatedDate
				INTO #Customer
				FROM [WHB].[Inbound_Customers] cu
				LEFT JOIN #Customer_LookupFanID clu
					ON cu.CustomerGUID = clu.CustomerGUID
				LEFT JOIN [WHB].[Inbound_Balances] bal
					ON cu.CustomerGUID = bal.CustomerGUID
				LEFT JOIN #HardbounceCustomers hb
					ON cu.CustomerID = hb.FanID
				LEFT JOIN #Unsubscribed uns
					ON cu.CustomerID = uns.FanID
				CROSS APPLY (	SELECT	LTRIM(RTRIM(cu.Postcode)) AS Postcode
									,	CHARINDEX(' ', LTRIM(RTRIM(cu.Postcode))) AS PostcodeSpacePosition
									,	(@AgeCurrentDate - CONVERT(CHAR(8), cu.DateOfBirth, 112)) / 10000 AS AgeCurrent) cu2
				CROSS APPLY [WH_AllPublishers].[dbo].[iTVF_IsEmailStructureValid](cu.EmailAddress) esv

				CREATE CLUSTERED INDEX CIX_PostArea ON #Customer (PostArea)

				UPDATE #Customer
				SET FirstName = REPLACE(FirstName, 'Mehta Phone +447806723792 Email anita.mehta@hotmail.com Confirm email anita.mehta@hotmail.comita', '')
				WHERE FanID = -954883

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


			/***************************************************************************************************************************************
				2.4.	Temporary fix for Account Closure not feeding through to customer Closure
			***************************************************************************************************************************************/
					
				IF OBJECT_ID('tempdb..#CustomersWithOnlyClosedAccounts') IS NOT NULL DROP TABLE #CustomersWithOnlyClosedAccounts
				SELECT	CustomerID
					,	MAX(LoadDate) AS LoadDate
				INTO #CustomersWithOnlyClosedAccounts
				FROM [WHB].[Inbound_Accounts]
				GROUP BY CustomerID
				HAVING MIN(AccountStatus) = MAX(AccountStatus)
				AND MIN(AccountStatus) = 'closed'

				UPDATE cu
				SET	cu.ClosedDate = cwoca.LoadDate
				,	cu.CurrentlyActive = 0
				FROM #Customer cu
				INNER JOIN #CustomersWithOnlyClosedAccounts cwoca
					ON cu.FanID = cwoca.CustomerID
				WHERE cu.CurrentlyActive = 1

		/*******************************************************************************************************************************************
			3.	Find customer Account Types
		*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#AccountTypes_Open') IS NOT NULL DROP TABLE #AccountTypes_Open
			SELECT	ac.CustomerID
				,	AccountType = STUFF((	SELECT ', ' + AccountType
											FROM [WHB].[Inbound_Accounts] ac2
											WHERE ac.CustomerID = ac2.CustomerID
											AND AccountStatus = 'open'
											FOR XML PATH('')), 1, 1, '')
			INTO #AccountTypes_Open
			FROM [WHB].[Inbound_Accounts] ac
			WHERE AccountStatus = 'open'

			CREATE CLUSTERED INDEX CIX_CustomerID ON #AccountTypes_Open (CustomerID)

			IF OBJECT_ID('tempdb..#AccountTypes_Closed') IS NOT NULL DROP TABLE #AccountTypes_Closed
			SELECT	ac.CustomerID
				,	AccountType = STUFF((	SELECT ', ' + AccountType
											FROM [WHB].[Inbound_Accounts] ac2
											WHERE ac.CustomerID = ac2.CustomerID
											AND AccountStatus = 'closed'
											FOR XML PATH('')), 1, 1, '')
			INTO #AccountTypes_Closed
			FROM [WHB].[Inbound_Accounts] ac
			WHERE AccountStatus = 'closed'

			CREATE CLUSTERED INDEX CIX_CustomerID ON #AccountTypes_Closed (CustomerID)


		/*******************************************************************************************************************************************
			4.	Populate [WHB].[Customer] with the created table
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
				,	RTRIM(LTRIM(COALESCE(acco.AccountType, accc.AccountType))) AS AccountType
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
			LEFT JOIN #AccountTypes_Open acco
				ON cu.FanID = acco.CustomerID
			LEFT JOIN #AccountTypes_Closed accc
				ON cu.FanID = accc.CustomerID
			LEFT JOIN [Warehouse].[Relational].[CAMEO] cam
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
