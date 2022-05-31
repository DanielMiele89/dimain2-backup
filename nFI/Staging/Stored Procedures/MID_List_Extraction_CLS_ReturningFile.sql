/*

	Author:		Stuart Barnley

	Date:		10th October 2016

	Purpose:	To produce a list of MerchantIDs to be provided to CLS

*/


CREATE PROCEDURE [Staging].[MID_List_Extraction_CLS_ReturningFile]

AS

BEGIN


---------------------------------------------------------------------------------------------------
-----------------------------Produce final data including header and footer------------------------
---------------------------------------------------------------------------------------------------

SELECT *
INTO #DataToBeOutput
FROM Warehouse.Staging.CLS_Onboarding_FileImport

SELECT *
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