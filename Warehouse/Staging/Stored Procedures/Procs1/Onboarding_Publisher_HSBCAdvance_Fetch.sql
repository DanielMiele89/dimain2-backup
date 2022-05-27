/*

	Author:		Stuart Barnley

	Date:		10th October 2016

	Purpose:	To produce a list of MerchantIDs to be provided to CLS

*/

CREATE PROCEDURE [Staging].[Onboarding_Publisher_HSBCAdvance_Fetch] (@PartnerID INT
																  , @FileName VARCHAR(100))

AS
	BEGIN
	
	--DECLARE @PartnerID INT = 4793
	--	,	@FileName VARCHAR(100) = 'test'


	DECLARE @FileDate VARCHAR(10) = CONVERT(VARCHAR(10), GETDATE(), 101)

	/***************************************************************************************************************************************
		1. Add any alternate partner records that may exist
	***************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#PartnerIDs') IS NOT NULL DROP TABLE #PartnerIDs
		SELECT CONVERT(INT, pa.ID) AS ID
			 , pa.Name
			 , pa.RegisteredName
		INTO #PartnerIDs
		FROM [SLC_REPL].[dbo].[Partner] pa
		WHERE pa.ID IN (@PartnerID)

		INSERT INTO #PartnerIDs
		SELECT CONVERT(INT, pa.ID) AS ID
			 , pa.Name
			 , pa.RegisteredName
		FROM #PartnerIDs p
		INNER JOIN [iron].[PrimaryRetailerIdentification] pri
			ON p.ID = COALESCE(pri.PrimaryPartnerID, pri.PartnerID)
		INNER JOIN [SLC_REPL].[dbo].[Partner] pa
			ON pri.PartnerID = pa.ID
		WHERE pa.[Name] NOT LIKE '%amex%'
		AND pa.[Name] NOT LIKE '%archive%'
		AND pa.ID != p.ID
		AND EXISTS (	SELECT 1
						FROM [SLC_REPL].[dbo].[RetailOutlet] ro
						WHERE pa.ID = ro.PartnerID
						AND ro.MerchantID != ''
						AND LEFT(ro.MerchantID, 1) != '#')
		AND NOT EXISTS (SELECT 1
						FROM #PartnerIDs pe
						WHERE pa.ID = pe.ID)

		INSERT INTO #PartnerIDs
		SELECT CONVERT(INT, pa.ID) AS ID
			 , pa.Name
			 , pa.RegisteredName
		FROM #PartnerIDs p
		INNER JOIN [iron].[PrimaryRetailerIdentification] pri
			ON p.ID = COALESCE(pri.PartnerID, pri.PrimaryPartnerID)
		INNER JOIN [SLC_REPL].[dbo].[Partner] pa
			ON pri.PrimaryPartnerID = pa.ID
		WHERE pa.[Name] NOT LIKE '%amex%'
		AND pa.[Name] NOT LIKE '%archive%'
		AND pa.ID != p.ID
		AND EXISTS (	SELECT 1
						FROM [SLC_REPL].[dbo].[RetailOutlet] ro
						WHERE pa.ID = ro.PartnerID
						AND ro.MerchantID != ''
						AND LEFT(ro.MerchantID, 1) != '#')
		AND NOT EXISTS (SELECT 1
						FROM #PartnerIDs pe
						WHERE pa.ID = pe.ID)


	/***************************************************************************************************************************************
		2. Produce the table of MID entires to send with pipe delimiters removed
	***************************************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#MIDsToSend') IS NOT NULL DROP TABLE #MIDsToSend
		SELECT DISTINCT
			   CONVERT(VARCHAR, ro.ID) AS SiteID
			 , REPLACE(pa.Name, '|', '') AS PartnerName
			 , REPLACE(ro.PartnerOutletReference, '|', '') AS PartnerOutletReference
			 , REPLACE(pa.RegisteredName, '|', '') AS RegisteredName
			 , REPLACE(fa.Address1, '|', '') AS Address1
			 , REPLACE(fa.Address2, '|', '') AS Address2
			 , REPLACE(fa.City,'|','') AS City
			 , REPLACE(fa.County,'|','') AS County
			 , REPLACE(fa.Postcode,'|','') AS Postcode
			 , CASE
					WHEN ro.MerchantID IN ('2100399337', '2100399338', '336707216', '328374898', '526567002351232', '498750002475656') THEN 'DE'
					WHEN cc.LocationCountry = 'GB' THEN 'GBR'
					WHEN cc.LocationCountry = 'IR' THEN 'IRE'
					WHEN cc.LocationCountry IS NOT NULL THEN LocationCountry
					ELSE 'GBR'
			   END AS MerchantCountry
			 , REPLACE(fa.Telephone,'|','') AS Telephone
			 , LTRIM(RTRIM(ro.MerchantID)) AS MerchantID
			 , CONVERT(VARCHAR(10), DATEADD(day, -1, GETDATE()), 101) AS EffectiveDate
			 , CONVERT(VARCHAR(10), pa.ID) AS PassThru1
			 , CONVERT(VARCHAR(10), ro.ID) AS PassThru2
			 , @FileDate AS FileDate
		INTO #MIDsToSend
		FROM [SLC_REPL].[dbo].[RetailOutlet] ro
		INNER JOIN [SLC_REPL].[dbo].[Fan] fa
			ON ro.FanID = fa.ID
		INNER JOIN [SLC_REPL].[dbo].[Partner] pa
			ON ro.PartnerID = pa.ID
		LEFT JOIN [Relational].[ConsumerCombination] cc
			ON ro.MerchantID = cc.MID
		WHERE ro.MerchantID != ''
		AND LEFT(ro.MerchantID, 1) != '#'
		AND EXISTS (SELECT 1
					FROM #PartnerIDs p
					WHERE pa.ID = p.ID)


	/***************************************************************************************************************************************
		3. Add in additional fields that are required
	***************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#Output') IS NOT NULL DROP TABLE #Output
		SELECT DISTINCT
			   '20' AS RecordType
			 , 'REWARD INSIGHT HSBC' AS ProjectName
			 , 'A' AS ActionCode
			 , mts.SiteID
			 , '' AS Comments
			 , '' AS MC_Location
			 , '' AS MC_LastSeenDate
			 , COALESCE(mts.PartnerName, mts.PartnerOutletReference) AS MerchantDBAName
			 , '' AS MC_MerchantDBAName
			 , mts.RegisteredName AS MerchantLegalName
			,	CASE
					WHEN LEN(mts.Address1) > 0 AND LEN(mts.Address2) = 0 THEN CONVERT(VARCHAR(500), mts.Address1)
					WHEN LEN(mts.Address1) = 0 AND LEN(mts.Address2) > 0 THEN CONVERT(VARCHAR(500), mts.Address2)
					WHEN LEN(mts.Address1) = 0 AND LEN(mts.Address2) = 0 THEN CONVERT(VARCHAR(500), '')
					ELSE CONVERT(VARCHAR(500), mts.Address1 + ', ' + mts.Address2)
				END AS MerchantAddress
			 , '' AS MC_MerchantAddress
			 , mts.City AS MerchantCity
			 , '' AS MC_MerchantCity
			 , mts.County AS MerchantState
			 , '' AS MC_MerchantState
			 , mts.Postcode AS MerchantPostalCode
			 , '' AS MC_MerchantPostalCode
			 , mts.MerchantCountry
			 , '' AS MC_MerchantCountry
			 , mts.Telephone AS MerchantPhoneNumber
			 , '' AS MerchantChainID
			 , mts.MerchantID AS AcquiringMerchantID
			 , '' AS MC_ClearingAcquiringMerchantID
			 , '' AS MC_ClearingAcquirerICA
			 , '' AS MC_AuthacquiringMerchantID
			 , '' AS MC_AuthacquirerICA
			 , '' AS MC_MCC
			 , '' AS IndustryDescription
			 , mts.EffectiveDate
			 , '' AS EndDate
			 , '' AS DiscountRate
			 , '' AS MerchantURL
			 , mts.PassThru1
			 , mts.PassThru2
			 , '' AS PassThru3
			 , '' AS PassThru4
			 , '' AS PassThru5
			 , mts.FileDate
		INTO #Output
		FROM #MIDsToSend mts


	/***************************************************************************************************************************************
		4. Insert to logging table
	***************************************************************************************************************************************/

		DELETE sf
		FROM [Staging].[Onboarding_Publisher_HSBCAdvance_SubmittedFiles] sf
		WHERE sf.FileDate = REPLACE(CONVERT(DATE, @FileDate), '1900-01-01', '')
		AND EXISTS (SELECT 1
					FROM #PartnerIDs pa
					WHERE sf.PassThru1 = pa.ID)


		INSERT INTO [Staging].[Onboarding_Publisher_HSBCAdvance_SubmittedFiles] (RecordType
																			   , ProjectName
																			   , ActionCode
																			   , SiteID
																			   , Comments
																			   , MC_Location
																			   , MC_LastSeenDate
																			   , MerchantDBAName
																			   , MC_MerchantDBAName
																			   , MerchantLegalName
																			   , MerchantAddress
																			   , MC_MerchantAddress
																			   , MerchantCity
																			   , MC_MerchantCity
																			   , MerchantState
																			   , MC_MerchantState
																			   , MerchantPostalCode
																			   , MC_MerchantPostalCode
																			   , MerchantCountry
																			   , MC_MerchantCountry
																			   , MerchantPhoneNumber
																			   , MerchantChainID
																			   , AcquiringMerchantID
																			   , MC_ClearingAcquiringMerchantID
																			   , MC_ClearingAcquirerICA
																			   , MC_AuthacquiringMerchantID
																			   , MC_AuthacquirerICA
																			   , MC_MCC
																			   , IndustryDescription
																			   , EffectiveDate
																			   , EndDate
																			   , DiscountRate
																			   , MerchantURL
																			   , PassThru1
																			   , PassThru2
																			   , PassThru3
																			   , PassThru4
																			   , PassThru5
																			   , FileDate
																			   , FileName
																			   , Reviewed)
		SELECT RecordType
			 , ProjectName
			 , ActionCode
			 , SiteID
			 , Comments
			 , MC_Location
			 , MC_LastSeenDate
			 , MerchantDBAName
			 , MC_MerchantDBAName
			 , MerchantLegalName
			 , MerchantAddress
			 , MC_MerchantAddress
			 , MerchantCity
			 , MC_MerchantCity
			 , MerchantState
			 , MC_MerchantState
			 , MerchantPostalCode
			 , MC_MerchantPostalCode
			 , MerchantCountry
			 , MC_MerchantCountry
			 , MerchantPhoneNumber
			 , MerchantChainID
			 , AcquiringMerchantID
			 , MC_ClearingAcquiringMerchantID
			 , MC_ClearingAcquirerICA
			 , MC_AuthacquiringMerchantID
			 , MC_AuthacquirerICA
			 , MC_MCC
			 , IndustryDescription
			 , REPLACE(EffectiveDate, '1900-01-01', '') AS EffectiveDate
			 , REPLACE(EndDate, '1900-01-01', '') AS EndDate
			 , DiscountRate
			 , MerchantURL
			 , PassThru1
			 , PassThru2
			 , PassThru3
			 , PassThru4
			 , PassThru5
			 , REPLACE(FileDate, '1900-01-01', '') AS FileDate
			 , @FileName
			 , 0 AS Reviewed
		FROM #Output o



		SELECT '10|' + REPLACE(CONVERT(VARCHAR(8), GETDATE(), 112) + CONVERT(VARCHAR(8), GETDATE(), 114), ':','') + '|REWARD INSIGHT' AS OutputForCLS

		UNION ALL

		SELECT   RecordType
		 + '|' + ProjectName
		 + '|' + ActionCode
		 + '|' + SiteID
		 + '|' + Comments
		 + '|' + MC_Location
		 + '|' + MC_LastSeenDate
		 + '|' + MerchantDBAName
		 + '|' + MC_MerchantDBAName
		 + '|' + MerchantLegalName
		 + '|' + MerchantAddress
		 + '|' + MC_MerchantAddress
		 + '|' + MerchantCity
		 + '|' + MC_MerchantCity
		 + '|' + MerchantState
		 + '|' + MC_MerchantState
		 + '|' + MerchantPostalCode
		 + '|' + MC_MerchantPostalCode
		 + '|' + MerchantCountry
		 + '|' + MC_MerchantCountry
		 + '|' + MerchantPhoneNumber
		 + '|' + MerchantChainID
		 + '|' + AcquiringMerchantID
		 + '|' + MC_ClearingAcquiringMerchantID
		 + '|' + MC_ClearingAcquirerICA
		 + '|' + MC_AuthacquiringMerchantID
		 + '|' + MC_AuthacquirerICA
		 + '|' + MC_MCC
		 + '|' + IndustryDescription
		 + '|' + REPLACE(EffectiveDate, '01/01/1900', '')
		 + '|' + REPLACE(EndDate, '01/01/1900', '')
		 + '|' + DiscountRate
		 + '|' + MerchantURL
		 + '|' + PassThru1
		 + '|' + PassThru2
		 + '|' + PassThru3
		 + '|' + PassThru4
		 + '|' + PassThru5
		 + '|' + REPLACE(FileDate, '01/01/1900', '')
		FROM #Output

		UNION ALL

		SELECT '30|REWARD INSIGHT|' + CONVERT(VARCHAR(100), (Select COUNT(*) From #Output))

	END