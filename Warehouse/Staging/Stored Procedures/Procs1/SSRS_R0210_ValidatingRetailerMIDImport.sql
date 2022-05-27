
CREATE PROCEDURE [Staging].[SSRS_R0210_ValidatingRetailerMIDImport] (@IsRetailerAMEX VARCHAR(3)
																  , @PartnerID NVARCHAR(MAX))
AS
	BEGIN
	
/*******************************************************************************************************************************************
	1. Declare Variables
*******************************************************************************************************************************************/

		--DECLARE @IsRetailerAMEX VARCHAR(3) = 'Yes'
		--	  , @PartnerID NVARCHAR(MAX))

		DECLARE @PID NVARCHAR(MAX) = REPLACE(@PartnerID, ' ', '')

		
/*******************************************************************************************************************************************
	2. Split multiple PartnerIDs
*******************************************************************************************************************************************/
			  
		IF OBJECT_ID ('tempdb..#PartnerIDsSplit') IS NOT NULL DROP TABLE #PartnerIDsSplit;
		SELECT p.Item AS PartnerID
			 , pa.Name
			 , pa.RegisteredName
			 , pa.MerchantAcquirer
		INTO #PartnerIDsSplit
		FROM [dbo].[il_SplitDelimitedStringArray] (@PID, ',') p
		INNER JOIN [SLC_REPL].[dbo].[Partner] pa
			ON p.Item = pa.ID

		
