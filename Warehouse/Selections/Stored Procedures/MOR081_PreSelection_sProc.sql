-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-02-20>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.MOR081_PreSelection_sProcASBEGIN--SELECT	DISTINCT OIN, Narrative_RBS, Narrative_VF

--FROM	Relational.ConsumerTransaction_DD_MyRewards my
--JOIN	Relational.ConsumerCombination_DD dd on dd.ConsumerCombinationID_DD = my.ConsumerCombinationID_DD

--WHERE	(Narrative_VF LIKE '%GENERAL%MEDICAL%COUNCIL%' OR --993730--
--		 Narrative_VF LIKE '%NURSING%MIDWIFERY%COUNCIL%' OR --599690--
--		 Narrative_VF LIKE '%BRITISH%MEDICAL%ASSOCIATION%' --991744--
--		)

--SELECT	DISTINCT OIN, Narrative_RBS, Narrative_VF

--FROM	Relational.ConsumerTransaction_DD_MyRewards my
--JOIN	Relational.ConsumerCombination_DD dd on dd.ConsumerCombinationID_DD = my.ConsumerCombinationID_DD

--WHERE	(Narrative_VF LIKE '%ROYAL%COLLEGE%OF%GPS%' OR --991021--
--		 Narrative_VF LIKE '%THE%ROYAL%COLLEGE%MIDWIVES%' OR --991815--
--		 Narrative_VF LIKE '%ROYAL%COLLEGE%PHYSICIANS%THE%' OR --997151--
--		 Narrative_VF LIKE '%ROYAL%COLLEGE%ANAESTHETISTS%' OR --907439--
--		 Narrative_VF LIKE '%ROYAL%COLLEGE%SURGEONS%' OR --996697--
--		 Narrative_VF LIKE '%ROYAL%COLLEGE%PAEDIATRICS%' OR --981960--
--		 Narrative_VF LIKE '%ROYAL%COLLEGE%RADIOLOGISTS%' OR --995813--
--		 Narrative_VF LIKE '%ROYAL%COLLEGE%PATHOLOGISTS%' --991658--
--		 )
--ORDER BY 3


-- Get all MyRewards Accounts (FB)
IF OBJECT_ID ('tempdb..#BaID') IS NOT NULL DROP TABLE #BaID
SELECT	BankAccountID, dd.AccountName
INTO	#BaID
FROM	SLC_Report.dbo.BankAccountTypeHistory bt
JOIN	(SELECT DISTINCT
		 AccountType, AccountName
		 FROM Warehouse.[Staging].[DirectDebit_EligibleAccounts])
		 dd on dd.AccountType = bt.Type
WHERE	 EndDate IS NULL
AND		 LEFT(type,1) = 'Q'

CREATE CLUSTERED INDEX INX ON #BaID(BankAccountID, AccountName)

IF OBJECT_ID ('tempdb..#FB') IS NOT NULL DROP TABLE #FB
SELECT DISTINCT	bam.BankAccountID, n.FanID, Nominee
INTO	#FB
FROM	SLC_Report..IssuerCustomer ic
JOIN	SLC_Report..IssuerBankAccount iba ON ic.ID = iba.IssuerCustomerID
JOIN	SLC_Report..BankAccount ba ON iba.BankAccountID = ba.ID
JOIN	Warehouse.Relational.customer c on c.SourceUID = ic.SourceUID
JOIN	#BaID bam on bam.BankAccountID = ba.ID
JOIN	Relational.Customer_Loyalty_DD_Nominee n on n.FanID = c.FanID
WHERE	iba.CustomerStatus = 1
AND		ba.Status = 1
AND		currentlyactive = 1
and		EndDate is null

IF OBJECT_ID('tempdb..#Unique_HH_BankAccountID') IS NOT NULL DROP TABLE #Unique_HH_BankAccountID
SELECT DISTINCT	 HouseholdID
				, BankAccountID
INTO #Unique_HH_BankAccountID
FROM Warehouse.Relational.MFDD_Households
WHERE EndDate IS NULL

--Task 1--
--SELECT	OIN,
--		Narrative_VF,
--		COUNT(DISTINCT FB.BankAccountID) AS DistinctBA

--FROM	#FB fb
--JOIN	Relational.ConsumerTransaction_DD_MyRewards my on my.BankAccountID = fb.BankAccountID
--JOIN	Relational.ConsumerCombination_DD dd on dd.ConsumerCombinationID_DD = my.ConsumerCombinationID_DD

