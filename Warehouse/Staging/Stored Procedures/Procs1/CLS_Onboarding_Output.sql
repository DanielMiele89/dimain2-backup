/*

	Author:		Rory Francis

	Date:		2019-10-24

	Purpose:	To produce a list of MerchantIDs to be provided to CLS

*/


CREATE PROCEDURE [Staging].[CLS_Onboarding_Output] (@PartnerName VARCHAR(50))
AS
	BEGIN
		---------------------------------------------------------------------------------------------------
		--------------------------Set Internal Parameter = to Partner ID-----------------------------------
		---------------------------------------------------------------------------------------------------

		--	DECLARE @PartnerName VARCHAR(50) = 'Sainsburys'

		DECLARE @PName VARCHAR(50) = @PartnerName
		DECLARE @PartnerID INT = (SELECT DISTINCT PrimaryPartnerID FROM [Staging].[CLS_Onboarding_MIDsToSend] WHERE PrimaryPartnerName = @PName)

		---------------------------------------------------------------------------------------------------
		--------------------------------Produce table of MID entries---------------------------------------
		---------------------------------------------------------------------------------------------------

		IF OBJECT_ID('tempdb..#DataToBeOutput') IS NOT NULL DROP TABLE #DataToBeOutput
		SELECT DISTINCT
			   '20' AS RecordType
			 , 'REWARD INSIGHT' AS ProjectName
			 , 'A' AS ActionCode
			 , CONVERT(VARCHAR, ro.ID) AS SiteID
			 , '' AS Comments
			 , '' AS MC_Location
			 , '' AS MC_LastSeenDate

			 , REPLACE(COALESCE(pa.Name, /*gk.PubName,*/ ro.PartnerOutletReference, pa.Name),'|','') AS MerchantDBAName

			 , '' AS MC_MerchantDBAName
			 , pa.RegisteredName AS MerchantLegalName
			 , CASE
					WHEN LEN(REPLACE(fa.Address1, '|', '')) > 0 AND LEN(REPLACE(fa.Address2, '|', '')) = 0 THEN REPLACE(fa.Address1, '|', '')
					WHEN LEN(REPLACE(fa.Address1, '|', '')) = 0 AND LEN(REPLACE(fa.Address2, '|', '')) > 0 THEN REPLACE(fa.Address2, '|', '')
					WHEN LEN(REPLACE(fa.Address1, '|', '')) = 0 AND LEN(REPLACE(fa.Address2, '|', '')) = 0 THEN ''
					ELSE REPLACE(fa.Address1, '|', '') + ', ' + REPLACE(fa.Address2, '|', '')
			   END AS MerchantAddress
			 , '' AS MC_MerchantAddress
			 , REPLACE(fa.City,'|','') AS MerchantCity
			 , '' AS MC_MerchantCity
			 , REPLACE(fa.County,'|','') AS MerchantState
			 , '' AS MC_MerchantState
			 , REPLACE(fa.Postcode,'|','') AS MerchantPostalCode
			 , '' AS MC_MerchantPostalCode
			 , 'GBR' AS MerchantCountry
			 , '' AS MC_MerchantCountry
			 , '' AS MerchantPhoneNumber
			 , '' AS MerchantChainID
			 , LTRIM(RTRIM(ro.MerchantID)) AS AcquiringMerchantID
			 , '' AS MC_ClearingAcquiringMerchantID
			 , '' AS MC_ClearingAcquirerICA
			 , '' AS MC_AuthacquiringMerchantID
			 , '' AS MC_AuthacquirerICA
			 , '' AS MC_MCC
			 , '' AS IndustryDescription
			 , CONVERT(VARCHAR(10), DATEADD(day, -1, GETDATE()), 101) AS EffectiveDate
			 , '' AS EndDate
			 , '' AS DiscountRate
			 , '' AS MerchantURL
			 , '' AS PassThru1
			 , '' AS PassThru2
			 , '' AS PassThru3
			 , '' AS PassThru4
			 , '' AS PassThru5
			 , CONVERT(VARCHAR(10), GETDATE(), 101) AS FileDate
		INTO #DataToBeOutput
		FROM [SLC_REPL].[dbo].[RetailOutlet] ro
		INNER JOIN [SLC_REPL].[dbo].[Fan] fa
			ON ro.FanID = fa.ID
		INNER JOIN [SLC_REPL].[dbo].[Partner] pa
			ON ro.PartnerID = pa.ID
		INNER JOIN [Staging].[CLS_Onboarding_MIDsToSend] mts
			ON ro.ID = mts.RetailOutletID
		WHERE pa.ID = @PartnerID

		CREATE CLUSTERED INDEX CIX_DataToBeOutput_PostcodeMID ON #DataToBeOutput (MerchantPostalCode, MC_AuthacquiringMerchantID)

		---------------------------------------------------------------------------------------------------
		-----------------------------Produce final data including header and footer------------------------
		---------------------------------------------------------------------------------------------------

		INSERT INTO [nFI].[Staging].[CLS_FilesSent]
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
			 , REPLACE(CONVERT(DATE, EffectiveDate), '1900-01-01', '') AS EffectiveDate
			 , REPLACE(CONVERT(DATE, EndDate), '1900-01-01', '') AS EndDate
			 , DiscountRate
			 , MerchantURL
			 , PassThru1
			 , PassThru2
			 , PassThru3
			 , PassThru4
			 , PassThru5
			 , REPLACE(CONVERT(DATE, FileDate), '1900-01-01', '') AS FileDate
			 , 0 AS Reviewed
		FROM #DataToBeOutput dto
		WHERE NOT EXISTS (	SELECT 1
							FROM [nFI].[Staging].[CLS_FilesSent] cls
							WHERE dto.SiteID = cls.SiteID
							AND REPLACE(CONVERT(DATE, dto.FileDate), '1900-01-01', '') = cls.FileDate
							AND REPLACE(CONVERT(DATE, dto.EffectiveDate), '1900-01-01', '') = cls.EffectiveDate)


		DECLARE @Rows VARCHAR(100) = CONVERT(VARCHAR(100), (Select COUNT(*) From #DataToBeOutput))
			  , @HeaderDateTime VARCHAR(100) = REPLACE(CONVERT(VARCHAR(8), GETDATE(), 112) + CONVERT(VARCHAR(8), GETDATE(), 114), ':','')

		TRUNCATE TABLE [Staging].[CLS_Onboarding_NewFile]
		INSERT INTO [Staging].[CLS_Onboarding_NewFile]
		SELECT '10|' + @HeaderDateTime + '|REWARD INSIGHT' AS OutputForCLS

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
		 + '|' + EffectiveDate
		 + '|' + EndDate
		 + '|' + DiscountRate
		 + '|' + MerchantURL
		 + '|' + PassThru1
		 + '|' + PassThru2
		 + '|' + PassThru3
		 + '|' + PassThru4
		 + '|' + PassThru5
		 + '|' + FileDate
		FROM #DataToBeOutput

		UNION ALL

		SELECT '30|REWARD INSIGHT|' + @Rows

	END