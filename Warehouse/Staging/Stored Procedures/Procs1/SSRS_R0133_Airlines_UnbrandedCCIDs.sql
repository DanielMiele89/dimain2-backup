


-- *****************************************************************************************************
-- Author:		Ijaz Amjad
-- Create date: 14/10/2016
-- Description: Shows all unbranded Airline records in the specified MCC's.
-- *****************************************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0133_Airlines_UnbrandedCCIDs]
						
			
AS

	SET NOCOUNT ON;



/***************************************************************************
********* Bring back ALL unbranded records for the specified MCC's *********
***************************************************************************/
IF OBJECT_ID ('tempdb..#T1') IS NOT NULL DROP TABLE #T1
SELECT		cc.BrandID AS CC_BrandID
,			b.Brandname AS CC_Brandname
,			cc.ConsumerCombinationID
,			cc.MID
,			cc.Narrative
,			LocationCountry
,			mcc.MCC
,			mcc.MCCDesc
,			mcc.MCCCategory
,			air.BrandID
,			air.BrandName
INTO		#T1
FROM		Warehouse.Relational.ConsumerCombination AS CC WITH (NOLOCK)
INNER JOIN	Warehouse.Relational.MCCList AS mcc
	ON		cc.MCCID = mcc.MCCID
INNER JOIN	Warehouse.Relational.Brand AS b
	ON		cc.BrandID = b.BrandID
INNER JOIN	Warehouse.Staging.R_0133_IncludedMCCs air
	ON		mcc.MCC = air.MCC
LEFT OUTER JOIN Warehouse.Staging.BrandSuggestionRejected bsr
	ON		cc.ConsumerCombinationID = bsr.ConsumerCombinationID
	AND		air.BrandID = bsr.BrandID
WHERE		cc.BrandID = 944
	AND		bsr.ConsumerCombinationID IS NULL
ORDER BY	mcc.MCCDesc

SELECT		*
FROM		#T1
ORDER BY	MCCDesc,Narrative

--EXEC Warehouse.Prototype.Ijaz_Airlines_Unbranded