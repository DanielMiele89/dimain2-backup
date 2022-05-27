/*

	Author:		Stuart Barnley

	Date:		10th October 2016

	Purpose:	To produce a list of MerchantIDs to be provided to CLS

*/


CREATE PROCEDURE [Staging].[Onboarding_Matcher_Mastercard_ReturnReviewFile]

AS

BEGIN

---------------------------------------------------------------------------------------------------
-----------------------------Produce final data including header and footer------------------------
---------------------------------------------------------------------------------------------------


DECLARE @Rows VARCHAR(100) = CONVERT(VARCHAR(100), (Select COUNT(*) From [Staging].[Onboarding_Matcher_Mastercard_FileImport]))
	  , @HeaderDateTime VARCHAR(100) = REPLACE(CONVERT(VARCHAR(8), GETDATE(), 112) + CONVERT(VARCHAR(8), GETDATE(), 114), ':','')

SELECT '10|' + @HeaderDateTime + '|' + (SELECT MAX(ProjectName) FROM [Staging].[Onboarding_Matcher_Mastercard_FileImport] WHERE RecordType = 20) AS OutputForCLS

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
 + '|' + ReviewDate
 + '|' + Unknown1
 + '|' + Unknown2
 + '|' + Unknown3
 + '|' + Unknown4
 + '|' + Unknown5
 + '|' + Unknown6
FROM [Staging].[Onboarding_Matcher_Mastercard_FileImport]

UNION ALL

SELECT '30|' + (SELECT MAX(ProjectName) FROM [Staging].[Onboarding_Matcher_Mastercard_FileImport] WHERE RecordType = 20) + '|' + @Rows

END