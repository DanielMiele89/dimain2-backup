

-- ***************************************************************************--
-- ***************************************************************************--
-- Author:		Ijaz Amjad													  --
-- Create date: 16/08/2016													  --
-- Description: Check if there are any duplicate deals before populating the  --
--				Reporting Table												  --
-- ***************************************************************************--
-- ***************************************************************************--
CREATE PROCEDURE [Staging].[SSRS_R0129_nFI_Partner_Deals_DuplicateDealCheck&Import]
AS


IF OBJECT_ID ('tempdb..#T1') IS NOT NULL DROP TABLE #T1
SELECT				CAST(ID AS INT) AS ID
,					CAST(ClubID AS INT) AS ClubID
,					CAST(PartnerID AS INT) AS PartnerID
,					CAST(IntroducedBy AS VARCHAR(100)) AS IntroducedBy
,					CAST(ManagedBy AS VARCHAR(100)) AS ManagedBy
,					CASE
						WHEN EndDate IS NULL THEN 1
						ELSE 0
					END AS CurrentDeal
,					CAST(StartDate + '01' AS DATE) AS StartDate
,					CASE
						WHEN EndDate IS NULL THEN NULL
						WHEN EndDate IS NOT NULL THEN CAST(EndDate + '01' AS DATE)
					END AS EndDate
,					CAST(Cashback AS DECIMAL(5,4)) AS Cashback
,					CAST(Publisher AS DECIMAL(5,4)) AS Publisher
,					CAST(Reward AS DECIMAL(5,4)) AS Reward
INTO				#T1
FROM				Staging.nFI_Partner_Deals


INSERT INTO			Staging.nFI_Partner_Deals_For_Reporting 
SELECT				*
FROM				#T1
WHERE				ID NOT IN (	SELECT	ID
								FROM	Staging.nFI_Partner_Deals_For_Reporting)
	--AND				ClubID != ClubID
	--AND				PartnerID != PartnerID
	--AND				StartDate != StartDate
	--AND				EndDate != EndDate
	--AND				Cashback != Cashback
	--AND				Publisher != Publisher
	--AND				Reward != Reward


IF OBJECT_ID ('tempdb..#T2') IS NOT NULL DROP TABLE #T2
SELECT				ID
,					EndDate
INTO				#T2
FROM				Staging.nFI_Partner_Deals


UPDATE				Staging.nFI_Partner_Deals_For_Reporting
SET					EndDate = CAST(#T2.EndDate + '01' AS DATE)
FROM				#T2
WHERE				#T2.ID = Staging.nFI_Partner_Deals_For_Reporting.ID
	AND				#T2.EndDate IS NOT NULL
	AND				Staging.nFI_Partner_Deals_For_Reporting.EndDate IS NULL