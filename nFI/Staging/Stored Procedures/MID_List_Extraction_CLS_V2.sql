/*

	Author:		Stuart Barnley

	Date:		10th October 2016

	Purpose:	To produce a list of MerchantIDs to be provided to CLS

*/


CREATE PROCEDURE [Staging].[MID_List_Extraction_CLS_V2] (@PartnerID INT
													  , @RunType BIT = 0)

AS

---------------------------------------------------------------------------------------------------
--------------------------Set Internal Parameter = to Partner ID-----------------------------------
---------------------------------------------------------------------------------------------------

DECLARE @PID INT = @PartnerID--4265

---------------------------------------------------------------------------------------------------
--------------------------------Produce table of MID entries---------------------------------------
---------------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#Output') IS NOT NULL DROP TABLE #Output
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
INTO #Output
FROM SLC_REPL..RetailOutlet ro
INNER JOIN SLC_REPL..Fan fa
	ON ro.FanID = fa.ID
INNER JOIN SLC_REPL..Partner pa
	ON ro.PartnerID = pa.ID
--LEFT JOIN Sandbox.Rory.GK_MIDs_PubName gk
--	ON ro.MerchantID = gk.MerchantID
WHERE pa.ID = @PID
AND LEFT(LTRIM(ro.MerchantID), 1) NOT IN ('x', '#', 'A')



IF OBJECT_ID('tempdb..#DataToBeOutput') IS NOT NULL DROP TABLE #DataToBeOutput
SELECT *
INTO #DataToBeOutput
FROM #Output o1
WHERE NOT EXISTS (SELECT 1
				  FROM #Output o2
				  WHERE (o1.AcquiringMerchantID LIKE '%' + o2.AcquiringMerchantID + '%' OR o2.AcquiringMerchantID LIKE '%' + o1.AcquiringMerchantID + '%')
				  AND (
						(LEN(o1.AcquiringMerchantID) > LEN(o2.AcquiringMerchantID) AND LEN(o1.AcquiringMerchantID) <= 8) OR
						(LEN(o1.AcquiringMerchantID) < LEN(o2.AcquiringMerchantID) AND LEN(o2.AcquiringMerchantID) > 9)
						)
				  )


---------------------------------------------------------------------------------------------------
-----------------------------Produce final data including header and footer------------------------
---------------------------------------------------------------------------------------------------

SELECT *
FROM #DataToBeOutput

IF @RunType = 1
	BEGIN
		INSERT INTO Staging.CLS_FilesSent
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
		FROM #DataToBeOutput


		DECLARE @Rows VARCHAR(100) = CONVERT(VARCHAR(100), (Select COUNT(*) From #DataToBeOutput))
			  , @HeaderDateTime VARCHAR(100) = REPLACE(CONVERT(VARCHAR(8), GETDATE(), 112) + CONVERT(VARCHAR(8), GETDATE(), 114), ':','')

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