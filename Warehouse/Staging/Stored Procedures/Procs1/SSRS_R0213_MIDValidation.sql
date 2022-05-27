
CREATE PROCEDURE [Staging].[SSRS_R0213_MIDValidation] @BrandID INT
AS
	BEGIN

	/*
	SELECT *
	FROM [Relational].[Brand]
	WHERE BrandName LIKE '%burberry%'
	*/

	--	DECLARE @BrandID INT = 2107

	--SET @BrandID = 9999

/*******************************************************************************************************************************************
	1. Declare Variables
*******************************************************************************************************************************************/

	DECLARE @ValidationID INT
	--	,	@BrandID INT
		,	@BrandName VARCHAR(100)

	SELECT	@ValidationID = MAX(COALESCE(ValidationID, 0))
	FROM (	SELECT MAX(ValidationID) AS ValidationID
			FROM [Staging].[MIDValidation_MIDs]
			UNION ALL
			SELECT MAX(ValidationID) AS ValidationID
			FROM [Staging].[MIDValidation_Details]) mv

	--	SELECT @ValidationID = 159
	
	IF @BrandID IS NOT NULL
		BEGIN

			SELECT	@ValidationID = MAX(COALESCE(ValidationID, 0))
			FROM (	SELECT MAX(ValidationID) AS ValidationID
					FROM [Staging].[MIDValidation_MIDs]
					WHERE BrandID = @BrandID
					UNION ALL
					SELECT MAX(ValidationID) AS ValidationID
					FROM [Staging].[MIDValidation_Details]
					WHERE BrandID = @BrandID) mv

		END
	
	IF @BrandID IS NULL
		BEGIN
			SELECT	@BrandID = MIN(BrandID)
			FROM [Staging].[MIDValidation_Details]
			WHERE ValidationID = @ValidationID

		END

	SELECT	@BrandName = '%' + BrandName + '%'
	FROM [Relational].[Brand]
	WHERE BrandID = @BrandID

	--	SELECT @ValidationID, @BrandID, @BrandName


/*******************************************************************************************************************************************
	2. Fetch all MIDs & details from the retailers file
*******************************************************************************************************************************************/
	
	IF OBJECT_ID('tempdb..#MIDValidation_Details') IS NOT NULL DROP TABLE #MIDValidation_Details
	SELECT	BrandID
		,	PartnerID
		,	MIDListType
		,	RetailerType
	INTO #MIDValidation_Details
	FROM [Staging].[MIDValidation_Details]
	WHERE ValidationID = @ValidationID

	IF OBJECT_ID('tempdb..#MIDValidation_MIDs') IS NOT NULL DROP TABLE #MIDValidation_MIDs
	SELECT	mvm.BrandID
		,	(SELECT ID FROM [SLC_REPL].[dbo].[Partner] WHERE Name = PartnerName AND FanID IS NOT NULL) AS PartnerID
		,	CASE WHEN PartnerName = '' THEN NULL ELSE PartnerName END AS PartnerName
		,	REPLACE(MerchantID, ' ', '') AS MerchantID
		,	CASE WHEN AddressLine1 = '' THEN NULL ELSE AddressLine1 END AS Address1
		,	CASE WHEN AddressLine2 = '' THEN NULL ELSE AddressLine2 END AS Address2
		,	CASE WHEN City = '' THEN NULL ELSE City END AS City
		,	CASE WHEN Postcode = '' THEN NULL ELSE Postcode END AS Postcode
		,	CASE WHEN County = '' THEN NULL ELSE County END AS County
		,	CASE WHEN ContactPhone = '' THEN NULL ELSE ContactPhone END AS Telephone
		,	CASE WHEN PartnerOutletReference = '' THEN NULL ELSE PartnerOutletReference END AS PartnerOutletReference
		,	CASE WHEN Channel = '' THEN NULL ELSE Channel END AS Channel
		,	CASE WHEN Notes = '' THEN NULL ELSE Notes END AS Notes
	INTO #MIDValidation_MIDs
	FROM [Staging].[MIDValidation_MIDs] mvm
	WHERE ValidationID = @ValidationID
	AND MerchantID != ''

