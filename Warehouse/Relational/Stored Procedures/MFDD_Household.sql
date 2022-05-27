-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

CREATE PROCEDURE [Relational].[MFDD_Household]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

/*******************************************************************************************************************************************
	1. Declare variables
*******************************************************************************************************************************************/

	DECLARE @Time DATETIME
		  , @Message VARCHAR(500)

	EXEC Prototype.oo_TimerMessage 'Household -- Start', @Time OUTPUT


/*******************************************************************************************************************************************
	2. Fetch all currently active customers and bank accounts they are currently linked to
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#BankAccountUsers') IS NOT NULL DROP TABLE #BankAccountUsers
	SELECT FanID = fa.ID
		 , SourceUID = ic.SourceUID
		 , BankAccountID = iba.BankAccountID
		 , HouseholdID = DENSE_RANK() OVER (ORDER BY BankAccountID)
	INTO #BankAccountUsers
	FROM [SLC_REPL].[dbo].[Fan] fa
	INNER JOIN [SLC_REPL].[dbo].[IssuerCustomer] ic 
		ON fa.SourceUID = ic.SourceUID
	INNER JOIN [SLC_REPL].[dbo].[IssuerBankAccount] iba 
		ON  ic.ID = iba.IssuerCustomerID
	WHERE 1=1
	AND fa.Status = 1
	AND fa.ClubID IN (132, 138)
	AND EXISTS (SELECT 1 FROM Relational.Customer cu WHERE cu.CurrentlyActive = 1 AND fa.ID = cu.FanID)
	GROUP BY fa.ID
		   , ic.SourceUID
		   , iba.BankAccountID
	-- (5,036,575 rows affected) / 00:00:07

	EXEC Prototype.oo_TimerMessage '#BankAccountUsers', @Time OUTPUT

	CREATE CLUSTERED INDEX CIX_HouseholdSource ON #BankAccountUsers (HouseholdID, SourceUID) -- 00:00:00
	CREATE INDEX IX_BankAccountHousehold ON #BankAccountUsers (BankAccountID, HouseholdID) -- 00:00:01

	EXEC Prototype.oo_TimerMessage '#BankAccountUsers -- Index', @Time OUTPUT


/*******************************************************************************************************************************************
	4. Find the minimum HouseholdID that each customer and then bank is attached to and use this as the customers new HouseholdID,
	   repeat this process until there are no more updates to be made
*******************************************************************************************************************************************/

	DECLARE @RowCount INT = 1
		  , @RowCountBank INT = 1
		  , @UpdateNumber INT = 1


	WHILE @RowCount > 0
		BEGIN
		
			SET @RowCount = 0
			SET @RowCountBank = 0

			;WITH
			Updater_SourceUID AS (SELECT FanID
								  	   , SourceUID
								  	   , BankAccountID
								  	   , HouseholdID
								  	   , MinHouseholdID = MIN(HouseholdID) OVER (PARTITION BY SourceUID)
								  FROM #BankAccountUsers b)

			UPDATE Updater_SourceUID
			SET HouseholdID = MinHouseholdID
			WHERE MinHouseholdID < HouseholdID
			-- (1,348,979 rows affected) / 00:01:00

			SET @RowCount = @RowCount + @@ROWCOUNT
			
			SET @Message = CONVERT(VARCHAR(2), @UpdateNumber) + ' - SourceUID     - ' + LEFT(CONVERT(VARCHAR(7), @RowCount) + '       ', 7) + ' rows updated '
			EXEC Prototype.oo_TimerMessage @Message, @Time OUTPUT

			;WITH
			Updater_BankAccountID AS (SELECT FanID
									  	   , SourceUID
									  	   , BankAccountID
									  	   , HouseholdID
									  	   , MinHouseholdID = MIN(HouseholdID) OVER (PARTITION BY BankAccountID)
									  FROM #BankAccountUsers b)

			UPDATE Updater_BankAccountID
			SET HouseholdID = MinHouseholdID
			WHERE MinHouseholdID < HouseholdID
			-- (224,768 rows affected) / 00:00:13

			SET @RowCountBank = @@ROWCOUNT
			SET @RowCount = @RowCount + @RowCountBank
			
			SET @Message = CONVERT(VARCHAR(2), @UpdateNumber) + ' - BankAccountID - ' + LEFT(CONVERT(VARCHAR(7), @RowCountBank) + '       ', 7) + ' rows updated '
			EXEC Prototype.oo_TimerMessage @Message, @Time OUTPUT

			SET @UpdateNumber = @UpdateNumber + 1

		END


/*******************************************************************************************************************************************
	4. Rank the remaining household IDs and use the new ranking to give incremental IDs
*******************************************************************************************************************************************/

	;WITH
	Updater_HouseholdID AS (SELECT FanID
								 , SourceUID
								 , BankAccountID
								 , HouseholdID
								 , RankedHouseholdID = DENSE_RANK() OVER (ORDER BY HouseholdID)
							FROM #BankAccountUsers b)

	UPDATE Updater_HouseholdID
	SET HouseholdID = RankedHouseholdID


/*******************************************************************************************************************************************
	5. Insert the results into a holding table
*******************************************************************************************************************************************/

	ALTER INDEX CIX_SourceUID ON [Relational].[NewHousehouldIDs] DISABLE
	ALTER INDEX CIX_HouseholdID_SourceUID ON [Relational].[NewHousehouldIDs] DISABLE

	TRUNCATE TABLE [Relational].[NewHousehouldIDs]
	INSERT INTO [Relational].[NewHousehouldIDs] (FanID
											   , SourceUID
											   , BankAccountID
											   , HouseholdID)
	SELECT FanID
		 , SourceUID
		 , BankAccountID
		 , HouseholdID
	FROM #BankAccountUsers

	EXEC Prototype.oo_TimerMessage 'Output to : [Relational].[NewHousehouldIDs] ', @Time OUTPUT

	ALTER INDEX CIX_SourceUID ON [Relational].[NewHousehouldIDs] REBUILD
	ALTER INDEX CIX_HouseholdID_SourceUID ON [Relational].[NewHousehouldIDs] REBUILD

	EXEC Prototype.oo_TimerMessage 'Index : [Relational].[NewHousehouldIDs] ', @Time OUTPUT
	EXEC Prototype.oo_TimerMessage 'Household -- End', @Time OUTPUT


/*******************************************************************************************************************************************
	6. Update and insert to live table
*******************************************************************************************************************************************/

	DECLARE @Date DATE = GETDATE()

	/***********************************************************************************************************************
		6.1. Update EndDate for customers that are no longer active
	***********************************************************************************************************************/

		--	EndDate customers no longer attached to a bank account

			UPDATE mf
			SET EndDate = @Date
			FROM [Relational].[MFDD_Households] mf
			WHERE EndDate IS NULL
			AND NOT EXISTS (SELECT 1
							FROM [Relational].[NewHousehouldIDs] mf_n
							WHERE mf.BankAccountID = mf_n.BankAccountID
							AND mf.FanID = mf_n.FanID)

		--	EndDate customers no longer attached to any bank account

			UPDATE mf
			SET EndDate = @Date
			FROM [Relational].[MFDD_Households] mf
			WHERE EndDate IS NULL
			AND NOT EXISTS (SELECT 1
							FROM [Relational].[NewHousehouldIDs] mf_n
							WHERE mf.FanID = mf_n.FanID)

		--	EndDate bank accounts no longer attached to any customer

			UPDATE mf
			SET EndDate = @Date
			FROM [Relational].[MFDD_Households] mf
			WHERE EndDate IS NULL
			AND NOT EXISTS (SELECT 1
							FROM [Relational].[NewHousehouldIDs] mf_n
							WHERE mf.BankAccountID = mf_n.BankAccountID)

	/***********************************************************************************************************************
		6.2. Find new customers
	***********************************************************************************************************************/	

		-- Find new bank accounts & customers

			;WITH
			NewEntries AS  (SELECT *
								 , DENSE_RANK() OVER (ORDER BY HouseholdID) + (SELECT MAX(HouseholdID) FROM [Relational].[MFDD_Households]) AS NewHouseholdID
							FROM [Relational].[NewHousehouldIDs] mf_n
							WHERE NOT EXISTS (SELECT 1
											  FROM [Relational].[MFDD_Households] mf
											  WHERE mf.BankAccountID = mf_n.BankAccountID
											  AND mf.FanID = mf_n.FanID
											  AND EndDate IS NULL))

			INSERT INTO [Relational].[MFDD_Households] (FanID
							 , SourceUID
							 , BankAccountID
							 , HouseholdID
							 , StartDate
							 , EndDate)
			SELECT FanID
				 , SourceUID
				 , BankAccountID
				 , NewHouseholdID
				 , @Date AS StartDate
				 , NULL AS EndDate
			FROM NewEntries

	/***********************************************************************************************************************
		6.3. Find households that have split in two
	***********************************************************************************************************************/

		--	Find households that have split

			IF OBJECT_ID('tempdb..#Split') IS NOT NULL DROP TABLE #Split
			SELECT *
			INTO #Split
			FROM [Relational].[MFDD_Households] mf
			WHERE HouseholdID IN (SELECT mf.HouseholdID
								  FROM [Relational].[MFDD_Households] mf
								  INNER JOIN [Relational].[NewHousehouldIDs] mf_n
						  			  ON mf.BankAccountID = mf_n.BankAccountID
								  WHERE mf.EndDate IS NULL
								  GROUP BY mf.HouseholdID
								  HAVING COUNT(DISTINCT mf_n.HouseholdID) > 1
								  UNION
								  SELECT mf.HouseholdID
								  FROM [Relational].[MFDD_Households] mf
								  INNER JOIN [Relational].[NewHousehouldIDs] mf_n
						  			  ON mf.FanID = mf_n.FanID
								  WHERE mf.EndDate IS NULL
								  GROUP BY mf.HouseholdID
								  HAVING COUNT(DISTINCT mf_n.HouseholdID) > 1)

			IF OBJECT_ID('tempdb..#Split_NewFile') IS NOT NULL DROP TABLE #Split_NewFile
			SELECT *
			INTO #Split_NewFile
			FROM [Relational].[NewHousehouldIDs] mf_n
			WHERE EXISTS (SELECT 1
						  FROM #Split sp
						  WHERE mf_n.BankAccountID = sp.BankAccountID)
			UNION
			SELECT *
			FROM [Relational].[NewHousehouldIDs] mf_n
			WHERE EXISTS (SELECT 1
						  FROM #Split sp
						  WHERE mf_n.FanID = sp.FanID)

			IF OBJECT_ID('tempdb..#SplitComparison') IS NOT NULL DROP TABLE #SplitComparison
			SELECT mf.ID
				 , mf.HouseholdID
				 , mf.BankAccountID
				 , mf.FanID
				 , mf.StartDate
				 , mf.EndDate
				 , mf_n.ID AS ID_New
				 , mf_n.HouseholdID AS HouseholdID_New
				 , mf_n.BankAccountID AS BankAccountID_New
				 , mf_n.FanID AS FanID_New
				 , MIN(mf_n.HouseholdID) OVER (PARTITION BY mf.HouseholdID) AS MinHouseholdID_New
			INTO #SplitComparison
			FROM #Split mf
			INNER JOIN #Split_NewFile mf_n
				ON mf.FanID = mf_n.FanID
				OR mf.BankAccountID = mf_n.BankAccountID
			WHERE mf.EndDate IS NULL

			UPDATE mf
			SET EndDate = @Date
			FROM [Relational].[MFDD_Households] mf
			WHERE EXISTS (SELECT 1
						  FROM #SplitComparison sc
						  WHERE HouseholdID_New != MinHouseholdID_New
						  AND mf.ID = sc.ID)

			;WITH
			NewEntries AS  (SELECT *
								 , DENSE_RANK() OVER (ORDER BY HouseholdID) + (SELECT MAX(HouseholdID) FROM [Relational].[MFDD_Households]) AS NewHouseholdID
							FROM [Relational].[NewHousehouldIDs] mf
							WHERE EXISTS (SELECT 1
										  FROM #SplitComparison sc
										  WHERE HouseholdID_New != MinHouseholdID_New
										  AND mf.ID = sc.ID))

			INSERT INTO [Relational].[MFDD_Households] (FanID
													  , SourceUID
													  , BankAccountID
													  , HouseholdID
													  , StartDate
													  , EndDate)
			SELECT FanID
				 , SourceUID
				 , BankAccountID
				 , NewHouseholdID
				 , @Date AS StartDate
				 , NULL AS EndDate
			FROM NewEntries

	/***********************************************************************************************************************
		6.4. Find households that have merged
	***********************************************************************************************************************/

		--	Find households that have merged
	
			IF OBJECT_ID('tempdb..#Merge_NewFile') IS NOT NULL DROP TABLE #Merge_NewFile
			SELECT *
			INTO #Merge_NewFile
			FROM [Relational].[NewHousehouldIDs] mf
			WHERE HouseholdID IN (SELECT mf_n.HouseholdID
								  FROM [Relational].[MFDD_Households] mf
								  INNER JOIN [Relational].[NewHousehouldIDs] mf_n
						  			  ON mf.BankAccountID = mf_n.BankAccountID
								  WHERE mf.EndDate IS NULL
								  GROUP BY mf_n.HouseholdID
								  HAVING COUNT(DISTINCT mf.HouseholdID) > 1
								  UNION
								  SELECT mf_n.HouseholdID
								  FROM [Relational].[MFDD_Households] mf
								  INNER JOIN [Relational].[NewHousehouldIDs] mf_n
						  			  ON mf.FanID = mf_n.FanID
								  WHERE mf.EndDate IS NULL
								  GROUP BY mf_n.HouseholdID
								  HAVING COUNT(DISTINCT mf.HouseholdID) > 1)

			IF OBJECT_ID('tempdb..#Merge') IS NOT NULL DROP TABLE #Merge
			SELECT *
			INTO #Merge
			FROM [Relational].[MFDD_Households] mf_n
			WHERE EXISTS (SELECT 1
						  FROM #Merge_NewFile sp
						  WHERE mf_n.BankAccountID = sp.BankAccountID)
			UNION
			SELECT *
			FROM [Relational].[MFDD_Households] mf_n
			WHERE EXISTS (SELECT 1
						  FROM #Merge_NewFile sp
						  WHERE mf_n.FanID = sp.FanID)

			IF OBJECT_ID('tempdb..#MergeComparison') IS NOT NULL DROP TABLE #MergeComparison
			SELECT *
				 , MIN(HouseholdID) OVER (PARTITION BY HouseholdID_New) AS MinHouseholdID_New
			INTO #MergeComparison
			FROM (	SELECT mf.ID
						 , mf.HouseholdID
						 , mf.BankAccountID
						 , mf.FanID
						 , mf.SourceUID
						 , mf.StartDate
						 , mf.EndDate
						 , mf_n.ID AS ID_New
						 , mf_n.HouseholdID AS HouseholdID_New
						 , mf_n.BankAccountID AS BankAccountID_New
						 , mf_n.FanID AS FanID_New
					FROM #Merge mf
					INNER JOIN #Merge_NewFile mf_n
						ON mf.FanID = mf_n.FanID
					WHERE mf.EndDate IS NULL
					UNION
					SELECT mf.ID
						 , mf.HouseholdID
						 , mf.BankAccountID
						 , mf.FanID
						 , mf.SourceUID
						 , mf.StartDate
						 , mf.EndDate
						 , mf_n.ID AS ID_New
						 , mf_n.HouseholdID AS HouseholdID_New
						 , mf_n.BankAccountID AS BankAccountID_New
						 , mf_n.FanID AS FanID_New
					FROM #Merge mf
					INNER JOIN #Merge_NewFile mf_n
						ON mf.BankAccountID = mf_n.BankAccountID
					WHERE mf.EndDate IS NULL) mf
	
			UPDATE mf
			SET EndDate = @Date
			FROM [Relational].[MFDD_Households] mf
			WHERE EXISTS (SELECT 1
						  FROM #MergeComparison mc
						  WHERE HouseholdID != MinHouseholdID_New
						  AND mf.ID = mc.ID)

			INSERT INTO [Relational].[MFDD_Households] (FanID
													  , SourceUID
													  , BankAccountID
													  , HouseholdID
													  , StartDate
													  , EndDate)	  
			SELECT DISTINCT
				   FanID
				 , SourceUID
				 , BankAccountID
				 , MinHouseholdID_New
				 , @Date AS StartDate
				 , NULL AS EndDate
			FROM #MergeComparison
			WHERE HouseholdID != MinHouseholdID_New

	/***********************************************************************************************************************
		6.5. Remove entries that have been added and then immediately merged today
	***********************************************************************************************************************/

		DELETE
		FROM [Relational].[MFDD_Households]
		WHERE StartDate = EndDate
		AND StartDate IS NOT NULL

END