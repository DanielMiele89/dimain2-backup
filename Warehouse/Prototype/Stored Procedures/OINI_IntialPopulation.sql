

CREATE PROCEDURE [Prototype].[OINI_IntialPopulation]
AS
BEGIN

		INSERT INTO Prototype.OINI_FileIDs
		SELECT CONVERT(INT, ID) AS FileID
			 , 0 AS Inserted
			 , 0 AS AddedToFinalTable
		FROM SLC_Report..NobleFiles nf
		WHERE EXISTS (SELECT 1
					  FROM Archive_Light.dbo.CBP_DirectDebit_TransactionHistory dd
					  WHERE nf.ID = dd.FileID)
		AND NOT EXISTS (SELECT 1
						FROM Prototype.OINI_FileIDs fi
						WHERE nf.ID = fi.FileID)

					
		IF OBJECT_ID('tempdb..#IssuerBankAccount') IS NOT NULL DROP TABLE #IssuerBankAccount;
		WITH
		BankAccountID AS (	SELECT BankAccountID
							FROM SLC_Report..IssuerBankAccount iba
							GROUP BY BankAccountID
							HAVING COUNT(DISTINCT IssuerCustomerID) = 1)

		SELECT iba.BankAccountID
			 , iba.ID AS IssuerBankAccountID
			 , iba.IssuerCustomerID
			 , fa.SourceUID
			 , fa.ID AS FanID
		INTO #IssuerBankAccount
		FROM SLC_Report..IssuerBankAccount iba
		INNER JOIN SLC_Report..IssuerCustomer ic
			ON iba.IssuerCustomerID = ic.ID
		INNER JOIN SLC_Report..Fan fa
			ON ic.SourceUID = fa.SourceUID
			AND fa.ClubID IN (132, 138)
		WHERE EXISTS (SELECT 1
					  FROM BankAccountID ba
					  WHERE iba.BankAccountID = ba.BankAccountID)

		CREATE CLUSTERED INDEX CIX_BankAccountID ON #IssuerBankAccount (BankAccountID)

	
		IF OBJECT_ID('tempdb..#IssuerBankAccountID') IS NOT NULL DROP TABLE #IssuerBankAccountID;
		SELECT iba.ID AS IssuerBankAccountID
			 , iba.IssuerCustomerID
			 , fa.SourceUID
			 , fa.ID AS FanID
		INTO #IssuerBankAccountID
		FROM SLC_Report..IssuerBankAccount iba
		INNER JOIN SLC_Report..IssuerCustomer ic
			ON iba.IssuerCustomerID = ic.ID
		INNER JOIN SLC_Report..Fan fa
			ON ic.SourceUID = fa.SourceUID
			AND fa.ClubID IN (132, 138)

		CREATE CLUSTERED INDEX CIX_Fan ON #IssuerBankAccountID (FanID)

		SET NOCOUNT ON



		DECLARE	@FileID INT
			  , @FileDate DATE
			  , @LoopNumber INT = 1
			  , @FinalLoopNumber VARCHAR(10) = (SELECT COUNT(*) FROM Warehouse.Prototype.OINI_FileIDs WHERE Inserted = 0)
			  , @StartDate DATE = GETDATE()
	
		WHILE EXISTS (SELECT 1 FROM Warehouse.Prototype.OINI_FileIDs WHERE Inserted = 0) AND (SELECT CONVERT(DATE, GETDATE())) = @StartDate
		BEGIN
	
			SET @FileID = (SELECT MIN(FileID) FROM Prototype.OINI_FileIDs WHERE Inserted = 0)
		
			IF OBJECT_ID('tempdb..#TransactionHistory') IS NOT NULL DROP TABLE #TransactionHistory
			SELECT FileID
				 , RowNum
				 , OIN
				 , Narrative
				 , Amount
				 , Date
				 , BankAccountID
				 , IssuerBankAccountID
				 , IssuerCustomerID
				 , SourceUID
				 , FanID
				 , NULL AS ConsumerCombo_DD
			INTO #TransactionHistory
			FROM Archive_Light.dbo.CBP_DirectDebit_TransactionHistory dd
			WHERE FileID = @FileID	--	20391

			CREATE CLUSTERED INDEX CIX_OIN ON #TransactionHistory (OIN)
		

			-- Update customer IDs

			UPDATE th
			SET th.IssuerBankAccountID = COALESCE(th.IssuerBankAccountID, ba.IssuerBankAccountID)
			  , th.IssuerCustomerID = COALESCE(th.IssuerCustomerID, ba.IssuerCustomerID)
			  , th.SourceUID = COALESCE(th.SourceUID, ba.SourceUID)
			  , th.FanID = COALESCE(th.FanID, ba.FanID)
			FROM #TransactionHistory th
			INNER JOIN #IssuerBankAccount ba
				ON th.BankAccountID = ba.BankAccountID
		
			UPDATE th
			SET th.FanID = fa.FanID
			FROM #TransactionHistory th
			INNER JOIN #IssuerBankAccountID fa
				ON th.IssuerBankAccountID = fa.IssuerBankAccountID
			WHERE th.FanID IS NULL
		
			UPDATE th
			SET th.FanID = fa.FanID
			FROM #TransactionHistory th
			INNER JOIN #IssuerBankAccountID fa
				ON th.IssuerCustomerID = fa.IssuerCustomerID
			WHERE th.FanID IS NULL
		
			UPDATE th
			SET th.FanID = fa.FanID
			FROM #TransactionHistory th
			INNER JOIN #IssuerBankAccountID fa
				ON th.SourceUID = fa.SourceUID
			WHERE th.FanID IS NULL
		

			-- Find CCs
		
			SELECT @FileDate = Date
			FROM #TransactionHistory
		
			SELECT @FileDate = MAX(StartDate)
			FROM [Staging].[VocaFile_OriginatorRecord_AllEntries]
			WHERE StartDate <= @FileDate
	
	
			IF OBJECT_ID('tempdb..#Combos') IS NOT NULL DROP TABLE #Combos;
			WITH
			CC_DD AS (SELECT DISTINCT
					  	     OIN
					  	   , Narrative
					  FROM #TransactionHistory),
		
			VocaFile_OINs AS (SELECT ServiceUserNumber AS OIN
							  	   , ServiceUserName AS Narrative
							  FROM [Staging].[VocaFile_OriginatorRecord_AllEntries]
							  WHERE StartDate = @StartDate)

			SELECT DISTINCT
				   dd.OIN
				 , dd.Narrative AS Narrative_RBS
				 , vf.Narrative AS Narrative_VF
			INTO #Combos
			FROM CC_DD dd
			LEFT JOIN VocaFile_OINs vf
				ON dd.OIN = vf.OIN


			INSERT INTO [Relational].[ConsumerCombination_DD] (OIN
															 , Narrative_RBS
															 , Narrative_VF
															 , BrandID)
			SELECT OIN
				 , Narrative_RBS
				 , Narrative_VF
				 , 944
			FROM #Combos c
			WHERE NOT EXISTS (SELECT 1
							  FROM [Relational].[ConsumerCombination_DD] cc
							  WHERE c.OIN = cc.OIN
							  AND c.Narrative_RBS = cc.Narrative_RBS
							  AND COALESCE(c.Narrative_VF, '') = COALESCE(cc.Narrative_VF, ''))
							   

			IF OBJECT_ID('tempdb..#NewCombos') IS NOT NULL DROP TABLE #NewCombos
			SELECT *
			INTO #NewCombos
			FROM [Relational].[ConsumerCombination_DD] c
			WHERE EXISTS (SELECT 1
						  FROM #Combos cc
						  WHERE c.OIN = cc.OIN
						  AND c.Narrative_RBS = cc.Narrative_RBS
						  AND COALESCE(c.Narrative_VF, '') = COALESCE(cc.Narrative_VF, ''))

			CREATE CLUSTERED INDEX CIX_OIN ON #NewCombos (OIN)

		
			UPDATE th
			SET th.ConsumerCombo_DD = nc.ConsumerCombinationID_DD
			FROM #TransactionHistory th
			INNER JOIN #NewCombos nc
				ON th.OIN = nc.OIN
				AND th.Narrative = nc.Narrative_RBS


			INSERT INTO Prototype.OINI_Trans (FileID
											, RowNum
											, OIN
											, Narrative
											, Amount
											, Date
											, BankAccountID
											, IssuerBankAccountID
											, IssuerCustomerID
											, SourceUID
											, FanID
											, ConsumerCombo_DD)
			SELECT th.FileID
				 , th.RowNum
				 , th.OIN
				 , th.Narrative
				 , th.Amount
				 , th.Date
				 , th.BankAccountID
				 , th.IssuerBankAccountID
				 , th.IssuerCustomerID
				 , th.SourceUID
				 , th.FanID
				 , th.ConsumerCombo_DD
			FROM #TransactionHistory th
			WHERE FanID IS NOT NULL

			UPDATE Prototype.OINI_FileIDs
			SET Inserted = 1
			WHERE FileID = @FileID

			PRINT CONVERT(VARCHAR(10), @LoopNumber) + ' of ' +  @FinalLoopNumber

			SET @LoopNumber = @LoopNumber + 1

		END
	
		SET NOCOUNT OFF

END	
/*

	USE Warehouse

SELECT FileID
	 , COUNT(DISTINCT Date)
FROM Prototype.OINI_Trans
GROUP BY FileID



		
		
		SELECT *
		FROM #CheckAccounts
		WHERE BankAccountID = 9102120
		ORDER BY BankAccountID


		SELECT *
		FROM SLC_Report..IssuerBankAccount iba
		INNER JOIN SLC_Report..BankAccount ba
			ON iba.BankAccountID = ba.ID
		WHERE IssuerCustomerID IN (12566515, 8593254)

		SELECT *
		FROM Relational.Customer
		WHERE FanID IN (5461743, 5465110)


		SELECT *
		FROM SLC_Report..Fan
		WHERE ID IN (5461743, 5465110)








		SELECT DISTINCT
			   c.BankAccountID
		INTO #OnlyBankAccountID
		FROM #Check c
		LEFT JOIN #IssuerBankAccount ba
			ON c.BankAccountID = ba.BankAccountID
		LEFT JOIN SLC_Report..IssuerBankAccount iba
			ON c.IssuerBankAccountID = iba.ID
		LEFT JOIN SLC_Report..IssuerCustomer ic
			ON c.IssuerCustomerID = ic.ID
			OR iba.IssuerCustomerID = ic.ID
		LEFT JOIN SLC_Report..Fan fa
			ON ic.SourceUID = fa.SourceUID


		DROP TABLE #CheckAccounts
		SELECT iba.BankAccountID
			 , iba.ID AS IssuerBankAccountID
			 , iba.IssuerCustomerID
			 , fa.SourceUID
			 , fa.ID AS FanID
			 , CASE WHEN nm.IssuerCustomerID IS NULL THEN 0 ELSE 1 END AS IsNominee
			 , CASE WHEN cu.CurrentlyActive = 1 THEN 1 ELSE 0 END AS InCustomer
		INTO #CheckAccounts
		FROM SLC_Report..IssuerBankAccount iba
		INNER JOIN SLC_Report..IssuerCustomer ic
			ON iba.IssuerCustomerID = ic.ID
		INNER JOIN SLC_Report..Fan fa
			ON ic.SourceUID = fa.SourceUID
		LEFT JOIN Relational.Customer cu
			ON fa.ID = cu.FanID
		LEFT JOIN SLC_Report..DDCashbackNominee nm
			ON ic.ID = nm.IssuerCustomerID
			AND nm.EndDate IS NULL
		WHERE EXISTS (SELECT 1
					  FROM #OnlyBankAccountID oba
					  WHERE iba.BankAccountID = oba.BankAccountID)





		*/