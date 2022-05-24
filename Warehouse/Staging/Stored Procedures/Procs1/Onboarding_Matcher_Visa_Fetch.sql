/*

	Author:		Rory Francis

	Date:		2020-04-01

	Purpose:	To produce a list of MerchantIDs to be provided to Visa

*/

CREATE PROCEDURE [Staging].[Onboarding_Matcher_Visa_Fetch]

AS
	BEGIN

	/*******************************************************************************************************************************************
			1.		Fetch Partners & their RetailOutlet entries
	*******************************************************************************************************************************************/

		/***************************************************************************************************************************************
			1.1.	Fetch Partners to run for
		***************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#IronOffer') IS NOT NULL DROP TABLE #IronOffer;
			SELECT	PartnerID
				,	MAX(iof.EndDate) AS EndDate
			INTO #IronOffer
			FROM [SLC_REPL].[dbo].[IronOffer] iof
			WHERE iof.IsSignedOff = 1
			GROUP BY PartnerID

			CREATE CLUSTERED INDEX CIX_PartnerEnd ON #IronOffer (PartnerID, EndDate)

			DECLARE @6MonthsAgo DATE = DATEADD(MONTH, -6, GETDATE())
	
			IF OBJECT_ID('tempdb..#PartnersToFetch') IS NOT NULL DROP TABLE #PartnersToFetch;
			WITH
			Partners AS (	SELECT	DISTINCT
									COALESCE(pa.ID, p.ID) AS PrimaryPartnerID
								,	COALESCE(pa.Name, p.Name) AS PrimaryPartnerName
								,	p.ID AS PartnerID
								,	p.Name AS PartnerName
								,	MAX(fap.RegistrationDate) OVER (PARTITION BY COALESCE(pa.ID, p.ID)) AS RegistrationDate_Partner
								,	MAX(far.RegistrationDate) OVER (PARTITION BY COALESCE(pa.ID, p.ID)) AS RegistrationDate_Outlets
								,	MAX(iof.EndDate) OVER (PARTITION BY COALESCE(pa.ID, p.ID)) AS EndDate_IronOffer
							FROM [SLC_REPL].[dbo].[Partner] p
							LEFT JOIN [iron].[PrimaryRetailerIdentification] pri
								ON p.ID = pri.PartnerID
							LEFT JOIN [SLC_REPL].[dbo].[Partner] pa
								ON COALESCE(pri.PrimaryPartnerID, pri.PartnerID) = pa.ID
							INNER JOIN [SLC_REPL].[dbo].[Fan] fap
								ON p.FanID = fap.ID
							INNER JOIN [SLC_REPL].[dbo].[RetailOutlet] ro
								ON p.ID = ro.PartnerID
							INNER JOIN [SLC_REPL].[dbo].[Fan] far
								ON ro.FanID = far.ID
							LEFT JOIN #IronOffer iof
								ON p.ID = iof.PartnerID
							WHERE LEN(p.Name) > 1
							AND p.Status = 3
							AND p.Name NOT LIKE '%AMEX%'
							AND p.Name NOT LIKE '%Ireland%'
							AND p.Name NOT LIKE '%L''Effet%'
							AND p.Name NOT LIKE '%UAE%')

			SELECT PartnerID
			INTO #PartnersToFetch
			FROM Partners pa
			WHERE @6MonthsAgo < RegistrationDate_Partner
			OR @6MonthsAgo < RegistrationDate_Outlets
			OR @6MonthsAgo < EndDate_IronOffer

			CREATE CLUSTERED INDEX CIX_RetailOutletID ON #PartnersToFetch (PartnerID)


		/***************************************************************************************************************************************
			1.2.	Fetch all entries from the RetailOutlet table, getting additional Partner information and the date MID was added
		***************************************************************************************************************************************/
		
			IF OBJECT_ID('tempdb..#RetailOutlet') IS NOT NULL DROP TABLE #RetailOutlet
			SELECT	COALESCE(pa.ID, ro.PartnerID) AS PrimaryPartnerID
				,	COALESCE(pa.Name, p.Name) AS PrimaryPartnerName
				,	ro.PartnerID
				,	p.Name AS PartnerName
				,	p.RegisteredName
				,	p.MerchantAcquirer
				,	ro.ID AS RetailOutletID
				,	ro.MerchantID
				,	COALESCE(CONVERT(VARCHAR(50), TRY_CONVERT(BIGINT, REPLACE(REPLACE(ro.MerchantID, '#', ''), 'x', ''))), REPLACE(REPLACE(ro.MerchantID, '#', ''), 'x', '')) AS MerchantIDCleaned
				,	ro.Channel
				,	ro.PartnerOutletReference
				,	ro.FanID
				,	MAX(fa.RegistrationDate) OVER (PARTITION BY COALESCE(CONVERT(VARCHAR(50), TRY_CONVERT(BIGINT, REPLACE(REPLACE(ro.MerchantID, '#', ''), 'x', ''))), REPLACE(REPLACE(ro.MerchantID, '#', ''), 'x', ''))) AS RegistrationDate
			INTO #RetailOutlet
			FROM [SLC_REPL].[dbo].[RetailOutlet] ro
			INNER JOIN [SLC_REPL].[dbo].[Partner] p
				ON ro.PartnerID = p.ID
			INNER JOIN [SLC_REPL].[dbo].[Fan] fa
				ON ro.FanID = fa.ID
			LEFT JOIN [iron].[PrimaryRetailerIdentification] pri
				ON p.ID = pri.PartnerID
			LEFT JOIN [SLC_REPL].[dbo].[Partner] pa
				ON COALESCE(pri.PrimaryPartnerID, pri.PartnerID) = pa.ID
			WHERE EXISTS (	SELECT 1
							FROM #PartnersToFetch ptf
							WHERE p.ID = ptf.PartnerID)
			AND LEN(ro.MerchantID) > 1

			CREATE CLUSTERED INDEX CIX_RetailOutletID ON #RetailOutlet (RetailOutletID)


	/*******************************************************************************************************************************************
			2.		Fetch transaction details from Match for all Retail Outlet IDs
	*******************************************************************************************************************************************/

		/***************************************************************************************************************************************
			2.1.	Fetch the max ID per RetailOutletID
		***************************************************************************************************************************************/
	
			IF OBJECT_ID('tempdb..#Match') IS NOT NULL DROP TABLE #Match
			SELECT	RetailOutletID
				,	MerchantID
				,	MerchantID AS MerchantIDCleaned
				,	CONVERT(DATE, NULL) AS MaxAddedDate
				,	MAX(ID) AS MaxID
			INTO #Match
			FROM [SLC_REPL].[dbo].[Match] ma
			WHERE EXISTS (	SELECT 1
							FROM #RetailOutlet ro
							WHERE ma.RetailOutletID = ro.RetailOutletID)
			GROUP BY	RetailOutletID
					,	MerchantID
			   
			CREATE NONCLUSTERED INDEX IX_MaxID ON #Match (MaxID)


		/***************************************************************************************************************************************
			2.2.	Populate that MaxAddedDates by rejoining to the Match table
		***************************************************************************************************************************************/
	   
			UPDATE ma
			SET ma.MaxAddedDate = m.AddedDate
			FROM #Match ma
			INNER JOIN [SLC_REPL].[dbo].[Match] m
				ON ma.MaxID = m.ID


		/***************************************************************************************************************************************
			2.3.	Create a cleaned version of the MerchantID by removing all leading 0s
		***************************************************************************************************************************************/

			UPDATE #Match
			SET MerchantIDCleaned = COALESCE(CONVERT(VARCHAR(50), TRY_CONVERT(BIGINT, REPLACE(REPLACE(MerchantID, '#', ''), 'x', ''))), REPLACE(REPLACE(MerchantID, '#', ''), 'x', ''))


		/***************************************************************************************************************************************
			2.4.	Aggregate results on the MerchantID with leading 0's removed
		***************************************************************************************************************************************/

			;WITH
			Match_Updater AS (	SELECT MerchantIDCleaned
										, MAX(MaxAddedDate) AS MaxAddedDate
								FROM #Match
								GROUP BY MerchantIDCleaned)

			UPDATE m
			SET m.MaxAddedDate = mu.MaxAddedDate
			FROM #Match m
			INNER JOIN Match_Updater mu
				ON m.MerchantIDCleaned = mu.MerchantIDCleaned

			CREATE CLUSTERED INDEX CIX_RetailOutletID ON #Match (RetailOutletID)


	/*******************************************************************************************************************************************
			3.		Join all Match data to all Retail Outlets
	*******************************************************************************************************************************************/

		/***************************************************************************************************************************************
			3.1.	Join to the Match table previously fetched in step 1
		***************************************************************************************************************************************/
		
			IF OBJECT_ID('tempdb..#MatchOutlet') IS NOT NULL DROP TABLE #MatchOutlet
			SELECT	ro.PrimaryPartnerID
				,	ro.PrimaryPartnerName
				,	ro.PartnerID
				,	ro.PartnerName
				,	ro.RegisteredName
				,	ro.MerchantAcquirer
				,	ro.RetailOutletID
				,	ro.MerchantID
				,	ro.MerchantIDCleaned
				,	ro.Channel
				,	ro.PartnerOutletReference
				,	ro.FanID
				,	ma.MaxAddedDate
				,	ro.RegistrationDate
				,	CONVERT(VARCHAR(50), NULL) AS Visa_Onboarded
			INTO #MatchOutlet
			FROM #RetailOutlet ro
			LEFT JOIN #Match ma
				ON REPLACE(REPLACE(ro.MerchantID, '#', ''), 'x', '') = REPLACE(REPLACE(ma.MerchantID, '#', ''), 'x', '')
			

		/***************************************************************************************************************************************
			3.2.	Aggregate results on the MerchantID with leading 0's removed
		***************************************************************************************************************************************/

			;WITH
			Match_Updater AS (	SELECT MerchantIDCleaned
									 , MAX(MaxAddedDate) AS MaxAddedDate
									 , MAX(RegistrationDate) AS RegistrationDate
								FROM #MatchOutlet
								GROUP BY MerchantIDCleaned)

			UPDATE m
			SET	m.MaxAddedDate = mu.MaxAddedDate
			,	m.RegistrationDate = mu.RegistrationDate
			FROM #MatchOutlet m
			INNER JOIN Match_Updater mu
				ON m.MerchantIDCleaned = mu.MerchantIDCleaned
			

		/***************************************************************************************************************************************
			3.3.	Remove hashed MIDs
		***************************************************************************************************************************************/
		
			DELETE
			FROM #MatchOutlet
			WHERE (MerchantID LIKE 'ARCH%' OR MerchantID LIKE '#%' OR MerchantID LIKE 'x%')
			AND MerchantID != 'X2RSITO59IAE6DO'


	/*******************************************************************************************************************************************
			4.		Exclude partners with no activity & MIDs that are no longer active
	*******************************************************************************************************************************************/

		/***************************************************************************************************************************************
			4.1.	Fetch MIDs onboarded with Visa already
		***************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#OnboardedMIDs') IS NOT NULL DROP TABLE #OnboardedMIDs;
			SELECT	DISTINCT
					mg.MerchantID
				,	COALESCE(CONVERT(VARCHAR(50), TRY_CONVERT(BIGINT, REPLACE(REPLACE(mg.MerchantID, '#', ''), 'x', ''))), REPLACE(REPLACE(mg.MerchantID, '#', ''), 'x', '')) AS MerchantIDCleaned
			INTO #OnboardedMIDs
			FROM [Staging].[Onboarding_Matcher_Visa_ActiveList] mg
			UNION
			SELECT	DISTINCT
					ml.MerchantID
				,	COALESCE(CONVERT(VARCHAR(50), TRY_CONVERT(BIGINT, REPLACE(REPLACE(ml.MerchantID, '#', ''), 'x', ''))), REPLACE(REPLACE(ml.MerchantID, '#', ''), 'x', '')) AS MerchantIDCleaned
			FROM [Staging].[Onboarding_Matcher_Visa_ReponseFiles] ml
			


		/***************************************************************************************************************************************
			4.2.	Update the Visa_Onboarded column with data from MIDs onboarded with MCE already
		***************************************************************************************************************************************/

			UPDATE mo
			SET mo.Visa_Onboarded = mg.MerchantID
			FROM #MatchOutlet mo
			INNER JOIN #OnboardedMIDs mg
				ON mo.MerchantIDCleaned = mg.MerchantIDCleaned

			CREATE CLUSTERED INDEX CIX_MerchantID ON #MatchOutlet (PrimaryPartnerID, MerchantID)
			

		/***************************************************************************************************************************************
			4.3.	Update the Visa_Onboarded column with data from alternate MIDs onboarded with Visa already
		***************************************************************************************************************************************/

			IF OBJECT_ID('tempdb.dbo.#OutletsCardnet') IS NOT NULL drop table #OutletsCardnet;
			SELECT pa.ID AS PartnerID
				 , pa.Name AS PartnerName
				 , CASE WHEN pa.ID IN (4557, 4585, 4618, 3421, 4696, 4689, 4781) THEN 1 ELSE 0 END AS PrimaryPartner
				 , CASE
						WHEN ro.MerchantID LIKE '33%' THEN 'Clearance'
						ELSE 'Authorisation'
				   END AS MIDType
				 , ro.ID AS RetailOutletID
				 , ro.MerchantID
				 , fa.Address1
				 , fa.Address2
				 , fa.City
				 , fa.Postcode
				 , ro.PartnerOutletReference
			INTO #OutletsCardnet
			FROM [SLC_Repl].[dbo].[Partner] pa
			INNER JOIN [SLC_Repl].[dbo].[RetailOutlet] ro
				ON pa.ID = ro.PartnerID
			INNER JOIN [SLC_REPL].[dbo].[Fan] fa
				ON ro.FanID = fa.ID
			WHERE pa.ID IN (4578, 4614, 4617, 4618, 4705, 4557, 4585, 3421, 4696, 4698, 4689, 4681, 4781)
			--AND (ro.MerchantID LIKE '33%' OR ro.MerchantID LIKE '54%' OR ro.MerchantID LIKE '#33%' OR ro.MerchantID LIKE '#54%')

			CREATE CLUSTERED INDEX CIX_ID ON #OutletsCardnet (RetailOutletID)
		
			IF OBJECT_ID('tempdb.dbo.#MatchCardnet') IS NOT NULL drop table #MatchCardnet;
			SELECT PanID
				 , CONVERT(DATE, TransactionDate) AS TranDate
				 , Amount
				 , MIN(MerchantID) AS ClearanceMID
				 , MAX(MerchantID) AS AuthorisationMID
			INTO #MatchCardnet
			FROM [SLC_Repl].[dbo].[Match] ma
			WHERE EXISTS (SELECT 1 FROM #OutletsCardnet o WHERE ma.RetailOutletID = o.RetailOutletID)
			GROUP BY PanID
				   , CONVERT(DATE, TransactionDate)
				   , Amount
			HAVING COUNT(DISTINCT MerchantID) > 1
			
			DELETE	
			FROM #MatchCardnet	
			WHERE ClearanceMID NOT LIKE '33%'
			OR AuthorisationMID NOT LIKE '54%'
		
			IF OBJECT_ID('tempdb.dbo.#MIDsCardnet') IS NOT NULL drop table #MIDsCardnet;
			SELECT o.PartnerID AS PartnerID_Auth
				 , o.PartnerName AS PartnerName_Auth
				 , o2.PartnerID AS PartnerID_Clear
				 , o2.PartnerName AS PartnerName_Clear
				 , ma.AuthorisationMID
				 , ma.ClearanceMID
			INTO #MIDsCardnet
			FROM #OutletsCardnet o
			INNER JOIN #MatchCardnet ma
				ON o.MerchantID = ma.AuthorisationMID
			INNER JOIN #OutletsCardnet o2
				ON ma.ClearanceMID = o2.MerchantID
			GROUP BY o.PartnerID
				   , o.PartnerName
				   , o2.PartnerID
				   , o2.PartnerName
				   , ma.AuthorisationMID
				   , ma.ClearanceMID
		
			UPDATE mo
			SET mo.Visa_Onboarded = ob.MerchantIDCleaned
			FROM #MIDsCardnet mc
			INNER JOIN #MatchOutlet mo
				ON mc.AuthorisationMID = mo.MerchantID
			INNER JOIN #OnboardedMIDs ob
				ON mc.ClearanceMID = ob.MerchantID
			WHERE mo.Visa_Onboarded IS NULL

			UPDATE mo
			SET mo.Visa_Onboarded = ob.MerchantIDCleaned
			FROM [Relational].[AlternateMerchantID] mc
			INNER JOIN #MatchOutlet mo
				ON mc.MerchantID = mo.MerchantID
			INNER JOIN #OnboardedMIDs ob
				ON mc.AlternateMerchantID = ob.MerchantID
			WHERE mo.Visa_Onboarded IS NULL

			ALTER INDEX CIX_MerchantID ON #MatchOutlet REBUILD
			
		/***************************************************************************************************************************************
			4.4.	Remove MIDs onboarded with MCE already
		***************************************************************************************************************************************/

			DELETE ro
			FROM #MatchOutlet ro
			WHERE Visa_Onboarded IS NOT NULL


		/***************************************************************************************************************************************
			4.5.	If there are multiple leading 0 versions of MIDs cut down to the actual MID
		***************************************************************************************************************************************/
	
			IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
			SELECT	cc.ConsumerCombinationID
				,	cc.MID
			INTO #CC
			FROM [Relational].[ConsumerCombination] cc
			WHERE EXISTS (	SELECT 1
							FROM #MatchOutlet ro
							WHERE cc.MID = ro.MerchantID)

			CREATE CLUSTERED INDEX CIX_CCID ON #CC (ConsumerCombinationID, MID)

			IF OBJECT_ID('tempdb..#MIDsToRemove') IS NOT NULL DROP TABLE #MIDsToRemove
			SELECT DISTINCT
					ro.MerchantID
					, RANK() OVER (PARTITION BY ro.merchantIDCleaned ORDER BY CASE
																				WHEN vm.MerchantID IS NOT NULL THEN 1
																				WHEN cc.MID IS NOT NULL THEN 2
																				ELSE 3
																			END, LEN(ro.MerchantID)) AS PriorityMIDRank
			INTO #MIDsToRemove
			FROM #MatchOutlet ro
			LEFT JOIN (SELECT DISTINCT MC_ClearingAcquiringMerchantID AS MerchantID FROM [Staging].[Onboarding_Matcher_Mastercard_ReponseFiles]) vm
				ON ro.MerchantID = vm.MerchantID
			LEFT JOIN (SELECT DISTINCT MID FROM #CC) cc
				ON ro.MerchantID = cc.MID

			--DELETE ro
			--FROM #MatchOutlet ro
			--WHERE EXISTS (	SELECT 1
			--				FROM #MIDsToRemove mtr
			--				WHERE PriorityMIDRank > 1
			--				AND ro.MerchantID = mtr.MerchantID)
							

		/***************************************************************************************************************************************
			4.6.	Remove non Visa MIDs
		***************************************************************************************************************************************/

			DELETE mo
			FROM #MatchOutlet mo
			WHERE (LEN(MerchantID) = 15 AND (MerchantID LIKE '52656%' OR MerchantID LIKE '54043%'))
			--AND EXISTS (	SELECT MerchantID
			--				FROM [Staging].[Onboarding_Matcher_Visa_ReviewFiles] rf
			--				WHERE rf.Result = 'CAID not recognised'
			--				AND DATEADD(MONTH, -1, GETDATE()) < rf.ValidationDate
			--				AND mo.MerchantID = rf.MerchantID
			--				GROUP BY MerchantID
			--				HAVING COUNT(*) > 1)

					
		/***************************************************************************************************************************************
			4.7.	Bespoke filters
		***************************************************************************************************************************************/
		
			IF OBJECT_ID('tempdb..#CT') IS NOT NULL DROP TABLE #CT
			SELECT	cc.MID
				,	MAX(ct.TranDate) AS MaxTran
			INTO #CT
			FROM #CC cc
			INNER JOIN [Relational].[ConsumerTransaction_MyRewards] ct
				ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
			GROUP BY cc.MID
			
			DELETE mo
			FROM #MatchOutlet mo
			INNER JOIN #CT ct
				ON mo.MerchantID = ct.MID
			WHERE ct.MaxTran < DATEADD(YEAR, -1, GETDATE())

			/*

			SELECT *
			FROM #MatchOutlet
			ORDER BY PrimaryPartnerName

			DELETE mo
			FROM #MatchOutlet mo
			WHERE PartnerName LIKE '%Nero%'
			AND LEN(MerchantID) < 9

			*/

	/*******************************************************************************************************************************************
			5.		Produce the table of MID entires to send
	*******************************************************************************************************************************************/

		/***************************************************************************************************************************************
			5.1.	Fetch entires with different Narratives
		***************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#MerchantNameDifferent') IS NOT NULL DROP TABLE #MerchantNameDifferent;
			SELECT	DISTINCT
					mo.PrimaryPartnerID
				,	mo.PrimaryPartnerName
				,	mo.PartnerID
				,	mo.PartnerName
				,	vs.RetailOutletID
				,	vs.MerchantID
				,	COALESCE(CONVERT(VARCHAR(50), TRY_CONVERT(BIGINT, REPLACE(REPLACE(vs.MerchantID, '#', ''), 'x', ''))), REPLACE(REPLACE(vs.MerchantID, '#', ''), 'x', '')) AS MerchantIDCleaned
				,	vs.ResultReason
				,	CASE
						WHEN LEN(vs.ResultReason) = CHARINDEX(']', vs.ResultReason) THEN NULL
						ELSE SUBSTRING(REPLACE(REPLACE(vs.ResultReason, '[', ''),']', ''), 1, CHARINDEX(']', vs.ResultReason) - 2)
					END AS ResultReason_OriginatorID
				,	CASE
						WHEN LEN(vs.ResultReason) = CHARINDEX(']', vs.ResultReason) THEN REPLACE(REPLACE(vs.ResultReason, '[', ''),']', '')
						ELSE SUBSTRING(REPLACE(REPLACE(vs.ResultReason, '[', ''),']', ''), CHARINDEX(']', vs.ResultReason) - 1, LEN(vs.ResultReason))
					END AS ResultReason_DBAName
			INTO #MerchantNameDifferent
			FROM [Staging].[Onboarding_Matcher_Visa_ReviewFiles] vs
			INNER JOIN #MatchOutlet mo
				ON vs.RetailOutletID = mo.RetailOutletID
			WHERE vs.Result LIKE '%Merchant%Name%'
			
			DELETE mnd
			FROM #MerchantNameDifferent mnd
			INNER JOIN [Staging].[VISA_IncorrectMerchantNames] imn
				ON mnd.MerchantID = imn.MerchantID
				AND mnd.ResultReason_DBAName = imn.PartnerName


		/***************************************************************************************************************************************
			5.2.	Fetch & clean data ready for File format
		***************************************************************************************************************************************/
	
			IF OBJECT_ID('tempdb..#MIDsToSend') IS NOT NULL DROP TABLE #MIDsToSend
			SELECT DISTINCT
				   ro.MerchantID
				 , pa.Name AS PrimaryPartnerName
				 , fa.City
				 , CASE
						WHEN fa.Address1 = '' THEN fa.Address2
						WHEN fa.Address2 = '' THEN fa.Address1
						ELSE fa.Address1 + ', ' + fa.Address2
				   END AS Address
				 , fa.Postcode
				 , pa.RegisteredName
				 , CONVERT(INT, cc.OriginatorID) AS OriginatorID
				 , pa.MerchantAcquirer

				 , CASE
						WHEN ro.MerchantID IN ('2100399337', '2100399338', '336707216', '328374898', '526567002351232', '498750002475656') THEN '276'
						WHEN iso.Alpha3Code IS NOT NULL THEN NumericCode
						ELSE '826'
				   END AS MerchantCountry
				 , CASE
						WHEN ro.Channel = 1 THEN 'Online'
						WHEN ro.Channel = 2 THEN 'In-Store'
						ELSE 'Unknown'
				   END AS OnlineInStore
				 , ro.ID AS RetailOutletID
				 , COALESCE(CONVERT(VARCHAR(50), TRY_CONVERT(BIGINT, REPLACE(REPLACE(ro.MerchantID, '#', ''), 'x', ''))), REPLACE(REPLACE(ro.MerchantID, '#', ''), 'x', '')) AS MerchantIDCleaned
			INTO #MIDsToSend
			FROM [SLC_REPL].[dbo].[RetailOutlet] ro
			INNER JOIN [SLC_REPL].[dbo].[Fan] fa
				ON ro.FanID = fa.ID
			INNER JOIN [SLC_REPL].[dbo].[Partner] pa
				ON ro.PartnerID = pa.ID
			LEFT JOIN [Relational].[Partner] pa_r
				ON ro.PartnerID = pa_r.PartnerID
			LEFT JOIN [Relational].[ConsumerCombination] cc
				ON ro.MerchantID = cc.MID
				AND pa_r.BrandID = cc.BrandID
			LEFT JOIN [Relational].[CountryCodes_ISO_2] iso
				ON CASE
						WHEN cc.IsCreditOrigin = 1 THEN LEFT(iso.Alpha3Code, 2)
						ELSE iso.Alpha2Code
				   END = cc.LocationCountry
			WHERE EXISTS (	SELECT 1
							FROM #MatchOutlet mo
							WHERE ro.ID = mo.RetailOutletID)

			INSERT INTO #MIDsToSend
			SELECT DISTINCT
				   mts.MerchantID
				 , COALESCE(mnd.ResultReason_DBAName, mts.PrimaryPartnerName) AS PrimaryPartnerName
				 , mts.City
				 , mts.Address
				 , mts.Postcode
				 , mts.RegisteredName
				 , COALESCE(mnd.ResultReason_OriginatorID, mts.OriginatorID) AS OriginatorID
				 , mts.MerchantAcquirer

				 , mts.MerchantCountry
				 , mts.OnlineInStore
				 , mts.RetailOutletID
				 , mts.MerchantIDCleaned
			FROM #MIDsToSend mts
			INNER JOIN #MerchantNameDifferent mnd
				ON COALESCE(CONVERT(VARCHAR(50), TRY_CONVERT(BIGINT, REPLACE(REPLACE(mts.MerchantID, '#', ''), 'x', ''))), REPLACE(REPLACE(mts.MerchantID, '#', ''), 'x', '')) = mnd.MerchantIDCleaned


/*******************************************************************************************************************************************
		6.		Insert to logging table
*******************************************************************************************************************************************/

	/***************************************************************************************************************************************
		6.1.	Remove rows entered for today already
	***************************************************************************************************************************************/
	
			DECLARE @FileDate DATE = GETDATE()

			DELETE sf
			FROM [Staging].[Onboarding_Matcher_Visa_SubmittedFiles] sf
			WHERE sf.SentDate = @FileDate
					

	/***************************************************************************************************************************************
		6.2.	Insert to logging table
	***************************************************************************************************************************************/

		INSERT INTO [Staging].[Onboarding_Matcher_Visa_SubmittedFiles] (MerchantID
																	,	PartnerName
																	,	City
																	,	Address
																	,	Postcode
																	,	RegisteredName
																	,	AcquirerBIN
																	,	AcquirerName
																	,	MerchantCountryCode_ISO
																	,	OnlineInStore
																	,	RetailOutletID
																	,	SentDate)
		SELECT DISTINCT
			   MerchantID
			 , PrimaryPartnerName AS PartnerName
			 , City
			 , Address
			 , Postcode
			 , RegisteredName
			 , COALESCE(CONVERT(VARCHAR(10), OriginatorID), '') AS AcquirerBIN
			 , MerchantAcquirer

			 , MerchantCountry AS MerchantCountryCode_ISO

			 , OnlineInStore
			 , RetailOutletID
			 , @FileDate
		FROM #MIDsToSend
		ORDER BY RegisteredName
			   , PartnerName
			   , MerchantID

/*******************************************************************************************************************************************
	7. Output results
*******************************************************************************************************************************************/
	
	SELECT DISTINCT
		   MerchantID
		 , PrimaryPartnerName AS PartnerName
		 , City
		 , Address
		 , Postcode
		 , RegisteredName
		 , COALESCE(CONVERT(VARCHAR(10), OriginatorID), '') AS AcquirerBIN
		 , MerchantAcquirer

		 , MerchantCountry AS MerchantCountryCode_ISO

		 , OnlineInStore
		 , RetailOutletID
	FROM #MIDsToSend
	ORDER BY RegisteredName
		   , PartnerName
		   , MerchantID


	END