--WHERE	OIN IN ('599690','993730','991744')
--AND		TranDate >= DATEADD(MONTH,-13,GETDATE())
--AND		Nominee = 1

--GROUP BY OIN,
--		 Narrative_VF

--SELECT	COUNT(DISTINCT FB.BankAccountID) AS DistinctBA

--FROM	#FB fb
--JOIN	Relational.ConsumerTransaction_DD_MyRewards my on my.BankAccountID = fb.BankAccountID
--JOIN	Relational.ConsumerCombination_DD dd on dd.ConsumerCombinationID_DD = my.ConsumerCombinationID_DD

--WHERE	OIN IN ('599690','993730','991744')
--AND		TranDate >= DATEADD(MONTH,-13,GETDATE())
--AND		Nominee = 1


--Task 2--
--SELECT	OIN,
--		Narrative_VF,
--		COUNT(DISTINCT FB.BankAccountID) AS DistinctBA

--FROM	#FB fb
--JOIN	Relational.ConsumerTransaction_DD_MyRewards my on my.BankAccountID = fb.BankAccountID
--JOIN	Relational.ConsumerCombination_DD dd on dd.ConsumerCombinationID_DD = my.ConsumerCombinationID_DD

--WHERE	OIN IN ('991021','991815','997151','907439','996697','981960','995813','991658')
--AND		TranDate >= DATEADD(MONTH,-13,GETDATE())
--AND		Nominee = 1

--GROUP BY OIN,
--		 Narrative_VF

--SELECT	COUNT(DISTINCT FB.BankAccountID) AS DistinctBA

--FROM	#FB fb
--JOIN	Relational.ConsumerTransaction_DD_MyRewards my on my.BankAccountID = fb.BankAccountID
--JOIN	Relational.ConsumerCombination_DD dd on dd.ConsumerCombinationID_DD = my.ConsumerCombinationID_DD

--WHERE	OIN IN ('991021','991815','997151','907439','996697','981960','995813','991658')
--AND		TranDate >= DATEADD(MONTH,-13,GETDATE())
--AND		Nominee = 1





-- THE BELOW S USED FOR OVERLAP BETWEEN NHS WORKERS AND KEY WORKERS (POS TRANSACTIONS IN S:\Data Insight\Insight\Reward\Reward - R0350 - Key Workers)--
IF OBJECT_ID('TEMPDB..#Medical') IS NOT NULL DROP TABLE #Medical
SELECT	a.HouseholdID,
		a.BankAccountID,
		SALES, 
		CASE WHEN Sales IS NULL THEN 0 ELSE 1 END AS Is_Medical
INTO	#Medical
FROM	(SELECT	HouseholdID,
				BankAccountID
		 FROM	#Unique_HH_BankAccountID
		) a
LEFT JOIN
		(SELECT	BankAccountID,
				SUM(ct.Amount) AS SALES
		 FROM	Warehouse.Relational.ConsumerTransaction_DD ct WITH(NOLOCK)
		 JOIN	Warehouse.Relational.ConsumerCombination_DD cc ON ct.ConsumerCombinationID_DD = cc.ConsumerCombinationID_DD
		 WHERE	cc.OIN IN ('991021','991815','997151','907439','996697','981960','995813','991658','599690','993730','991744')
		 AND	ct.TranDate >= DATEADD(MONTH,-13,GETDATE())
		 GROUP BY BankAccountID
		) b ON a.BankAccountID = b.BankAccountID


IF OBJECT_ID('TEMPDB..#MEDICAL_HOUSEHOLDS') IS NOT NULL DROP TABLE #MEDICAL_HOUSEHOLDS
SELECT	HouseholdID
INTO	#MEDICAL_HOUSEHOLDS
FROM	#Medical
WHERE	Is_Medical = 1
GROUP BY HouseholdID



--LOOK AT MIN / MAX TRANSACTION DD DATE TO GET TIME PERIOD FOR ACTIVE CUSTOMERS THROUGHOUT CHOSEN TIME PERIOD


-- Unique Households and SourceUIDs for POS transactions
IF OBJECT_ID('tempdb..#Unique_HH_SourceUID') IS NOT NULL DROP TABLE #Unique_HH_SourceUID
SELECT DISTINCT	 HouseholdID
				, SourceUID
INTO #Unique_HH_SourceUID
FROM Warehouse.Relational.MFDD_Households
WHERE EndDate IS NULL


-- Unique Households to aggregate DD and POS to
IF OBJECT_ID('tempdb..#Unique_HH') IS NOT NULL DROP TABLE #Unique_HH
SELECT DISTINCT	 HouseholdID
INTO #Unique_HH
FROM Warehouse.Relational.MFDD_Households
WHERE EndDate IS NULL


