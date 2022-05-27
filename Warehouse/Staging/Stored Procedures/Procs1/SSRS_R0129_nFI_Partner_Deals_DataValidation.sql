

-- ***************************************************************************--
-- ***************************************************************************--
-- Author:		Ijaz Amjad													  --
-- Create date: 03/08/2016													  --
-- Description: Validation checks on holding table							  --
--				Populates Error Table										  --
-- ***************************************************************************--
-- ***************************************************************************--
CREATE PROCEDURE [Staging].[SSRS_R0129_nFI_Partner_Deals_DataValidation]
AS

TRUNCATE TABLE Staging.nFI_Partner_Deals_Holding_ErrorTable

IF OBJECT_ID ('tempdb..#T1') IS NOT NULL DROP TABLE #T1
SELECT			DISTINCT ID
,				COUNT(1) AS DuplicateCheck
INTO			#T1
FROM			Staging.nFI_Partner_Deals_Holding
GROUP BY		ID
HAVING			COUNT(1) > 1


IF OBJECT_ID ('tempdb..#T2') IS NOT NULL DROP TABLE #T2
SELECT			ID
,				CASE
					WHEN ID IN (SELECT ID FROM #T1) THEN 0
					WHEN ID <= 0 THEN 0
					ELSE 1
				END AS ID_Check
,				CASE
					WHEN ClubID IN (SELECT ID FROM SLC_Report.dbo.Club) THEN 1
					ELSE 0
				END AS ClubID
,				CASE
					WHEN PartnerID IN (SELECT ID FROM SLC_Report.dbo.Partner) THEN 1
					ELSE 0
				END AS PartnerID
,				CASE
					WHEN IntroducedBy IN (SELECT Introduced_By FROM Warehouse.Staging.nFI_Partner_Deals_IntroducedBy_Lookup) THEN 1
					WHEN IntroducedBy IS NULL THEN 1
					ELSE 0
				END AS IntroducedBy
,				CASE
					WHEN ManagedBy IN (SELECT Managed_By FROM Warehouse.Staging.nFI_Partner_Deals_ManagedBy_Lookup) THEN 1
					WHEN ManagedBy IS NULL THEN 1
					ELSE 0
				END AS ManagedBy
,				CASE
					WHEN CAST(StartDate + '01' AS DATE) BETWEEN DATEADD(YEAR,-10,GETDATE()) AND DATEADD(YEAR,1,GETDATE()) THEN 1
					ELSE 0
				END AS StartDate
,				CASE
					WHEN CAST(EndDate + '01' AS DATE) > CAST(StartDate + '01' AS DATE) THEN 1
					WHEN CAST(EndDate + '01' AS DATE) IS NULL THEN 1
					ELSE 0
				END AS EndDate
,				CASE
					WHEN Cashback >= 0 AND Cashback <= 1 THEN 1
					ELSE 0
				END AS Cashback
,				CASE
					WHEN Publisher >= 0 AND Publisher <= 1 THEN 1
					ELSE 0
				END AS Publisher
,				CASE
					WHEN Reward >= 0 AND Reward <= 1 THEN 1
					ELSE 0
				END AS Reward
INTO			#T2
FROM			Staging.nFI_Partner_Deals_Holding


IF OBJECT_ID ('tempdb..#T3') IS NOT NULL DROP TABLE #T3
SELECT			ID
,				CASE
					WHEN ID_Check = 1 THEN 'No Error'
					ELSE 'Invalid ID/Duplicate ID'
				END AS [ID_Check]
,				CASE
					WHEN ClubID = 1 THEN 'No Error'
					ELSE 'Invalid ClubID'
				END AS ClubID
,				CASE
					WHEN PartnerID = 1 THEN 'No Error'
					ELSE 'Invalid PartnerID'
				END AS PartnerID
,				CASE
					WHEN IntroducedBy = 1 THEN 'No Error'
					ELSE 'Invalid Data'
				END AS IntroducedBy
,				CASE
					WHEN ManagedBy = 1 THEN 'No Error'
					ELSE 'Invalid Data'
				END AS ManagedBy
,				CASE
					WHEN StartDate = 1 THEN 'No Error'
					ELSE 'Invalid StartDate'
				END AS StartDate
,				CASE
					WHEN EndDate = 1 THEN 'No Error'
					ELSE 'Invalid EndDate'
				END AS EndDate
,				CASE
					WHEN Cashback = 1 THEN 'No Error'
					ELSE 'Invalid Data'
				END AS Cashback
,				CASE
					WHEN Publisher = 1 THEN 'No Error'
					ELSE 'Invalid Data'
				END AS Publisher
,				CASE
					WHEN Reward = 1 THEN 'No Error'
					ELSE 'Invalid Data'
				END AS Reward
INTO			#T3
FROM			#T2


IF OBJECT_ID ('tempdb..#T4') IS NOT NULL DROP TABLE #T4
SELECT			*
INTO			#T4
FROM			#T3
WHERE			ID_Check != 'No Error'
	OR			ClubID != 'No Error'
	OR			PartnerID != 'No Error'
	OR			IntroducedBy != 'No Error'
	OR			ManagedBy != 'No Error'
	OR			StartDate != 'No Error'
	OR			EndDate != 'No Error'
	OR			Cashback != 'No Error'
	OR			Publisher != 'No Error'
	OR			Reward != 'No Error'



INSERT INTO		Staging.nFI_Partner_Deals_Holding_ErrorTable
				(ID,ID_Check,ClubID,PartnerID,IntroducedBy,ManagedBy,StartDate,EndDate,Cashback,Publisher,Reward)
SELECT			ID
,				ID_Check
,				ClubID
,				PartnerID
,				IntroducedBy
,				ManagedBy
,				StartDate
,				EndDate
,				Cashback
,				Publisher
,				Reward
FROM			#T4



IF OBJECT_ID ('tempdb..#T5') IS NOT NULL DROP TABLE #T5
SELECT			CASE
					WHEN b.ID = a.ID THEN b.ID
					ELSE 'ID NOT MATCHED'
				END AS ID
,				CASE
					WHEN b.ID != a.ID THEN 1
					ELSE 0
				END AS ExistingIDChanged
,				CASE
					WHEN b.ClubID != a.ClubID THEN 1
					ELSE 0
				END AS ExistingClubIDChanged
,				CASE
					WHEN b.PartnerID != a.PartnerID THEN 1
					ELSE 0
				END AS ExistingPartnerIDChanged
,				CASE
					WHEN b.IntroducedBy != a.IntroducedBy THEN 1
					ELSE 0
				END AS ExistingIntroducedByChanged
,				CASE
					WHEN b.ManagedBy != a.ManagedBy THEN 1
					ELSE 0
				END AS ExistingManagedByChanged
,				CASE
					WHEN b.StartDate != a.StartDate THEN 1
					ELSE 0
				END AS ExistingStartDateChanged
,				CASE
					WHEN b.EndDate != a.EndDate AND b.EndDate IS NOT NULL THEN 1
					ELSE 0
				END AS ExistingEndDateChanged
,				CASE
					WHEN b.Cashback != a.Cashback THEN 1
					ELSE 0
				END AS ExistingCashbackChanged
,				CASE
					WHEN b.Publisher != a.Publisher THEN 1
					ELSE 0
				END AS ExistingPublisherChanged
,				CASE
					WHEN b.Reward != a.Reward THEN 1
					ELSE 0
				END AS ExistingRewardChanged
INTO			#T5
FROM			Staging.nFI_Partner_Deals_Holding AS a
	INNER JOIN	Staging.nFI_Partner_Deals AS b
			ON	a.ID = b.ID


IF OBJECT_ID ('Warehouse.Staging.nFI_Partner_Deals_Holding_ErrorExistingChangedTable') IS NOT NULL DROP TABLE Warehouse.Staging.nFI_Partner_Deals_Holding_ErrorExistingChangedTable
SELECT			ID
,				CASE
					WHEN ExistingIDChanged+ExistingClubIDChanged+ExistingPartnerIDChanged+ExistingIntroducedByChanged+ExistingManagedByChanged+ExistingStartDateChanged+ExistingEndDateChanged+ExistingCashbackChanged+ExistingPublisherChanged+ExistingRewardChanged IS NULL THEN 0
					ELSE ExistingIDChanged+ExistingClubIDChanged+ExistingPartnerIDChanged+ExistingIntroducedByChanged+ExistingManagedByChanged+ExistingStartDateChanged+ExistingEndDateChanged+ExistingCashbackChanged+ExistingPublisherChanged+ExistingRewardChanged
				END AS TotalExistingChanges	 
INTO			Staging.nFI_Partner_Deals_Holding_ErrorExistingChangedTable
FROM			#T5


UPDATE			Staging.nFI_Partner_Deals_Holding_ErrorTable
SET				TotalExistingChanges = a.TotalExistingChanges
FROM			Staging.nFI_Partner_Deals_Holding_ErrorExistingChangedTable AS a
INNER JOIN		Staging.nFI_Partner_Deals_Holding_ErrorTable AS b
		ON		a.ID = b.ID