
/***********************************************************************

	Author:			RF
	Create date:	2020-03-03
	Description:	Returns count of Reward Bank Accounts per
					customer and the details of those accounts

***********************************************************************/

CREATE PROCEDURE [Staging].[SSRS_R0209_BankAccountsPerCustomer]
AS
	BEGIN

	/*******************************************************************************************************************************************
		1. Fetch all currently active customer
	*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer
			SELECT DISTINCT
				   cu.ClubID
				 , cl.Name AS ClubName
				 , cu.CompositeID
				 , ic.IssuerID
				 , ic.ID AS IssuerCustomerID
				 , cu.SourceUID
			INTO #Customer
			FROM [Relational].[Customer] cu
			INNER JOIN [SLC_Report].[dbo].[Club] cl
				ON cu.ClubID = cl.ID
			INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
				ON cu.SourceUID = ic.SourceUID
				AND ((cu.ClubID = 132 AND IssuerID = 2) OR (cu.ClubID = 138 AND IssuerID = 1))
			WHERE cu.CurrentlyActive = 1
			AND EXISTS (SELECT IssuerCustomerID
						FROM [SLC_Report].[dbo].[IssuerBankAccount] iba
						WHERE ic.ID = iba.IssuerCustomerID
						GROUP BY IssuerCustomerID
						HAVING COUNT(DISTINCT iba.BankAccountID) > 2)


			CREATE CLUSTERED INDEX CIX_Comp ON #Customer (IssuerCustomerID)


	/*******************************************************************************************************************************************
		2. Fetch bank accounts that the customers have been attached to
	*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#BankAccountType') IS NOT NULL DROP TABLE #BankAccountType
			SELECT DISTINCT
				   cu.ClubID
				 , cu.ClubName
				 , cu.CompositeID
				 , cu.IssuerID
				 , cu.SourceUID
				 , iba.BankAccountID
				 , bat.Type AS BankAccountType
				 , MIN(bat.StartDate) OVER (PARTITION BY cu.CompositeID, iba.BankAccountID) AS BankAccountStartDate
				 , bat.EndDate
				 , iba.CustomerStatus
			INTO #BankAccountType
			FROM #Customer cu
			INNER JOIN [SLC_Report].[dbo].[IssuerBankAccount] iba
				ON cu.IssuerCustomerID = iba.IssuerCustomerID
			INNER JOIN [SLC_Report].[dbo].[BankAccountTypeHistory] bat
				ON iba.BankAccountID = bat.BankAccountID
				AND bat.Type IN ('QA', 'QC', 'QD', 'QB', 'QE')

			CREATE CLUSTERED INDEX CIX_Comp ON #BankAccountType (CompositeID, BankAccountID)


	/*******************************************************************************************************************************************
		3. Remove bank accounts that the customer is no longer attached to
	*******************************************************************************************************************************************/

			DELETE
			FROM #BankAccountType
			WHERE EndDate IS NOT NULL

			DELETE
			FROM #BankAccountType
			WHERE CustomerStatus = 0


	/*******************************************************************************************************************************************
		4. Fetch counts of accounts per customer
	*******************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#AccountsPerCustomer') IS NOT NULL DROP TABLE #AccountsPerCustomer
			SELECT CompositeID
				 , COUNT(DISTINCT BankAccountID) AS BankAccounts
			INTO #AccountsPerCustomer
			FROM #BankAccountType
			GROUP BY CompositeID
			HAVING COUNT(DISTINCT BankAccountID) > 2


			CREATE CLUSTERED INDEX CIX_Comp ON #AccountsPerCustomer (CompositeID)


	/*******************************************************************************************************************************************
		5. Combine datasets for final output
	*******************************************************************************************************************************************/
		
			IF OBJECT_ID('tempdb..#ReportOutput') IS NOT NULL DROP TABLE #ReportOutput
			SELECT bat.ClubID
				 , bat.ClubName
				 , bat.SourceUID
				 , apc.BankAccounts
				 , bat.BankAccountID
				 , bat.BankAccountType
				 , act.ProductName
				 , CONVERT(DATE, bat.BankAccountStartDate) AS BankAccountStartDate
			INTO #ReportOutput
			FROM #BankAccountType bat
			INNER JOIN #AccountsPerCustomer apc
				ON bat.CompositeID = apc.CompositeID
			INNER JOIN [Relational].[AccountType_Offers] act
				ON bat.BankAccountType = act.ProductCode
				AND bat.ClubID = act.BankID
				AND act.OfferType = 1


	/*******************************************************************************************************************************************
		6. Combine datasets for final output
	*******************************************************************************************************************************************/
			
			DECLARE @Today DATE = GETDATE()

			SELECT ClubID
				 , ClubName
				 , SourceUID
				 , BankAccounts
				 , BankAccountID
				 , BankAccountType
				 , ProductName
				 , BankAccountStartDate
				 , @Today AS ReportDate
			FROM #ReportOutput
			ORDER BY ClubID
				   , SourceUID
				   , BankAccountStartDate

	END