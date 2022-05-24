
CREATE PROCEDURE [Staging].[SSRS_R0196_ReducedBrandSpendReport_V3]  (@BrandID VarChar(200))
As
Begin

	/*******************************************************************************************************************************************
		1. Prepare parameters for script
	*******************************************************************************************************************************************/

		If Object_ID('tempdb..#BrandIDs') Is Not Null Drop Table #BrandIDs
		Create Table #BrandIDs (BrandID Int)

		/***********************************************************************************************************************
			1.1. Update @BrandID to entires that have been recently branded if the process is executed through ReportServer
		***********************************************************************************************************************/

			DECLARE @ConsumerCombinationChangeLogMaxDate DATE = (SELECT MAX(DateResolved) FROM Staging.ConsumerCombination_ChangeLog)

			IF @BrandID IS NULL
				BEGIN
					INSERT INTO #BrandIDs
					SELECT DISTINCT BrandID
					FROM [Staging].[ConsumerCombination_ChangeLog]
					WHERE DateResolved =  @ConsumerCombinationChangeLogMaxDate
				END


		/***********************************************************************************************************************
			1.2. Split @BrandID input into individual BrandIDs & insert to temp table
		***********************************************************************************************************************/

			INSERT INTO #BrandIDs
			SELECT CONVERT(INT, Item) AS BrandID
			FROM [dbo].[il_SplitDelimitedStringArray] (@BrandID, ',')

			Create Clustered Index CIX_BrandIDs_BrandID on #BrandIDs (BrandID)

	/*******************************************************************************************************************************************
		2. Output results
	*******************************************************************************************************************************************/

			SELECT ID
			 , BrandID
			 , BrandName
			 , SectorName
			 , SectorGroupName
			 , CASE
					WHEN CustomerType = 'All Customers' THEN 'All Spend'
					WHEN CustomerType = 'MyRewards Customers' THEN 'MyRewards Spend'
					ELSE 'Unknown'
			   END AS RowType
			 , CASE
					WHEN TransactionType = 'Direct Debit' THEN 'DD'
					WHEN TransactionType = 'POS' THEN 'POS'
					ELSE 'Unknown'
			   END AS TransactionType
			 , Amount AS Spend
			 , AmountOnline AS OnlineSpend
			 , Transactions
			 , Customers AS UniqueSpenders
			 , TotalCustomers
			 , CASE 
					WHEN Customers = 0 THEN 0
					ELSE 1.0 * Transactions / Customers
			    END AS AvgTranFreq
			 , CASE 
					WHEN Transactions = 0 then 0
					ELSE 1.0 * Amount / Transactions
				END AS AvgTranValue
			 , 0 AS OnlineAvgTranValue
			 , CASE 
					WHEN Customers = 0 THEN 0 
					ELSE  1.0 * Amount / Customers 
				END AS SpendPerSpender
			 , CASE
					WHEN TotalCustomers = 0 then 0 
					ELSE 1.0 * Customers / TotalCustomers 
				END AS CustomerPenetration
		FROM [MI].[TotalBrandSpend_RBSG_V2] bs
		WHERE FilterID IN (1, 2, 16, 17)
		AND EXISTS (SELECT 1
					FROM #BrandIDs br
					WHERE bs.BrandID = br.BrandID)

END





