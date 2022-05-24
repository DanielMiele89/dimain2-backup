/*

	Author:		Stuart Barnley

	Date:		10th October 2016

	Purpose:	To produce a list of MerchantIDs to be provided to CLS

*/


CREATE PROCEDURE [Staging].[Onboarding_Publisher_HSBCAdvance_ReturnReviewFile]

AS

BEGIN

---------------------------------------------------------------------------------------------------
-----------------------------Produce final data including header and footer------------------------
---------------------------------------------------------------------------------------------------

DECLARE @Rows VARCHAR(100) = CONVERT(VARCHAR(100), (Select COUNT(*) From [Staging].[Onboarding_Publisher_HSBCAdvance_FileImport]))
	  , @HeaderDateTime VARCHAR(100) = REPLACE(CONVERT(VARCHAR(8), GETDATE(), 112) + CONVERT(VARCHAR(8), GETDATE(), 114), ':','')

SELECT '10|' + @HeaderDateTime + '|' + (SELECT MAX(ProjectName) FROM [Staging].[Onboarding_Publisher_HSBCAdvance_FileImport] WHERE RecordType IN (20, 25)) AS OutputForCLS

UNION ALL

SELECT   REPLACE(REPLACE(RecordType
 + '|' + ProjectName
 + '|' + ActionCode
 + '|' + SiteID
 + '|' + Comments
 + '|' + MC_Location
 + '|' + REPLACE(CONVERT(VARCHAR(10), CONVERT(DATE, MC_LastSeenDate), 101), '01/01/1900', '')
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
 + '|' + REPLACE(CONVERT(VARCHAR(10), CONVERT(DATE, EffectiveDate), 101), '01/01/1900', '')
 + '|' + REPLACE(CONVERT(VARCHAR(10), CONVERT(DATE, EndDate), 101), '01/01/1900', '')
 + '|' + DiscountRate
 + '|' + MerchantURL
 + '|' + PassThru1
 + '|' + PassThru2
 + '|' + PassThru3
 + '|' + PassThru4
 + '|' + PassThru5
 + '|' + REPLACE(CONVERT(VARCHAR(10), CONVERT(DATE, FileDate), 101), '01/01/1900', '')
 + '|' + REPLACE(CONVERT(VARCHAR(10), CONVERT(DATE, ReviewDate), 101), '01/01/1900', '')
 + '|' + Unknown1
 + '|' + Unknown2
 + '|' + Unknown3
 + '|' + Unknown4
 + '|' + Unknown5
 + '|' + Unknown6, CHAR(10), ''), CHAR(13), '')
FROM [Staging].[Onboarding_Publisher_HSBCAdvance_FileImport]

UNION ALL

SELECT '30|' + (SELECT MAX(ProjectName) FROM [Staging].[Onboarding_Publisher_HSBCAdvance_FileImport] WHERE RecordType IN (20, 25)) + '|' + @Rows

END