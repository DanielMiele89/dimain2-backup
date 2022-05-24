

-- ***************************************************************************--
-- ***************************************************************************--
-- Author:		Ijaz Amjad													  --
-- Create date: 04/08/2016													  --
-- Description: Populates nFI Partner Deals Table with Validated Data		  --
-- ***************************************************************************--
-- ***************************************************************************--
CREATE PROCEDURE [Staging].[SSRS_R0129_nFI_Partner_Deals_ImportData]
AS


INSERT INTO			Staging.nFI_Partner_Deals
SELECT				*
FROM				Staging.nFI_Partner_Deals_Holding
WHERE				ID NOT IN (	SELECT	ID
								FROM	Staging.nFI_Partner_Deals)


IF OBJECT_ID ('tempdb..#T1') IS NOT NULL DROP TABLE #T1
SELECT				ID
,					EndDate
INTO				#T1
FROM				Staging.nFI_Partner_Deals_Holding


UPDATE				Staging.nFI_Partner_Deals
SET					EndDate = #T1.EndDate
FROM				#T1
WHERE				#T1.ID = Staging.nFI_Partner_Deals.ID
	AND				#T1.EndDate IS NOT NULL
	AND				Staging.nFI_Partner_Deals.EndDate IS NULL