/*******************************************************************************************************************************************
	3. Fetch all connected partners including Alternate Partner records
*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#PartnerIDs') IS NOT NULL DROP TABLE #PartnerIDs
		SELECT CONVERT(INT, pa.ID) AS PartnerID
			 , pa.Name AS PartnerName
			 , pa.RegisteredName
		INTO #PartnerIDs
		FROM [SLC_REPL].[dbo].[Partner] pa
		WHERE EXISTS (	SELECT 1
						FROM #PartnerIDsSplit pis
						WHERE pa.ID = pis.PartnerID)

		INSERT INTO #PartnerIDs
		SELECT CONVERT(INT, pa.ID) AS PartnerID
			 , pa.Name AS PartnerName
			 , pa.RegisteredName
		FROM #PartnerIDs p
		INNER JOIN [iron].[PrimaryRetailerIdentification] pri
			ON p.PartnerID = COALESCE(pri.PrimaryPartnerID, pri.PartnerID)
		INNER JOIN [SLC_REPL].[dbo].[Partner] pa
			ON pri.PartnerID = pa.ID
		WHERE pa.[Name] NOT LIKE '%archive%'
		AND pa.ID != p.PartnerID
		AND NOT EXISTS (SELECT 1
						FROM #PartnerIDs pis
						WHERE pa.ID = pis.PartnerID)
			
		IF @IsRetailerAMEX = 'Yes' DELETE FROM #PartnerIDs WHERE PartnerName NOT LIKE '%AMEX%'
		IF @IsRetailerAMEX = 'No' DELETE FROM #PartnerIDs WHERE PartnerName LIKE '%AMEX%'


/*******************************************************************************************************************************************
	2. Fetch all MIDs from the retailers file
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#MIDValidation_Import') IS NOT NULL DROP TABLE #MIDValidation_Import
	SELECT MerchantID
		 , CASE WHEN Address1 = '' THEN NULL ELSE Address1 END AS Address1
		 , CASE WHEN Address2 = '' THEN NULL ELSE Address2 END AS Address2
		 , CASE WHEN City = '' THEN NULL ELSE City END AS City
		 , CASE WHEN Postcode = '' THEN NULL ELSE Postcode END AS Postcode
		 , CASE WHEN County = '' THEN NULL ELSE County END AS County
		 , CASE WHEN Telephone = '' THEN NULL ELSE Telephone END AS Telephone
		 , CASE WHEN PartnerOutletReference = '' THEN NULL ELSE PartnerOutletReference END AS PartnerOutletReference
		 , CASE WHEN Channel = '' THEN NULL ELSE Channel END AS Channel
	INTO #MIDValidation_Import
	FROM [Staging].[MIDValidation_Import]


/*******************************************************************************************************************************************
	3. Fetch all MIDs for the selected partner, currently or preivously incentivised
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#RetailOutlets') IS NOT NULL DROP TABLE #RetailOutlets
	SELECT pa.PartnerID
		 , pa.PartnerName
		 , ro.ID AS RetailOutletID
		 , REPLACE(ro.MerchantID, '#', '') AS MerchantID
		 , CASE WHEN fa.Address1 = '' THEN NULL ELSE fa.Address1 END AS Address1
		 , CASE WHEN fa.Address2 = '' THEN NULL ELSE fa.Address2 END AS Address2
		 , CASE WHEN fa.City = '' THEN NULL ELSE fa.City END AS City
		 , CASE WHEN fa.Postcode = '' THEN NULL ELSE fa.Postcode END AS Postcode
		 , CASE WHEN fa.County = '' THEN NULL ELSE fa.County END AS County
		 , CASE WHEN fa.Telephone = '' THEN NULL ELSE fa.Telephone END AS Telephone
		 , CASE WHEN ro.PartnerOutletReference = '' THEN NULL ELSE ro.PartnerOutletReference END AS PartnerOutletReference
		 , CASE
				WHEN ro.Channel = 0 THEN 'Unknown'
				WHEN ro.Channel = 1 THEN 'Online'
				WHEN ro.Channel = 2 THEN 'Offline'
		   END AS Channel
		 , MAX(CONVERT(DATE, COALESCE(mtg.StartDate, GETDATE()))) AS StartDate
		 , MAX(mtg.EndDate) AS EndDate
	INTO #RetailOutlets
	FROM [SLC_REPL].[dbo].[RetailOutlet] ro
	INNER JOIN #PartnerIDs pa
		ON ro.PartnerID = pa.PartnerID
	INNER JOIN [SLC_REPL].[dbo].[Fan] fa
		ON ro.FanID = fa.ID
	LEFT JOIN [Relational].[MIDTrackingGAS] mtg
		ON ro.ID = mtg.RetailOutletID
		AND mtg.EndDate IS NULL
	GROUP BY pa.PartnerID
		   , pa.PartnerName
		   , ro.ID
		   , ro.MerchantID
		   , fa.Address1
		   , fa.Address2
		   , fa.City
		   , fa.Postcode
		   , fa.County
		   , fa.Telephone
		   , ro.PartnerOutletReference
		   , ro.Channel

	INSERT INTO #RetailOutlets
	SELECT pa.ID AS PartnerID
		 , pa.Name AS PartnerName
		 , ro.ID AS RetailOutletID
		 , REPLACE(ro.MerchantID, '#', '') AS MerchantID
		 , CASE WHEN fa.Address1 = '' THEN NULL ELSE fa.Address1 END AS Address1
		 , CASE WHEN fa.Address2 = '' THEN NULL ELSE fa.Address2 END AS Address2
		 , CASE WHEN fa.City = '' THEN NULL ELSE fa.City END AS City
		 , CASE WHEN fa.Postcode = '' THEN NULL ELSE fa.Postcode END AS Postcode
		 , CASE WHEN fa.County = '' THEN NULL ELSE fa.County END AS County
		 , CASE WHEN fa.Telephone = '' THEN NULL ELSE fa.Telephone END AS Telephone
		 , CASE WHEN ro.PartnerOutletReference = '' THEN NULL ELSE ro.PartnerOutletReference END AS PartnerOutletReference
		 , ro.Channel
		 , MAX(CONVERT(DATE, COALESCE(mtg.StartDate, GETDATE()))) AS StartDate
		 , MAX(mtg.EndDate) AS EndDate
	FROM [SLC_REPL].[dbo].[RetailOutlet] ro
	INNER JOIN [SLC_REPL].[dbo].[Partner] pa
		ON ro.PartnerID = pa.ID
	INNER JOIN [SLC_REPL].[dbo].[Fan] fa
		ON ro.FanID = fa.ID
	LEFT JOIN [Relational].[MIDTrackingGAS] mtg
		ON ro.ID = mtg.RetailOutletID
		AND mtg.EndDate IS NULL
	WHERE NOT EXISTS (	SELECT 1
						FROM #RetailOutlets r
						WHERE ro.ID = r.RetailOutletID)
	AND EXISTS (SELECT 1
				FROM #MIDValidation_Import mv
				WHERE COALESCE(CONVERT(VARCHAR(500), TRY_CONVERT(INT, ro.MerchantID)), ro.MerchantID) = COALESCE(CONVERT(VARCHAR(500), TRY_CONVERT(INT, mv.MerchantID)), mv.MerchantID))
	GROUP BY pa.ID
		   , pa.Name
		   , ro.ID
		   , ro.MerchantID
		   , fa.Address1
		   , fa.Address2
		   , fa.City
		   , fa.Postcode
		   , fa.County
		   , fa.Telephone
		   , ro.PartnerOutletReference
		   , ro.Channel



/*******************************************************************************************************************************************
	4. Seperate MIDs for Credit Card Data postcode search
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#MIDs') IS NOT NULL DROP TABLE #MIDs
	SELECT DISTINCT
		   MerchantID
	INTO #MIDs
	FROM #RetailOutlets
	WHERE EndDate IS NULL
	UNION
	SELECT DISTINCT
		   MerchantID
	FROM #MIDValidation_Import

	CREATE CLUSTERED INDEX CIX_MerchantID ON #MIDs (MerchantID)

	IF OBJECT_ID('tempdb..#CreditDataRaw') IS NOT NULL DROP TABLE #CreditDataRaw
	SELECT th.MerchantID
		 , REPLACE(REPLACE(REPLACE(th.MerchantZip, ' ', '<>'), '><', ''), '<>', ' ') AS MerchantZip
		 , TranDate
		 , Amount
	INTO #CreditDataRaw
	FROM [Archive_Light].[dbo].[CBP_Credit_TransactionHistory] th
	WHERE ISDATE(TranDate) = 1
	AND EXISTS (SELECT 1
				FROM #MIDs mi
				WHERE mi.MerchantID = th.MerchantID)

	DECLARE @LastYear DATE = DATEADD(YEAR, -1, GETDATE())

	IF OBJECT_ID('tempdb..#CreditData') IS NOT NULL DROP TABLE #CreditData
	SELECT MerchantID
		 , MerchantZip
		 , SUM(CASE WHEN CONVERT(DATE, TranDate) > @LastYear THEN Amount ELSE 0 END) AS Transactions
		 , MAX(TranDate) AS MaxTranDate
	INTO #CreditData
	FROM #CreditDataRaw
	GROUP BY MerchantID
		   , MerchantZip
		   
	IF OBJECT_ID('tempdb..#CreditDataMax') IS NOT NULL DROP TABLE #CreditDataMax;
	WITH
	CreditData AS (	SELECT MerchantID
						 , MerchantZip
						 , Transactions
						 , MaxTranDate
						 , MAX(MaxTranDate) OVER (PARTITION BY REPLACE(cd.MerchantZip, ' ', '')) AS MaxTranDatePerMID
					FROM #CreditData cd
					WHERE EXISTS (	SELECT 1
									FROM Relational.PostCode pc
									WHERE REPLACE(cd.MerchantZip, ' ', '') = REPLACE(pc.Postcode, ' ', '')))
	
	SELECT MerchantID
		 , pc.Postcode
		 , pcd.Town
		 , pcd.County
	INTO #CreditDataMax
	FROM CreditData cd
	INNER JOIN Relational.PostCode pc
		ON REPLACE(cd.MerchantZip, ' ', '') = REPLACE(pc.Postcode, ' ', '')
	LEFT JOIN Relational.PostcodeDistrict pcd
		ON pc.PostOuter = pcd.PostCodeDistrict
	WHERE MaxTranDate = MaxTranDatePerMID
	
	IF OBJECT_ID('tempdb..#CombinedMIDList') IS NOT NULL DROP TABLE #CombinedMIDList;
	SELECT PartnerID
		 , PartnerName
		 , RetailOutletID
		 , COALESCE(ro.MerchantID, mr.MerchantID) AS MerchantID
		 , CASE
				WHEN ro.MerchantID IS NOT NULL AND ro.PartnerID NOT IN (SELECT PartnerID FROM #PartnerIDs) THEN 'MID On GAS assigned to another retailer'
				WHEN mr.MerchantID IS NOT NULL AND ro.EndDate IS NOT NULL THEN 'Previously On GAS And In File - To Be Checked'
				WHEN ro.MerchantID IS NULL AND mr.MerchantID IS NOT NULL THEN 'New MerchantID To Be Added To GAS'
				WHEN mr.MerchantID IS NULL AND ro.EndDate IS NULL THEN 'MerchantID To Be Removed From GAS'
				WHEN mr.MerchantID IS NULL AND ro.EndDate IS NOT NULL THEN 'Previously On GAS And Not In File'
				WHEN ro.StartDate IS NOT NULL THEN 'On GAS And In File'
		   END AS StatusOfMID
		 , COALESCE(ro.Address1, mr.Address1, '') AS Address1
		 , COALESCE(ro.Address2, mr.Address2, cd.Town, '') AS Address2
		 , COALESCE(ro.City, mr.City, '') AS City
		 , CASE
				WHEN ro.MerchantID IS NULL AND mr.Postcode IS NULL AND cd.Postcode IS NOT NULL THEN COALESCE(cd.Postcode, mr.Postcode, '')
				ELSE COALESCE(ro.Postcode, mr.Postcode, '')
		   END AS Postcode
		 , COALESCE(ro.County, mr.County, cd.County, '') AS County
		 , COALESCE(ro.Telephone, mr.Telephone, '') AS Telephone
		 , COALESCE(ro.PartnerOutletReference, mr.PartnerOutletReference, '') AS PartnerOutletReference
		 , COALESCE(ro.Channel, mr.Channel, '') AS Channel
		 , CASE
				WHEN ro.MerchantID IS NULL AND mr.Postcode = '' AND cd.Postcode IS NOT NULL THEN 'Check Postocde'
		   END AS PostcodeCodeStatus
	INTO #CombinedMIDList
	FROM #RetailOutlets ro
	FULL OUTER JOIN #MIDValidation_Import mr
		ON COALESCE(CONVERT(VARCHAR(500), TRY_CONVERT(INT, ro.MerchantID)), ro.MerchantID) = COALESCE(CONVERT(VARCHAR(500), TRY_CONVERT(INT, mr.MerchantID)), mr.MerchantID)
	LEFT JOIN #CreditDataMax cd
		ON cd.MerchantID = COALESCE(mr.MerchantID, ro.MerchantID)


	SELECT PartnerID
		 , PartnerName
		 , RetailOutletID
		 , MerchantID
		 , StatusOfMID
		 , Address1
		 , Address2
		 , City
		 , Postcode
		 , County
		 , Telephone
		 , PartnerOutletReference
		 , CASE
				WHEN Channel = '0' THEN 'Unknown'
				WHEN Channel = '1' THEN 'Online'
				WHEN Channel = '2' THEN 'In Store'
				ELSE Channel
		   END AS Channel
		 , PostcodeCodeStatus
	FROM #CombinedMIDList
	ORDER BY StatusOfMID
		   , COALESCE(CONVERT(VARCHAR(500), TRY_CONVERT(INT, MerchantID)), MerchantID)
		   , MerchantID


END