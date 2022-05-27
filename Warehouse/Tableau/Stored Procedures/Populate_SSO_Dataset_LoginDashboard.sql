


-- =============================================
-- Author: Ryan Dickson
-- Create date: 2020-07-16
-- JIRA ticket: DOT-71
-- Description: Retrieve Direct Debit Earning Transactions.
-- 
-- Change Log:
--				2020-07-16; Modified By: Ryan Dickson; DOT-71 - Initial Version
--				2020-08-19: Modified By: Ryan Dickson; DBA-199 - Modified Join to matomo visits to remove LoginType
--				2021-01-06: Modified By: Ryan Dickson; DOPSPR-271 - Modified ZionActions so that Website Registration now comes from FanCredentials along with SSO ones
--																	In step 4c row number added sso.ActionType, sso.LoginType to the 
-- =============================================
CREATE PROCEDURE [Tableau].[Populate_SSO_Dataset_LoginDashboard] 
(
	@FirstProcessDay DATETIME = NULL
,	@LastProcessDate DATETIME = NULL
,	@InitialRun INT = 0
) AS
BEGIN
	SET NOCOUNT ON

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @msg VARCHAR(500)

	IF @FirstProcessDay IS NULL SELECT @FirstProcessDay = CAST(DATEADD(day, -1, GETDATE()) AS DATE);
	IF @LastProcessDate IS NULL SELECT @LastProcessDate = CAST(DATEADD(day, -1, GETDATE()) AS DATE);

	/******************************************************************************/
	--STEP 1 - Pull the days ZionActions
	/******************************************************************************/
	IF @InitialRun = 0
	BEGIN
		--RAISERROR('STEP 1', 0, 1) WITH NOWAIT

		IF OBJECT_ID('tempdb.dbo.#ZionActionFanSSO') IS NOT NULL DROP TABLE #ZionActionFanSSO;
		SELECT
			combined.FanID
		,	combined.ActionType
		,	combined.LoginType
		,	combined.ActionDateTime
		INTO
			#ZionActionFanSSO
		FROM
		(
			-- Website and SSO Registration
			SELECT
				fc.FanID
			,	'Registration' AS ActionType
			,	CASE WHEN fc.OnlineRegistrationSourceID = 1 THEN 'SSO' ELSE 'Website' END AS LoginType
			,	CONVERT(CHAR(16), fc.OnlineRegistrationDate, 20) AS ActionDateTime
			FROM
				SLC_REPL.dbo.FanCredentials fc
			WHERE
				CAST(fc.OnlineRegistrationDate AS DATE) >= @FirstProcessDay
			AND
				CAST(fc.OnlineRegistrationDate AS DATE) <= @LastProcessDate
			UNION ALL
			-- Logins
			SELECT
				logins.FanID
			,	'Login' AS ActionType
			,	CASE WHEN logins.ZionActionID = 20 THEN 'SSO' ELSE 'Website' END AS LoginType
			,	CONVERT(CHAR(16), logins.Date, 20) AS ActionDateTime
			FROM
				SLC_REPL.zion.ZionActionFan logins
			WHERE
				logins.ZionActionID IN (1, 20)
			AND
				CAST(logins.Date AS DATE) >= @FirstProcessDay
			AND
				CAST(logins.Date AS DATE) <= @LastProcessDate
		) combined

		CREATE CLUSTERED INDEX cix_ZionActionFanSSO ON #ZionActionFanSSO (FanID ASC, ActionDateTime ASC);
	END

	/******************************************************************************/
	--STEP 2 - Prepare Matomomo Data for that day
	/******************************************************************************/
	IF @InitialRun = 0
	BEGIN
		--RAISERROR('STEP 2', 0, 1) WITH NOWAIT

		IF OBJECT_ID('tempdb.dbo.#MatomoSSO') IS NOT NULL DROP TABLE #MatomoSSO;
		SELECT
			v.FanID
		,	CONVERT(CHAR(16), v.FirstActionDateTime, 20) AS ActionDateTime
		,	v.VisitDuration AS SessionLength
		,	v.DeviceBrand
		,	v.DeviceModel
		,	v.DeviceType
		INTO
			#MatomoSSO
		FROM 
			[Tableau].[Matomo_Visits] v
		WHERE
			CAST(v.firstActionDateTime AS DATE) >= @FirstProcessDay
		AND
			CAST(v.firstActionDateTime AS DATE) <= @LastProcessDate

		CREATE CLUSTERED INDEX cix_MatomoSSO ON #MatomoSSO (FanID ASC, ActionDateTime ASC);
	END
	/******************************************************************************/
	--STEP 3 - Fan Data
	/******************************************************************************/

	/******************************************************************************/
	--STEP 3a - Bank Accounts
	/******************************************************************************/
	
	--RAISERROR('STEP 3a', 0, 1) WITH NOWAIT

	IF OBJECT_ID('tempdb.dbo.#BankAccounts') IS NOT NULL DROP TABLE #BankAccounts;
	SELECT
		iba.IssuerCustomerID
	,	count(*) AS NoOfBankAccounts
	INTO
		#BankAccounts
	FROM
		SLC_REPL.dbo.IssuerBankAccount iba
	INNER JOIN
		SLC_REPL.dbo.BankAccount ba 
	ON 
		iba.BankAccountID = ba.ID 
	AND
		ba.Status = 1
	INNER JOIN 
		SLC_REPL.dbo.BankAccountTypeHistory bah 
	ON 
		iba.BankAccountID = bah.BankAccountID
	AND
		bah.EndDate IS NULL
	INNER JOIN
		SLC_REPL.dbo.IssuerCustomerAttribute isa
	ON
		iba.IssuerCustomerID = isa.IssuerCustomerID
	AND
		isa.Value IN ('F', 'B')
	AND
		isa.AttributeID = 2
	AND
		isa.EndDate IS NULL
	GROUP BY
		iba.IssuerCustomerID

	CREATE CLUSTERED INDEX cix_BankAccounts ON #BankAccounts (IssuerCustomerID ASC);

	SET @msg = 'rows affected: ' + CAST((SELECT COUNT(*) FROM #BankAccounts) AS VARCHAR(10))
	--RAISERROR(@msg, 0, 1) WITH NOWAIT

	/******************************************************************************/
	--STEP 3b - Cards
	/******************************************************************************/
	--RAISERROR('STEP 3b', 0, 1) WITH NOWAIT

	IF OBJECT_ID('tempdb.dbo.#Cards') IS NOT NULL DROP TABLE #Cards;
	SELECT
		ipc.IssuerCustomerID
	,	count(*) AS NoOfCards
	INTO
		#Cards
	FROM 
		SLC_REPL.dbo.IssuerPaymentCard ipc
	INNER JOIN
		SLC_REPL.dbo.PaymentCard pc
	ON
		pc.ID = ipc.PaymentCardID
	WHERE
		ipc.Status = 1
	AND
		pc.CardTypeID = 1
	GROUP BY
		ipc.IssuerCustomerID

	CREATE CLUSTERED INDEX cix_Cards ON #Cards (IssuerCustomerID ASC);

	SET @msg = 'rows affected: ' + CAST((SELECT COUNT(*) FROM #Cards) AS VARCHAR(10))
	--RAISERROR(@msg, 0, 1) WITH NOWAIT

	/******************************************************************************/
	--STEP 3c - Fans Dataset
	/******************************************************************************/
	--RAISERROR('STEP 3c', 0, 1) WITH NOWAIT

	IF OBJECT_ID('tempdb.dbo.#Customers') IS NOT NULL DROP TABLE #Customers;
	SELECT
		f.ID AS CustomerID
	,	CASE WHEN 
				fc.OnlineRegistrationDate IS NOT NULL AND
				f.AgreedTCs = 1 AND
				f.AgreedTCsDate IS NOT NULL AND 
				f.Status = 1
			THEN
				CASE 
					WHEN OnlineRegistrationSourceID = 0 THEN 'Registered Website'
					WHEN OnlineRegistrationSourceID = 1 THEN 'Registered SSO'
					ELSE 'Not Registered'
				END
			ELSE
				'Not Registered'
		END AS CustomerStatus
	,	CASE 
			WHEN ca.IssuerCustomerID IS NOT NULL AND ba.IssuerCustomerID IS NOT NULL THEN 'Both'
			WHEN ca.IssuerCustomerID IS NOT NULL THEN 'Credit'
			WHEN ba.IssuerCustomerID IS NOT NULL THEN 'Bank'
			ELSE 'Unknown' -- should never hit this condition
		END AS CustomerType
	,	CASE WHEN f.ClubID = 138 THEN 'RBS' ELSE 'Natwest' END AS Bank
	,	CASE WHEN 
				fc.OnlineRegistrationDate IS NOT NULL AND
				f.AgreedTCs = 1 AND
				f.AgreedTCsDate IS NOT NULL AND 
				f.Status = 1
			THEN
				fc.OnlineRegistrationDate 
			ELSE
				NULL
		END AS CustomerRegistrationDate
	,	f.RegistrationDate AS CustomerCreatedDate
	INTO
		#Customers
	FROM
		SLC_REPL.dbo.Fan f
	INNER JOIN
		SLC_REPL.dbo.FanCredentials fc
	ON
		fc.FanID = f.ID
	INNER JOIN
		SLC_Report.dbo.OnlineRegistrationSource ors
	ON
		ors.ID = fc.OnlineRegistrationSourceID
	LEFT OUTER JOIN
		SLC_REPL.dbo.IssuerCustomer ic
	ON 
		f.SourceUID = ic.SourceUID
	AND
		(
			(f.ClubID = 132 and ic.IssuerID = 2) 
		OR 
			(f.ClubID = 138 and ic.IssuerID = 1)
		)
	LEFT OUTER JOIN
		#BankAccounts ba
	ON
		ic.ID = ba.IssuerCustomerID
	LEFT OUTER JOIN
		#Cards ca
	ON
		ic.ID = ca.IssuerCustomerID
	WHERE
		f.ClubID IN (132, 138)
	AND
		f.Status = 1
	AND
		NOT (ca.IssuerCustomerID IS NULL AND ba.IssuerCustomerID IS NULL)

	CREATE CLUSTERED INDEX cix_Customers ON #Customers (CustomerID ASC);
	CREATE NONCLUSTERED INDEX idx_Customers_CustomerCreatedDate ON #Customers (CustomerCreatedDate ASC, CustomerStatus ASC);

	/******************************************************************************/
	--STEP 4 - Combine Datasets
	/******************************************************************************/

	/******************************************************************************/
	--STEP 4a - Fans Initial Dataset daily file
	--			Fan records up the point and time SSO went live
	/******************************************************************************/

	IF @InitialRun = 1
	BEGIN

		--RAISERROR('STEP 4a', 0, 1) WITH NOWAIT
		SET @msg = 'rows affected: ' + CAST((SELECT COUNT(*) FROM #Customers) AS VARCHAR(10))
		--RAISERROR(@msg, 0, 1) WITH NOWAIT

		INSERT INTO Warehouse.Tableau.[SSO_Dataset_LoginDashboard]
		SELECT
			f.CustomerID
		,	CAST(f.CustomerRegistrationDate AS DATETIME) AS ActionDateTime
		,	CASE WHEN f.CustomerRegistrationDate IS NULL THEN 'Not Registered' ELSE 'Registration' END AS ActionType
		,	CASE WHEN f.CustomerRegistrationDate IS NULL THEN 'Unknown' ELSE 'Website' END AS LoginType
		,	f.CustomerStatus
		,	0 AS SessionLength
		,	'Unknown' AS DeviceBrand
		,	'Unknown' AS DeviceModel
		,	'Unknown' AS DeviceType
		,	CASE WHEN cs.CustomerSegment = 'V' THEN 'Premier' ELSE 'Core' END AS AccountType
		,	f.Bank
		,	COALESCE(cust.Region, 'Unknown') AS Region
		,	COALESCE(cust.PostcodeDistrict, 'Unknown') AS PostcodeDistrict
		FROM
			#Customers f
		LEFT OUTER JOIN
			Warehouse.Relational.Customer cust
		ON
			f.CustomerID = cust.FanID
		LEFT OUTER JOIN
			Warehouse.relational.Customer_RBSGSegments cs
		ON
			cs.FanID = f.CustomerID
		AND
			cs.EndDate IS NULL
	END

	/******************************************************************************/
	--STEP 4b - New Fans Added during that period will have a blank record added
	--			Assumption that a fan will appear in the dashboard as not signed up first until they register
	--			Do not add a fan if they already exist in the dashboard table (somehow)
	/******************************************************************************/

	IF @InitialRun = 0
	BEGIN
		--RAISERROR('STEP 4b', 0, 1) WITH NOWAIT

		INSERT INTO Warehouse.Tableau.[SSO_Dataset_LoginDashboard]
		SELECT
			f.CustomerID
		,	NULL AS ActionDateTime
		,	'Not Registered' AS ActionType
		,	'Unknown' AS LoginType
		,	f.CustomerStatus
		,	0 AS SessionLength
		,	'Unknown' AS DeviceBrand
		,	'Unknown' AS DeviceModel
		,	'Unknown' AS DeviceType
		,	CASE WHEN cs.CustomerSegment = 'V' THEN 'Premier' ELSE 'Core' END AS AccountType
		,	f.Bank
		,	COALESCE(cust.Region, 'Unknown') AS Region
		,	COALESCE(cust.PostcodeDistrict, 'Unknown') AS PostcodeDistrict
		FROM
			#Customers f
		LEFT OUTER JOIN
			DIMAIN.Warehouse.Relational.Customer cust
		ON
			f.CustomerID = cust.FanID
		LEFT OUTER JOIN
			Warehouse.relational.Customer_RBSGSegments cs
		ON
			cs.FanID = f.CustomerID
		AND
			cs.EndDate IS NULL
		WHERE
			CAST(f.CustomerCreatedDate AS DATE) >= @FirstProcessDay
		AND
			CAST(f.CustomerCreatedDate AS DATE) <= @LastProcessDate
		AND
			NOT EXISTS (SELECT DISTINCT dash.CustomerID FROM Warehouse.Tableau.[SSO_Dataset_LoginDashboard] dash WHERE dash.CustomerID = f.CustomerID)
	END

	/******************************************************************************/
	-- STEP 4c	Combine with Fan Data
	--			Only returns fans that have data today
	--			Fans Dataset daily file
	--			Join to matomo data is using fuzzy logic as its the best we can do to join the data
	/******************************************************************************/

	IF @InitialRun = 0
	BEGIN
		--RAISERROR('STEP 4c', 0, 1) WITH NOWAIT

		INSERT INTO Warehouse.Tableau.[SSO_Dataset_LoginDashboard]
		SELECT
			actions.CustomerID
		,	actions.ActionDateTime
		,	actions.ActionType
		,	actions.LoginType
		,	actions.CustomerStatus
		,	actions.SessionLength
		,	actions.DeviceBrand
		,	actions.DeviceModel
		,	actions.DeviceType
		,	actions.AccountType
		,	actions.Bank
		,	actions.Region
		,	actions.PostcodeDistrict
		FROM
		(			
			SELECT
				ROW_NUMBER() OVER (PARTITION BY f.CustomerID, sso.ActionDateTime, sso.ActionType, sso.LoginType ORDER BY msso.ActionDateTime) AS RowNo
			,	f.CustomerID
			,	CAST(sso.ActionDateTime AS DATETIME) AS ActionDateTime
			,	sso.ActionType
			,	sso.LoginType
			,	f.CustomerStatus
			,	CASE WHEN msso.SessionLength IS NULL THEN 0 ELSE msso.SessionLength END AS SessionLength
			,	CASE WHEN msso.DeviceBrand IS NULL THEN 'Unknown' ELSE msso.DeviceBrand END AS DeviceBrand
			,	CASE WHEN msso.DeviceModel IS NULL THEN 'Unknown' ELSE msso.DeviceModel END AS DeviceModel
			,	CASE WHEN msso.DeviceType IS NULL THEN 'Unknown' ELSE msso.DeviceType END AS DeviceType
			,	CASE WHEN cs.CustomerSegment = 'V' THEN 'Premier' ELSE 'Core' END AS AccountType
			,	f.Bank
			,	COALESCE(cust.Region, 'Unknown') AS Region
			,	COALESCE(cust.PostcodeDistrict, 'Unknown') AS PostcodeDistrict
			FROM
				#Customers f
			INNER JOIN
				#ZionActionFanSSO sso
			ON
				f.CustomerID = sso.FanID
			LEFT OUTER JOIN
				#MatomoSSO msso
			ON
				sso.FanID = msso.FanID
			AND
				sso.ActionDateTime >= DATEADD(minute, -5, msso.ActionDateTime)
			AND
				sso.ActionDateTime <= DATEADD(minute, 5, msso.ActionDateTime)
			LEFT OUTER JOIN
				DIMAIN.Warehouse.Relational.Customer cust
			ON
				f.CustomerID = cust.FanID
			LEFT OUTER JOIN
				DIMAIN.Warehouse.relational.Customer_RBSGSegments cs
			ON
				cs.FanID = f.CustomerID
			AND
				cs.EndDate IS NULL
		) actions
		WHERE
			actions.RowNo = 1
	END

	/******************************************************************************/
	-- STEP 4d	Remove any fans that are now registered
	/******************************************************************************/

	IF @InitialRun = 0
	BEGIN
		--RAISERROR('STEP 4d', 0, 1) WITH NOWAIT
	
		DELETE dash
		FROM
			Warehouse.Tableau.[SSO_Dataset_LoginDashboard] dash
		INNER JOIN
			#ZionActionFanSSO sso
		ON
			dash.CustomerID = sso.FanID
		AND
			sso.ActionType = 'Registration'
		WHERE
			dash.ActionType = 'Not Registered'

	END

	/******************************************************************************/
	-- STEP 4e	Clean up any fans that have two registrations records
	/******************************************************************************/

	IF @InitialRun = 0
	BEGIN
		--RAISERROR('STEP 4e', 0, 1) WITH NOWAIT
	
		--SSO Registrations Incorrectly Marked as Website ones (due to initial data import)
		DELETE dash
		FROM
			Warehouse.Tableau.[SSO_Dataset_LoginDashboard] dash
		INNER JOIN
		(
			SELECT
				d.CustomerID
			FROM
				Warehouse.Tableau.[SSO_Dataset_LoginDashboard] d
			WHERE
				d.ActionType = 'Registration'
			GROUP BY
				d.CustomerID
			HAVING
				COUNT(*) > 1
		) dups
		ON
			dups.CustomerID = dash.CustomerID
		AND
			dash.ActionType = 'Registration'
		AND
			dash.LoginType = 'Website'
		AND
			dash.CustomerStatus = 'Registered SSO'

		--Duplicate Rows (due to initial data import)
		DELETE dash
		FROM
			Warehouse.Tableau.[SSO_Dataset_LoginDashboard] dash
		INNER JOIN
		(
			SELECT
				d.SSO_Dataset_LoginDashboardID
			,	d.CustomerID
			,	ROW_NUMBER() OVER (PARTITION BY d.CustomerID ORDER BY d.CustomerID, d.SSO_Dataset_LoginDashboardID DESC) AS row_num
			FROM
				Warehouse.Tableau.[SSO_Dataset_LoginDashboard] d
			WHERE
				d.ActionType = 'Registration'
		) c
		ON
			c.SSO_Dataset_LoginDashboardID = dash.SSO_Dataset_LoginDashboardID
		WHERE
			c.row_num > 1
	END
END