--Unique Households & BankAccounts from Base for POS Transactions
IF OBJECT_ID('tempdb..#Unique_HH_Base') IS NOT NULL DROP TABLE #Unique_HH_Base
SELECT DISTINCT BA.HouseholdID
				, BankAccountID
INTO #Unique_HH_Base
FROM #Unique_HH_BankAccountID BA
JOIN #Unique_HH_SourceUID S ON S.HouseholdID = BA.HouseholdID




IF OBJECT_ID('tempdb..#DDHealthWorkers') IS NOT NULL DROP TABLE #DDHealthWorkers
SELECT	FanID
		,CINID
		,M.HouseholdID
INTO	#DDHealthWorkers
FROM	#MEDICAL_HOUSEHOLDS M
JOIN	#Unique_HH_SourceUID U ON U.HouseholdID = M.HouseholdID
JOIN	Relational.Customer C ON C.SourceUID = U.SourceUID
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID




IF OBJECT_ID('Sandbox.SamW.MorrisonsHealthWorksers080720') IS NOT NULL DROP TABLE Sandbox.SamW.MorrisonsHealthWorksers080720
SELECT C.FanID
		,U.CINID
INTO Sandbox.SamW.MorrisonsHealthWorksers080720
FROM	#DDHealthWorkers U
JOIN	Relational.Customer C ON U.FanID = C.FanID
JOIN	Relational.CINList CL ON CL.CIN = C.SourceUID






-- -- FIND UNIQUE HOUSEHOLDS AND BANKACCOUNTS
--IF OBJECT_ID('TEMPDB..#UNIQUE_HOUSEHOLDID_BANKACCOUNTID') IS NOT NULL DROP TABLE #UNIQUE_HOUSEHOLDID_BANKACCOUNTID
--SELECT DISTINCT HouseholdID
-- , BankAccountID
--INTO #UNIQUE_HOUSEHOLDID_BANKACCOUNTID
--FROM Warehouse.Relational.MFDD_Households
--WHERE EndDate IS NULL


--IF OBJECT_ID('TEMPDB..#UNIQUE_HOUSEHOLDID_SOURCEUID') IS NOT NULL DROP TABLE #UNIQUE_HOUSEHOLDID_SOURCEUID
--SELECT DISTINCT HouseholdID
-- , SourceUID
--INTO #UNIQUE_HOUSEHOLDID_SOURCEUID
--FROM Warehouse.Relational.MFDD_Households
--WHERE EndDate IS NULL

--IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
--SELECT ConsumerCombinationID_DD
--		,Narrative_RBS
--INTO #CC
--FROM Relational.ConsumerCombination_DD
--WHERE Narrative_RBS LIKE '%CORONER%'
--OR Narrative_RBS LIKE '%Firebrigades%Union%'
--OR Narrative_RBS LIKE '%Police%'
--OR Narrative_RBS LIKE '%Teacher%'
--OR Narrative_RBS LIKE '%Society%Of%Care%'

--select *
--from #CC


----FIREBRIGADES UNION
---- LIKE '%Police%'
----TEACHERS
----TEACHERSTOYOURHOME
----TEACHERS HOUSING
----SOCIETY OF TEACHER
----SOCIAL CARE

--IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
--SELECT F.FanID
--INTO #Trans
--FROM #FB F
--JOIN Relational.ConsumerTransaction_DD_MyRewards CT ON F.FanID = CT.FanID
--JOIN #CC C ON C.ConsumerCombinationID_DD = CT.ConsumerCombinationID_DD
------LEFT JOIN Sandbox.SamW.MorrisonsHealthWorksers080720 S ON S.FanID = f.FanID
--GROUP BY F.FanID

--IF OBJECT_ID('Sandbox.SamW.KeyWorkers170121') IS NOT NULL DROP TABLE Sandbox.SamW.KeyWorkers170121
--SELECT	FanID
--INTO Sandbox.SamW.KeyWorkers170121
--FROM	(SELECT FanID
--		FROM Sandbox.SamW.MorrisonsHealthWorksers080720
--		UNION
--		SELECT FanID
--		FROM #Trans
--		) A

If Object_ID('Warehouse.Selections.MOR081_PreSelection') Is Not Null Drop Table Warehouse.Selections.MOR081_PreSelectionSelect FanIDInto Warehouse.Selections.MOR081_PreSelectionFROM  Sandbox.SamW.MorrisonsHealthWorksers080720END