/*******************************************************************************************************************************************
	3. Fetch all MIDs for the selected partner, currently or preivously incentivised
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#RetailOutlets') IS NOT NULL DROP TABLE #RetailOutlets
	SELECT	pa.ID AS PartnerID
		,	pa.Name AS PartnerName
		,	ro.ID AS RetailOutletID
		,	ro.MerchantID	--	COALESCE(mtg.MID_Join, REPLACE(REPLACE(ro.MerchantID, '#', ''), 'x', '')) AS MerchantID
		,	CASE WHEN fa.Address1 = '' THEN NULL ELSE fa.Address1 END AS Address1
		,	CASE WHEN fa.Address2 = '' THEN NULL ELSE fa.Address2 END AS Address2
		,	CASE WHEN fa.City = '' THEN NULL ELSE fa.City END AS City
		,	CASE WHEN fa.Postcode = '' THEN NULL ELSE fa.Postcode END AS Postcode
		,	CASE WHEN fa.County = '' THEN NULL ELSE fa.County END AS County
		,	CASE WHEN fa.Telephone = '' THEN NULL ELSE fa.Telephone END AS Telephone
		,	CASE WHEN ro.PartnerOutletReference = '' THEN NULL ELSE ro.PartnerOutletReference END AS PartnerOutletReference
		,	ro.Channel
		,	CASE
				WHEN ro.Coordinates IS NOT NULL THEN 1
				ELSE 0
			END AS CurrentAddressDetailsCorrect
		--,	MAX(CONVERT(DATE, COALESCE(mtg.StartDate, GETDATE()))) AS StartDate
		--,	MAX(mtg.EndDate) AS EndDate
	INTO #RetailOutlets
	FROM [SLC_REPL].[dbo].[RetailOutlet] ro
	INNER JOIN [SLC_REPL].[dbo].[Partner] pa
		ON ro.PartnerID = pa.ID
	INNER JOIN [SLC_REPL].[dbo].[Fan] fa
		ON ro.FanID = fa.ID
	--LEFT JOIN [Relational].[MIDTrackingGAS] mtg
	--	ON ro.ID = mtg.RetailOutletID
	WHERE (EXISTS (	SELECT 1
					FROM #MIDValidation_MIDs mvi
					WHERE ro.MerchantID = mvi.MerchantID)	-- REPLACE(REPLACE(ro.MerchantID, '#', ''), 'x', '') = REPLACE(REPLACE(mvi.MerchantID, '#', ''), 'x', ''))
	OR EXISTS (	SELECT 1
				FROM #MIDValidation_Details md
				WHERE ro.PartnerID = md.PartnerID))
	AND ro.MerchantID NOT LIKE '%#%'
	GROUP BY	pa.ID
			,	pa.Name
			,	ro.ID
			,	ro.MerchantID
			,	fa.Address1
			,	fa.Address2
			,	fa.City
			,	fa.Postcode
			,	fa.County
			,	fa.Telephone
			,	ro.PartnerOutletReference
			,	ro.Channel
			,	CASE
					WHEN ro.Coordinates IS NOT NULL THEN 1
					ELSE 0
				END

	CREATE CLUSTERED INDEX CIX_MID ON #RetailOutlets (MerchantID)

/*******************************************************************************************************************************************
	4. Combine MID Lists
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#CombinedMIDs') IS NOT NULL DROP TABLE #CombinedMIDs
	SELECT	@BrandID AS BrandID
		,	COALESCE(mvm.PartnerID, ro.PartnerID) AS PartnerID
		,	COALESCE(mvm.PartnerName, ro.PartnerName) AS PartnerName
		,	COALESCE(mvm.MerchantID, ro.MerchantID) AS MerchantID
		,	CASE WHEN ro.CurrentAddressDetailsCorrect = 1 THEN COALESCE(ro.Address1, mvm.Address1) ELSE COALESCE(mvm.Address1, ro.Address1) END AS Address1
		,	CASE WHEN ro.CurrentAddressDetailsCorrect = 1 THEN COALESCE(ro.Address2, mvm.Address2) ELSE COALESCE(mvm.Address2, ro.Address2) END AS Address2
		,	CASE WHEN ro.CurrentAddressDetailsCorrect = 1 THEN COALESCE(ro.City, mvm.City) ELSE COALESCE(mvm.City, ro.City) END AS City
		,	CASE WHEN ro.CurrentAddressDetailsCorrect = 1 THEN COALESCE(ro.Postcode, mvm.Postcode) ELSE COALESCE(mvm.Postcode, ro.Postcode) END AS Postcode
		,	CASE WHEN ro.CurrentAddressDetailsCorrect = 1 THEN COALESCE(ro.County, mvm.County) ELSE COALESCE(mvm.County, ro.County) END AS County
		,	CASE WHEN ro.CurrentAddressDetailsCorrect = 1 THEN COALESCE(ro.Telephone, mvm.Telephone) ELSE COALESCE(mvm.Telephone, ro.Telephone) END AS Telephone
		,	COALESCE(mvm.PartnerOutletReference, ro.PartnerOutletReference) AS PartnerOutletReference
		,	COALESCE(mvm.Channel, CASE WHEN ro.Channel = 1 THEN 'Online' WHEN ro.Channel = 2 THEN 'In Store' ELSE 'Unknown' END) AS Channel
		,	CASE WHEN mvm.MerchantID IS NOT NULL THEN 1 ELSE 0 END AS InClientList
		,	CASE WHEN ro.MerchantID IS NOT NULL THEN 1 ELSE 0 END AS OnGAS
		,	CASE WHEN ro.PartnerID IN (SELECT PartnerID FROM #MIDValidation_MIDs) THEN 1 ELSE 0 END AS OnGASOnTheCorrectPartnerRecord
		,	COALESCE(CurrentAddressDetailsCorrect, 0) AS CurrentAddressDetailsCorrect
	INTO #CombinedMIDs
	FROM #MIDValidation_MIDs mvm
	FULL OUTER JOIN #RetailOutlets ro
		ON mvm.MerchantID = ro.MerchantID

	CREATE CLUSTERED INDEX CIX_MID ON #CombinedMIDs (MerchantID)


/*******************************************************************************************************************************************
	5. Fetch CCs for all included MIDs
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#ConsumerCombination_Removed0') IS NOT NULL DROP TABLE #ConsumerCombination_Removed0;
	SELECT	MerchantID_Provided = cm.MerchantID
		,	MerchantID_MatchedOn = cc.MID
		,	cc.Narrative
		,	cc.BrandID
		,	cc.ConsumerCombinationID
		,	cm.InClientList
		,	cm.OnGAS
		,	cm.OnGASOnTheCorrectPartnerRecord
	INTO #ConsumerCombination_Removed0
	FROM [Relational].[ConsumerCombination] cc
	INNER JOIN #CombinedMIDs cm
		ON REPLACE(cc.MID, '0', '') = REPLACE(cm.MerchantID, '0', '')
		
	CREATE NONCLUSTERED INDEX IX_MID ON #ConsumerCombination_Removed0 (MerchantID_MatchedOn, ConsumerCombinationID)

	IF OBJECT_ID('tempdb..#ConsumerCombination') IS NOT NULL DROP TABLE #ConsumerCombination;
	SELECT	MerchantID_Provided = cm.MerchantID
		,	MerchantID_MatchedOn = cc.MID
		,	cc.Narrative
		,	cc.BrandID
		,	cc.ConsumerCombinationID
		,	cm.InClientList
		,	cm.OnGAS
		,	cm.OnGASOnTheCorrectPartnerRecord
	INTO #ConsumerCombination
	FROM [Relational].[ConsumerCombination] cc
	INNER JOIN #CombinedMIDs cm
		ON cc.MID = cm.MerchantID
		
	CREATE NONCLUSTERED INDEX IX_MID ON #ConsumerCombination (MerchantID_MatchedOn, ConsumerCombinationID)
					
	INSERT INTO #ConsumerCombination
	SELECT	MerchantID_Provided = cm.MerchantID
		,	MerchantID_MatchedOn = cc.MerchantID_MatchedOn
		,	cc.Narrative
		,	cc.BrandID
		,	cc.ConsumerCombinationID
		,	cm.InClientList
		,	cm.OnGAS
		,	cm.OnGASOnTheCorrectPartnerRecord
	FROM #ConsumerCombination_Removed0 cc
	INNER JOIN #CombinedMIDs cm
		ON cc.MerchantID_MatchedOn LIKE '%0' + cm.MerchantID
	WHERE NOT EXISTS (	SELECT 1
						FROM #ConsumerCombination c
						WHERE cc.ConsumerCombinationID = c.ConsumerCombinationID)

	ALTER INDEX IX_MID ON #ConsumerCombination REBUILD

	INSERT INTO #ConsumerCombination
	SELECT	MerchantID_Provided = cm.MerchantID
		,	MerchantID_MatchedOn = cc.MerchantID_MatchedOn
		,	cc.Narrative
		,	cc.BrandID
		,	cc.ConsumerCombinationID
		,	cm.InClientList
		,	cm.OnGAS
		,	cm.OnGASOnTheCorrectPartnerRecord
	FROM #ConsumerCombination_Removed0 cc
	INNER JOIN #CombinedMIDs cm
		ON cm.MerchantID LIKE '%0' + cc.MerchantID_MatchedOn
	--	AND cc.MID NOT IN ('', '%', '0')
	WHERE NOT EXISTS (	SELECT 1
						FROM #ConsumerCombination c
						WHERE cc.ConsumerCombinationID = c.ConsumerCombinationID)

	ALTER INDEX IX_MID ON #ConsumerCombination REBUILD

	INSERT INTO #ConsumerCombination
	SELECT	CASE WHEN cc.MID LIKE 'VCR[0-9]%' THEN 'VCR' ELSE cc.MID END AS MerchantID
		,	CASE WHEN cc.MID LIKE 'VCR[0-9]%' THEN 'VCR' ELSE cc.MID END AS MID
		,	cc.Narrative
		,	cc.BrandID
		,	cc.ConsumerCombinationID
		,	0
		,	0
		,	0
	FROM [Relational].[ConsumerCombination] cc
	WHERE cc.BrandID = @BrandID
	AND NOT EXISTS (SELECT 1
					FROM #ConsumerCombination c
					WHERE cc.ConsumerCombinationID = c.ConsumerCombinationID)

	ALTER INDEX IX_MID ON #ConsumerCombination REBUILD



	IF OBJECT_ID('tempdb..#CurveCard') IS NOT NULL DROP TABLE #CurveCard;
	WITH
	CurveCard AS (SELECT ConsumerCombinationID
					   , MID
				  FROM [Relational].[ConsumerCombination] cc
				  WHERE cc.BrandID != 944
				  AND (cc.Narrative LIKE 'CRV*%' OR cc.Narrative LIKE 'CURVE*%'))

	SELECT ConsumerCombinationID
	INTO #CurveCard
	FROM CurveCard
	UNION
	SELECT ConsumerCombinationID
	FROM [Relational].[ConsumerCombination] cc
	WHERE EXISTS (SELECT 1
				  FROM CurveCard cu
				  WHERE cc.MID = cu.MID
				  AND LEN(cu.MID) > 0)
	AND cc.BrandID != 944
		
	CREATE CLUSTERED INDEX CIX_CCID ON #CurveCard (ConsumerCombinationID)
				
	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC;
	SELECT	DISTINCT
			cc.MerchantID_Provided
		,	cc.MerchantID_MatchedOn
		,	cc.Narrative
		,	mcc.MCCDesc
		,	c.LocationCountry
		,	cc.BrandID
		,	cc.ConsumerCombinationID
		,	cc.InClientList
		,	cc.OnGAS
		,	cc.OnGASOnTheCorrectPartnerRecord
		,	c.IsCreditOrigin
	INTO #CC
	FROM #ConsumerCombination cc
	INNER JOIN [Relational].[ConsumerCombination] c
		ON cc.ConsumerCombinationID = c.ConsumerCombinationID
	INNER JOIN [Relational].[MCCList] mcc
		ON c.MCCID = mcc.MCCID
	WHERE cc.MerchantID_MatchedOn != ''
	AND cc.MerchantID_MatchedOn NOT LIKE 'VCR%'
	AND cc.Narrative NOT LIKE 'PayPal%'
	AND cc.Narrative NOT LIKE 'PP%'
	AND NOT EXISTS (SELECT 1
					FROM #CurveCard cur
					WHERE cc.ConsumerCombinationID = cur.ConsumerCombinationID)

	CREATE CLUSTERED INDEX CIX_CID ON #CC (ConsumerCombinationID)

	UPDATE cc
	SET cc.LocationCountry = cc2.LocationCountry
	FROM #CC cc
	INNER JOIN [Relational].[CountryCodes_ISO_2] c
		ON cc.LocationCountry = LEFT(c.Alpha3Code, 2)
		AND cc.IsCreditOrigin = 1
	INNER JOIN #CC cc2
		ON cc.MerchantID_MatchedOn = cc2.MerchantID_MatchedOn
		AND cc.Narrative = cc2.Narrative
		AND cc2.IsCreditOrigin = 0
		AND c.Alpha2Code = cc2.LocationCountry


/*******************************************************************************************************************************************
	6. Fetch transaction details for all included MIDs
*******************************************************************************************************************************************/

	DECLARE @LastYear DATE = DATEADD(YEAR, -1, GETDATE())
	
	IF OBJECT_ID('tempdb..#CT_Temp') IS NOT NULL DROP TABLE #CT_Temp;
	SELECT	ct.ConsumerCombinationID
		,	ct.IsOnline
		,	MIN(ct.TranDate) AS FirstTran
		,	MAX(ct.TranDate) AS LastTran
		,	SUM(ct.Amount) AS Amount
	INTO #CT_Temp
	FROM [Relational].[ConsumerTransaction] ct
	WHERE @LastYear < ct.TranDate
	AND EXISTS (SELECT 1
				FROM #CC cc
				WHERE cc.ConsumerCombinationID = ct.ConsumerCombinationID)
	GROUP BY	ct.ConsumerCombinationID
			,	ct.IsOnline

	CREATE CLUSTERED INDEX CIX_CID ON #CT_Temp (ConsumerCombinationID)
	
	IF OBJECT_ID('tempdb..#CT') IS NOT NULL DROP TABLE #CT;
	SELECT	cc.MerchantID_Provided
		,	cc.MerchantID_MatchedOn
		,	cc.Narrative
		,	cc.MCCDesc
		,	cc.LocationCountry
		,	cc.BrandID
		,	cc.InClientList
		,	cc.OnGAS
		,	cc.OnGASOnTheCorrectPartnerRecord
		,	SUM(ct.Amount) AS SpendInLastYear
		,	SUM(CASE WHEN ct.IsOnline = 1 THEN ct.Amount END) AS OnlineSpendInLastYear
		,	MIN(ct.FirstTran) AS FirstTran
		,	MAX(ct.LastTran) AS LastTran
	INTO #CT
	FROM #CC cc
	INNER JOIN #CT_Temp ct
		ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
	GROUP BY	cc.MerchantID_Provided
			,	cc.MerchantID_MatchedOn
			,	cc.Narrative
			,	cc.MCCDesc
			,	cc.LocationCountry
			,	cc.BrandID
			,	cc.InClientList
			,	cc.OnGAS
			,	cc.OnGASOnTheCorrectPartnerRecord
	
	IF OBJECT_ID('tempdb..#CTC_Temp') IS NOT NULL DROP TABLE #CTC_Temp;
	SELECT	ct.ConsumerCombinationID
		,	ct.IsOnline
		,	MIN(ct.TranDate) AS FirstTran
		,	MAX(ct.TranDate) AS LastTran
		,	SUM(ct.Amount) AS Amount
	INTO #CTC_Temp
	FROM [Relational].[ConsumerTransaction_CreditCard] ct
	WHERE @LastYear < ct.TranDate
	AND EXISTS (SELECT 1
				FROM #CC cc
				WHERE cc.ConsumerCombinationID = ct.ConsumerCombinationID)
	GROUP BY	ct.ConsumerCombinationID
			,	ct.IsOnline

	CREATE CLUSTERED INDEX CIX_CID ON #CTC_Temp (ConsumerCombinationID)
		
	IF OBJECT_ID('tempdb..#CTC') IS NOT NULL DROP TABLE #CTC;
	SELECT	cc.MerchantID_Provided
		,	cc.MerchantID_MatchedOn
		,	cc.Narrative
		,	cc.MCCDesc
		,	cc.LocationCountry
		,	cc.BrandID
		,	cc.InClientList
		,	cc.OnGAS
		,	cc.OnGASOnTheCorrectPartnerRecord
		,	SUM(ct.Amount) AS SpendInLastYear
		,	SUM(CASE WHEN ct.IsOnline = 1 THEN ct.Amount END) AS OnlineSpendInLastYear
		,	MIN(ct.FirstTran) AS FirstTran
		,	MAX(ct.LastTran) AS LastTran
	INTO #CTC
	FROM #CC cc
	INNER JOIN #CTC_Temp ct
		ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
	GROUP BY	cc.MerchantID_Provided
			,	cc.MerchantID_MatchedOn
			,	cc.Narrative
			,	cc.MCCDesc
			,	cc.LocationCountry
			,	cc.BrandID
			,	cc.InClientList
			,	cc.OnGAS
			,	cc.OnGASOnTheCorrectPartnerRecord
	
	IF OBJECT_ID('tempdb..#CT_All') IS NOT NULL DROP TABLE #CT_All
	SELECT	ct.MerchantID_Provided
		,	ct.MerchantID_MatchedOn
		,	ct.Narrative
		,	ct.MCCDesc
		,	ct.LocationCountry
		,	ct.BrandID
		,	ct.InClientList
		,	ct.OnGAS
		,	ct.OnGASOnTheCorrectPartnerRecord
		,	SUM(ct.SpendInLastYear) AS SpendInLastYear
		,	SUM(ct.OnlineSpendInLastYear) AS OnlineSpendInLastYear
		,	MIN(ct.FirstTran) AS FirstTran
		,	MAX(CT.LastTran) AS LastTran
	INTO #CT_All
	FROM (SELECT * FROM #CT UNION ALL SELECT * FROM #CTC) ct
	GROUP BY	ct.MerchantID_Provided
			,	ct.MerchantID_MatchedOn
			,	ct.Narrative
			,	ct.MCCDesc
			,	ct.LocationCountry
			,	ct.BrandID
			,	ct.InClientList
			,	ct.OnGAS
			,	ct.OnGASOnTheCorrectPartnerRecord

	UPDATE #CT_All
	SET OnlineSpendInLastYear = SpendInLastYear
	WHERE SpendInLastYear < OnlineSpendInLastYear


/*******************************************************************************************************************************************
	7.	Add transaction details to the combined MID list
*******************************************************************************************************************************************/
	
	IF OBJECT_ID('tempdb..#CombinedMIDs_CT') IS NOT NULL DROP TABLE #CombinedMIDs_CT
	SELECT	COALESCE(ct.BrandID, cm.BrandID) AS BrandID
		,	br.BrandName
		,	cm.PartnerID
		,	cm.PartnerName
		,	COALESCE(cm.MerchantID, ct.MerchantID_Provided) AS MerchantID
		,	ct.MerchantID_MatchedOn
		,	cm.Address1
		,	cm.Address2
		,	cm.City
		,	cm.Postcode
		,	cm.County
		,	cm.Telephone
		,	cm.PartnerOutletReference
		,	cm.Channel
		,	ct.Narrative
		,	ct.MCCDesc
		,	ct.LocationCountry
		,	ct.SpendInLastYear
		,	ct.OnlineSpendInLastYear
		,	ct.FirstTran
		,	ct.LastTran
		
		,	COALESCE(CurrentAddressDetailsCorrect, 0) AS CurrentAddressDetailsCorrect
		,	COALESCE(cm.InClientList, ct.InClientList) AS InClientList
		,	COALESCE(cm.OnGAS, ct.OnGAS) AS OnGAS
		,	COALESCE(cm.OnGASOnTheCorrectPartnerRecord, ct.OnGASOnTheCorrectPartnerRecord) AS OnGASOnTheCorrectPartnerRecord
	INTO #CombinedMIDs_CT
	FROM #CombinedMIDs cm
	FULL OUTER JOIN #CT_All ct
		ON cm.MerchantID = ct.MerchantID_Provided
	LEFT JOIN [Relational].[Brand] br
		ON COALESCE(ct.BrandID, cm.BrandID) = br.BrandID
	ORDER BY	CASE
					WHEN LEN(cm.PartnerName) > 0 THEN 0
					ELSE 1
				END
			,	cm.PartnerName
			,	COALESCE(cm.MerchantID, ct.MerchantID_Provided)
			,	ct.LastTran


/*******************************************************************************************************************************************
	8.	Use credit card data to infer postcode where one is missing
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#SharedMIDs') IS NOT NULL DROP TABLE #SharedMIDs
	SELECT	DISTINCT
			MID
	INTO #SharedMIDs
	FROM [Relational].[ConsumerCombination] cc
	WHERE EXISTS (	SELECT 1
					FROM #CombinedMIDs_CT mi
					WHERE cc.MID = mi.MerchantID_MatchedOn)
	AND (Narrative LIKE '%SUMUP%'
	OR Narrative LIKE 'CRV%'
	OR Narrative LIKE 'iz%'
	OR Narrative LIKE 'SQ*%'
	OR Narrative LIKE 'SQ *%'
	OR Narrative LIKE 'PP%'
	OR Narrative LIKE 'PayPal%')

	CREATE CLUSTERED INDEX CIX_MerchantID ON #SharedMIDs (MID)

	IF OBJECT_ID('tempdb..#MIDs') IS NOT NULL DROP TABLE #MIDs
	SELECT DISTINCT
		   MerchantID
	INTO #MIDs
	FROM #CombinedMIDs_CT cm
	WHERE (LEN(cm.Postcode) < 3 OR cm.Postcode IS NULL)
	AND NOT EXISTS (SELECT 1
					FROM #SharedMIDs sm
					WHERE cm.MerchantID_MatchedOn = sm.MID)

	CREATE CLUSTERED INDEX CIX_MerchantID ON #MIDs (MerchantID)

	DECLARE @LastYear_Credit DATE = DATEADD(YEAR, -1, GETDATE())
	
	IF OBJECT_ID('tempdb..#CreditDataFileIDs') IS NOT NULL DROP TABLE #CreditDataFileIDs
	SELECT	nf.ID
	INTO #CreditDataFileIDs
	FROM [SLC_REPL].[dbo].[NobleFiles] nf
	WHERE nf.InDate > @LastYear_Credit
	AND nf.FileType = 'CRTRN'

	CREATE CLUSTERED INDEX CIX_ID ON #CreditDataFileIDs (ID)

	IF OBJECT_ID('tempdb..#CreditDataRaw') IS NOT NULL DROP TABLE #CreditDataRaw
	SELECT	th.MerchantID
		,	th.MerchantZip
		,	MAX(th.TranDate) AS TranDate
	INTO #CreditDataRaw
	FROM [Archive_Light].[dbo].[CBP_Credit_TransactionHistory] th
	WHERE ISDATE(TranDate) = 1
	AND EXISTS (	SELECT 1
					FROM #MIDs mi
					WHERE th.MerchantID = mi.MerchantID)
	AND EXISTS (	SELECT 1
					FROM #CreditDataFileIDs cdf
					WHERE th.FileID = cdf.ID)
	GROUP BY	th.MerchantID
			,	th.MerchantZip

	CREATE CLUSTERED INDEX CIX_MerchantZip ON #CreditDataRaw (MerchantZip)

	IF OBJECT_ID('tempdb..#CreditData') IS NOT NULL DROP TABLE #CreditData
	SELECT	MerchantID
		,	COALESCE(pc.Postcode, LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(MerchantZip, '  ', '<>'), '><', ''), '<>', ' ')))) AS Postcode
		,	MAX(TranDate) AS MaxTranDate
	INTO #CreditData
	FROM #CreditDataRaw cd
	LEFT JOIN [Relational].[PostCode] pc
		ON REPLACE(cd.MerchantZip, ' ', '') = REPLACE(pc.Postcode, ' ', '')
	GROUP BY	MerchantID
			,	COALESCE(pc.Postcode, LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(MerchantZip, '  ', '<>'), '><', ''), '<>', ' '))))

	CREATE CLUSTERED INDEX CIX_MerchantZip ON #CreditData (Postcode)

	IF OBJECT_ID('tempdb..#CreditDataMax') IS NOT NULL DROP TABLE #CreditDataMax;
	WITH
	CreditData AS (	SELECT	MerchantID
						,	Postcode
						,	MaxTranDate
						,	MAX(MaxTranDate) OVER (PARTITION BY MerchantID) AS MaxTranDatePerMID
					FROM #CreditData cd)
	
	SELECT MerchantID
		 , Postcode
	INTO #CreditDataMax
	FROM CreditData cd
	WHERE MaxTranDate = MaxTranDatePerMID

	CREATE CLUSTERED INDEX CIX_MID ON #CreditDataMax (MerchantID)

	UPDATE cm
	SET cm.Postcode = cdm.Postcode
	FROM #CombinedMIDs_CT cm
	INNER JOIN #CreditDataMax cdm
		ON cm.MerchantID_MatchedOn = cdm.MerchantID


/*******************************************************************************************************************************************
	9. Update City & County data where missing
*******************************************************************************************************************************************/

	UPDATE cm
	SET cm.City = CASE WHEN cm.CurrentAddressDetailsCorrect = 1 THEN COALESCE(cm.City, pcd.Town) ELSE COALESCE(pcd.Town, cm.City) END
	,	cm.County = CASE WHEN cm.CurrentAddressDetailsCorrect = 1 THEN COALESCE(cm.County, pcd.County) ELSE COALESCE(pcd.County, cm.County) END
	FROM #CombinedMIDs_CT cm
	INNER JOIN [Relational].[PostCode] pc
		ON REPLACE(cm.Postcode, ' ', '') = REPLACE(pc.Postcode, ' ', '')
	INNER JOIN [Relational].[PostcodeDistrict] pcd
		ON pc.PostOuter = pcd.PostCodeDistrict


/*******************************************************************************************************************************************
	10.	Output
*******************************************************************************************************************************************/

	SELECT	cm.BrandID
		,	cm.BrandName
		,	cm.PartnerID
		,	cm.PartnerName
		,	cm.MerchantID
		,	cm.Address1
		,	cm.Address2
		,	cm.City
		,	cm.Postcode
		,	cm.County
		,	cm.Telephone
		,	cm.PartnerOutletReference
		,	cm.Channel
		,	cm.MerchantID_MatchedOn
		,	cm.Narrative
		,	cm.MCCDesc
		,	cm.LocationCountry
		,	cm.SpendInLastYear
		,	cm.OnlineSpendInLastYear
		,	cm.FirstTran
		,	cm.LastTran
		
		,	cm.InClientList
		,	cm.OnGAS
		,	cm.OnGASOnTheCorrectPartnerRecord
	FROM #CombinedMIDs_CT cm

	END

