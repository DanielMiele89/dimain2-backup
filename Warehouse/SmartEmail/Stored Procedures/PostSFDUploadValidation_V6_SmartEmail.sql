
CREATE PROCEDURE [SmartEmail].[PostSFDUploadValidation_V6_SmartEmail] (	@Tablename VARCHAR(150)
																	,	@RunID INT
																	,	@aLionSendID INT)
AS
BEGIN
 

--DECLARE @Tablename VARCHAR(150) = 'Warehouse.SmartEmail.DataValSE_NWP'
--	,	@RunID Int	=	1
--	,	@aLionSendID Int	=	692

DECLARE @Qry VARCHAR(MAX) = ''

/*******************************************************************************************************************************************
	1. Insert the contents of the SFD extract into a holding tables for validation
*******************************************************************************************************************************************/

	/***********************************************************************************************************************
		1.1.	Store Imported Data into Temp Table
	***********************************************************************************************************************/

		SET @Qry = @Qry + '
		/*******************************************************************************
		***************************Import data into formatted table*********************
		*******************************************************************************/

		IF OBJECT_ID(''tempdb..##SmartFocusAssessment'') IS NOT NULL DROP TABLE ##SmartFocusAssessment
		SELECT	CONVERT(INT, FanID) AS FanID
			,	CONVERT(INT, ClubID) ClubID
			,	CONVERT(VARCHAR(500), Email) Email
			,	CONVERT(FLOAT, ClubCashAvailable) AS ClubCashAvailable
			,	CONVERT(FLOAT, ClubCashPending) AS ClubCashPending
			,	CONVERT(FLOAT, LVTotalEarning) AS LVTotalEarning
			,	CONVERT(BIT, IsDebit) AS IsDebit
			,	CONVERT(BIT, IsCredit) AS IsCredit
			,	CONVERT(BIT, LoyaltyAccount) AS LoyaltyAccount
			,	CONVERT(BIT, IsLoyalty) AS IsLoyalty
			,	CONVERT(INT, SmartEmailSendID) AS LionSendID
			,	CONVERT(INT, Offer1) AS Offer1
			,	CONVERT(INT, Offer2) AS Offer2
			,	CONVERT(INT, Offer3) AS Offer3
			,	CONVERT(INT, Offer4) AS Offer4
			,	CONVERT(INT, Offer5) AS Offer5
			,	CONVERT(INT, Offer6) AS Offer6
			,	CONVERT(INT, Offer7) AS Offer7
			,	CONVERT(DATE, Offer1StartDate) AS Offer1StartDate
			,	CONVERT(DATE, Offer2StartDate) AS Offer2StartDate
			,	CONVERT(DATE, Offer3StartDate) AS Offer3StartDate
			,	CONVERT(DATE, Offer4StartDate) AS Offer4StartDate
			,	CONVERT(DATE, Offer5StartDate) AS Offer5StartDate
			,	CONVERT(DATE, Offer6StartDate) AS Offer6StartDate
			,	CONVERT(DATE, Offer7StartDate) AS Offer7StartDate
			,	CONVERT(DATE, Offer1EndDate) AS Offer1EndDate
			,	CONVERT(DATE, Offer2EndDate) AS Offer2EndDate
			,	CONVERT(DATE, Offer3EndDate) AS Offer3EndDate
			,	CONVERT(DATE, Offer4EndDate) AS Offer4EndDate
			,	CONVERT(DATE, Offer5EndDate) AS Offer5EndDate
			,	CONVERT(DATE, Offer6EndDate) AS Offer6EndDate
			,	CONVERT(DATE, Offer7EndDate) AS Offer7EndDate
			,	CONVERT(INT, RedeemOffer1) AS RedeemOffer1
			,	CONVERT(INT, RedeemOffer2) AS RedeemOffer2
			,	CONVERT(INT, RedeemOffer3) AS RedeemOffer3
			,	CONVERT(INT, RedeemOffer4) AS RedeemOffer4
			,	CONVERT(INT, RedeemOffer5) AS RedeemOffer5
			,	CONVERT(DATE, RedeemOffer1EndDate) AS RedeemOffer1EndDate
			,	CONVERT(DATE, RedeemOffer2EndDate) AS RedeemOffer2EndDate
			,	CONVERT(DATE, RedeemOffer3EndDate) AS RedeemOffer3EndDate
			,	CONVERT(DATE, RedeemOffer4EndDate) AS RedeemOffer4EndDate
			,	CONVERT(DATE, RedeemOffer5EndDate) AS RedeemOffer5EndDate
		INTO ##SmartFocusAssessment
		FROM ' + @TableName

		EXEC (@Qry)

		CREATE CLUSTERED INDEX CIX_SmartFocusAssessment_FanID ON ##SmartFocusAssessment (FanID)

	/***********************************************************************************************************************
		1.2.	Store Imported Datas Offer Details into Long Table
	***********************************************************************************************************************/

		IF OBJECT_ID('tempdb..#SmartFocusAssessment_Offers') IS NOT NULL DROP TABLE #SmartFocusAssessment_Offers
		SELECT	LionSendID
			,	FanID
			,	Email
			,	OfferSlot = 1
			,	Offer1 AS IronOfferID
			,	Offer1StartDate AS StartDate
			,	Offer1EndDate AS EndDate
		INTO #SmartFocusAssessment_Offers
		FROM ##SmartFocusAssessment osd

		DECLARE @Loop INT
			,	@Query VARCHAR(MAX)
	
		SET @Loop = 2

		WHILE @Loop < 8
			BEGIN

				SET @Query = '	INSERT INTO #SmartFocusAssessment_Offers
								SELECT	LionSendID
									,	FanID
									,	Email
									,	OfferSlot = ' + CONVERT(VARCHAR(1), @Loop) + '
									,	Offer' + CONVERT(VARCHAR(1), @Loop) + '
									,	Offer' + CONVERT(VARCHAR(1), @Loop) + 'StartDate
									,	Offer' + CONVERT(VARCHAR(1), @Loop) + 'EndDate
								FROM ##SmartFocusAssessment osd'

				EXEC(@Query)

				SET @Loop = @Loop + 1

			END

	/***********************************************************************************************************************
		1.3.	Store [SmartEmail].[OfferSlotData] Offer Details into Long Table
	***********************************************************************************************************************/

		IF OBJECT_ID('tempdb..#OfferSlotData_Offers') IS NOT NULL DROP TABLE #OfferSlotData_Offers
		SELECT	LionSendID
			,	FanID
			,	OfferSlot = 1
			,	Offer1 AS IronOfferID
			,	Offer1StartDate AS StartDate
			,	Offer1EndDate AS EndDate
		INTO #OfferSlotData_Offers
		FROM [SmartEmail].[OfferSlotData] osd
		WHERE EXISTS (	SELECT 1
						FROM ##SmartFocusAssessment sfa
						WHERE osd.FanID = sfa.FanID)
	
		SET @Loop = 2

		WHILE @Loop < 8
			BEGIN

				SET @Query = '	INSERT INTO #OfferSlotData_Offers
								SELECT	LionSendID
									,	FanID
									,	OfferSlot = ' + CONVERT(VARCHAR(1), @Loop) + '
									,	Offer' + CONVERT(VARCHAR(1), @Loop) + '
									,	Offer' + CONVERT(VARCHAR(1), @Loop) + 'StartDate
									,	Offer' + CONVERT(VARCHAR(1), @Loop) + 'EndDate
								FROM [SmartEmail].[OfferSlotData] osd
								WHERE EXISTS (	SELECT 1
												FROM ##SmartFocusAssessment sfa
												WHERE osd.FanID = sfa.FanID)'

				EXEC(@Query)

				SET @Loop = @Loop + 1

			END

			   

/*******************************************************************************************************************************************
	2. Insert the counts of the validation table and the details of it to the PostSFDUploadValidation_DataChecks table
*******************************************************************************************************************************************/

	INSERT INTO [SmartEmail].[PostSFDUploadValidation_DataChecks] (noRows
															 , TableName
															 , RunID
															 , SmartEmail
															 , LionSendID)
	Select (Select Count(Distinct FanID) FROM ##SmartFocusAssessment) AS Rows
		 , @TableName AS TableName
		 , Convert(VARCHAR, @RunID)
		 , 1 AS SmartEmail
		 , Convert(VARCHAR, @aLionSendID)

/*******************************************************************************************************************************************
	3. Checking for misalignment of key data
*******************************************************************************************************************************************/

	/***********************************************************************************************************************
		3.1. Do all customers exist in the SLC_Report..Fan table?
	***********************************************************************************************************************/

		INSERT INTO [SmartEmail].[PostSFDUploadValidation_FansToBeExcluded] (	FanID
																			,	Email
																			,	Reason)
		SELECT	sfa.FanID
			,	sfa.Email
			,	'Customer does not exist in Fan' AS Reason
		FROM ##SmartFocusAssessment sfa
		WHERE NOT EXISTS (	SELECT 1
							FROM [SLC_REPL].[dbo].[Fan] fa
							WHERE sfa.FanID = fa.ID)

		UNION ALL
		

	/***********************************************************************************************************************
		3.2. Do customers still have the same email address and are they still marketable?
	***********************************************************************************************************************/
	
		SELECT	sfa.FanID
			,	sfa.Email
			,	'Customer no longer emailable at this email address' AS Reason
		FROM ##SmartFocusAssessment sfa
		WHERE NOT EXISTS (	SELECT 1
							FROM [SLC_REPL].[dbo].[Fan] fa
							INNER JOIN [Relational].[Customer] cu
								ON fa.ID = cu.FanID
							WHERE sfa.FanID = cu.FanID
							AND cu.CurrentlyActive = 1
							AND cu.MarketableByEmail = 1
							AND fa.Email = sfa.Email)

		UNION ALL
		

	/***********************************************************************************************************************
		3.3. Does the ClubID listed for each customer still match their account details?
	***********************************************************************************************************************/
	
		SELECT	sfa.FanID
			,	sfa.Email
			,	'ClubID does not match' AS Reason
		FROM ##SmartFocusAssessment sfa
		WHERE EXISTS (	SELECT 1
						FROM [SLC_REPL].[dbo].[Fan] fa
						WHERE sfa.FanID = fa.ID
						AND sfa.ClubID != fa.ClubID)

		UNION ALL
		

	/***********************************************************************************************************************
		3.4. Is the customer listed in the SmartEmail.DailyData table?
	***********************************************************************************************************************/
	
		SELECT	sfa.FanID
			,	sfa.Email
			,	'Customer missing from SmartEmail.DailyData table' AS Reason
		FROM ##SmartFocusAssessment sfa
		WHERE NOT EXISTS (	SELECT 1
							FROM [SmartEmail].[DailyData] dd
							WHERE sfa.FanID = dd.FanID)

		UNION ALL
		

	/***********************************************************************************************************************
		3.5. Do the customer Club Cash balances match their account?
	***********************************************************************************************************************/
	
		SELECT	sfa.FanID
			,	sfa.Email
			,	'Balances Do not match' AS Reason
		FROM ##SmartFocusAssessment sfa
		WHERE EXISTS (	SELECT 1
						FROM [SmartEmail].[DailyData] dd
						WHERE sfa.FanID = dd.FanID
						AND (	sfa.ClubCashAvailable != dd.ClubCashAvailable
							OR sfa.Clubcashpending != dd.ClubCashPending
							OR sfa.LvTotalEarning != dd.LvTotalEarning))

		UNION ALL
		

	/***********************************************************************************************************************
		3.6. Is the Loyalty Account flag correct?
	***********************************************************************************************************************/
	
		SELECT	sfa.FanID
			,	sfa.Email
			,	'LoyaltyAccount field does not match'as Reason
		FROM ##SmartFocusAssessment sfa
		WHERE EXISTS (	SELECT 1
						FROM [SmartEmail].[TriggerEmailDailyFile_Calculated] tefd
						WHERE sfa.FanID = tefd.FanID
						AND sfa.LoyaltyAccount != tefd.LoyaltyAccount)

		UNION ALL
		

	/***********************************************************************************************************************
		3.7. Is the customer now deceased?
	***********************************************************************************************************************/
	
		SELECT	sfa.FanID
			,	sfa.Email
			,	'Deceased Customer' AS Reason
		FROM ##SmartFocusAssessment sfa
		WHERE EXISTS (	SELECT 1
						FROM [SLC_REPL].[dbo].[Fan] fa
						WHERE sfa.FanID = fa.ID
						AND fa.DeceasedDate IS NOT NULL)

		UNION ALL
		

	/***********************************************************************************************************************
		3.8. Is the Is Loyalty flag correct?
	***********************************************************************************************************************/
	
		SELECT	sfa.FanID
			,	sfa.Email
			,	'IsLoyalty field does not match' AS Reason
		FROM ##SmartFocusAssessment sfa
		WHERE EXISTS (	SELECT 1
						FROM [SmartEmail].[TriggerEmailDailyFile_Calculated] tefd
						WHERE sfa.FanID = tefd.FanID
						AND sfa.IsLoyalty != tefd.IsLoyalty)
 
		UNION ALL
		

	/***********************************************************************************************************************
		3.9. Are all the right Earn Offers listed with the correct start & end dates?
	***********************************************************************************************************************/

		--	Do Offer IDs Match?

		SELECT	DISTINCT
				sfa.FanID
			,	sfa.Email
			,	'Earn offer(s) Misaligned - IronOffer' AS Reason
		FROM #SmartFocusAssessment_Offers sfa
		WHERE NOT EXISTS (	SELECT 1
							FROM #OfferSlotData_Offers osd
							WHERE sfa.FanID = osd.FanID
							AND sfa.OfferSlot = osd.OfferSlot
							AND sfa.IronOfferID = osd.IronOfferID)

		UNION ALL

		--	Do StartDates Match?

		SELECT	DISTINCT
				sfa.FanID
			,	sfa.Email
			,	'Earn offer(s) Misaligned - IronOffer' AS Reason
		FROM #SmartFocusAssessment_Offers sfa
		WHERE NOT EXISTS (	SELECT 1
							FROM #OfferSlotData_Offers osd
							WHERE sfa.FanID = osd.FanID
							AND sfa.OfferSlot = osd.OfferSlot
							AND sfa.StartDate = CONVERT(DATE, osd.StartDATE, 105))
		AND sfa.IronOfferID NOT IN (8495)

		UNION ALL

		--	Do EndDates Match?

		SELECT	DISTINCT
				sfa.FanID
			,	sfa.Email
			,	'Earn offer(s) Misaligned - IronOffer' AS Reason
		FROM #SmartFocusAssessment_Offers sfa
		WHERE NOT EXISTS (	SELECT 1
							FROM #OfferSlotData_Offers osd
							WHERE sfa.FanID = osd.FanID
							AND sfa.OfferSlot = osd.OfferSlot
							AND sfa.EndDate = CONVERT(DATE, osd.EndDATE, 105))
		AND sfa.IronOfferID NOT IN (8495)
 
		UNION ALL
		

	/***********************************************************************************************************************
		3.10. Are all the right Burn Offers listed?
	***********************************************************************************************************************/
	
		SELECT	sfa.FanID
			,	sfa.Email
			,	'Burn offer(s) Misaligned' AS Reason
		FROM ##SmartFocusAssessment sfa
		WHERE EXISTS (SELECT 1
					  FROM [SmartEmail].[RedeemOfferSlotData] rosd
					  WHERE sfa.FanID = rosd.FanID
					  AND sfa.RedeemOffer1 != rosd.RedeemOffer1
					  AND sfa.RedeemOffer2 != rosd.RedeemOffer2
					  AND sfa.RedeemOffer3 != rosd.RedeemOffer3
					  AND sfa.RedeemOffer4 != rosd.RedeemOffer4
					  AND sfa.RedeemOffer5 != rosd.RedeemOffer5
					  AND sfa.RedeemOffer1EndDate != CONVERT(DATE, rosd.RedeemOffer1EndDATE, 105)
					  AND sfa.RedeemOffer2EndDate != CONVERT(DATE, rosd.RedeemOffer2EndDATE, 105)
					  AND sfa.RedeemOffer3EndDate != CONVERT(DATE, rosd.RedeemOffer3EndDATE, 105)
					  AND sfa.RedeemOffer4EndDate != CONVERT(DATE, rosd.RedeemOffer4EndDATE, 105)
					  AND sfa.RedeemOffer5EndDate != CONVERT(DATE, rosd.RedeemOffer5EndDATE, 105))


/*******************************************************************************************************************************************
	4. Update the details of SmartEmail.PostSFDUploadValidation_DataChecks table to see whether RBS staff are where they are expected to be
*******************************************************************************************************************************************/


	Update [SmartEmail].[PostSFDUploadValidation_DataChecks]
	Set isAngela = (Select Count(1) FROM ##SmartFocusAssessment Where FanID In (1923715,1923714))
	  , isMarianneRBS = (Select Count(1) FROM ##SmartFocusAssessment Where FanID In (5698997))
	  , isMariannePersonal = (Select Count(1) FROM ##SmartFocusAssessment Where FanID In (18412563))
	  , RunDateTime = GetDate()
	Where TableName = @TableName
	And RunID = Convert(VARCHAR, @RunID)

	If Object_ID('tempdb..##SmartFocusAssessment') Is Not Null Drop Table ##SmartFocusAssessment

End