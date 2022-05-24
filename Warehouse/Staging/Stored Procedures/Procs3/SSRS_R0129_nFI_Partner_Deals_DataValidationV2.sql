

-- ***************************************************************************--
-- ***************************************************************************--
-- Author:		Ijaz Amjad													  --
-- Create date: 15/08/2016													  --
-- Description: Validation checks on holding table							  --
--				Populates Error Table										  --
-- ***************************************************************************--
-- ***************************************************************************--
CREATE PROCEDURE [Staging].[SSRS_R0129_nFI_Partner_Deals_DataValidationV2]
AS

Delete From Staging.nFI_Partner_Deals_Holding Where ID is null
/***************************************************************************
************************** Duplicate Check *********************************
***************************************************************************/
IF OBJECT_ID ('tempdb..#DuplicateCheck') IS NOT NULL DROP TABLE #DuplicateCheck
SELECT			DISTINCT ID
,				COUNT(1) AS DuplicateCheck
INTO			#DuplicateCheck
FROM			Staging.nFI_Partner_Deals_Holding
GROUP BY		ID
HAVING			COUNT(1) > 1


/***************************************************************************
***************** Check values that are in Holding Table *******************
***************************************************************************/
INSERT INTO		Staging.nFI_Partner_Deals_ErrorTable_Temp
				(ID,ID_Check,ClubID,PartnerID,IntroducedBy,ManagedBy,StartDate,EndDate,Cashback,Publisher,Reward,TotalPercentage)
SELECT			ID
,				CASE
					WHEN ID IN (SELECT ID FROM #DuplicateCheck) THEN 0
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
,				CASE
					WHEN CAST(Cashback AS FLOAT) + CAST(Publisher AS FLOAT) + CAST(Reward AS FLOAT) = 1 THEN 1
					WHEN CAST(Cashback AS Real) + CAST(Publisher AS Real) + CAST(Reward AS Real) = 1 THEN 1
					ELSE 0
				END AS TotalPercentage
FROM			Staging.nFI_Partner_Deals_Holding


IF OBJECT_ID ('tempdb..#ExistingChangesCheck') IS NOT NULL DROP TABLE #ExistingChangesCheck
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
INTO			#ExistingChangesCheck
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
FROM			#ExistingChangesCheck


UPDATE			Staging.nFI_Partner_Deals_ErrorTable_Temp
SET				TotalExistingChanges = a.TotalExistingChanges
FROM			Staging.nFI_Partner_Deals_Holding_ErrorExistingChangedTable AS a
INNER JOIN		Staging.nFI_Partner_Deals_ErrorTable_Temp AS b
		ON		a.ID = b.ID


/***************************************************************************
******************** Create Error Table to display  ************************
***************************************************************************/
IF OBJECT_ID ('tempdb..#Checks') IS NOT NULL DROP TABLE #Checks
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
,				CASE
					WHEN TotalPercentage = 1 THEN 'No Error'
					ELSE 'SUM Not equal to 100%'
				END AS TotalPercentage
,				CASE
					WHEN TotalExistingChanges = 0 THEN 'No Error'
					WHEN TotalExistingChanges IS NULL THEN 'No Error'
					ELSE 'Existing Change(s) Made'
				END AS TotalExistingChanges
INTO			#Checks
FROM			Staging.nFI_Partner_Deals_ErrorTable_Temp


INSERT INTO		Staging.nFI_Partner_Deals_ErrorTable
SELECT			*
FROM			#Checks
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
	OR			TotalPercentage != 'No Error'
	OR			TotalExistingChanges != 'No Error'


IF OBJECT_ID ('Warehouse.Staging.nFI_Partner_Deals_ErrorDuplicateDeals') IS NOT NULL DROP TABLE Warehouse.Staging.nFI_Partner_Deals_ErrorDuplicateDeals
SELECT				ClubID
,					PartnerID
,					COUNT(1) AS CurrentDeals
INTO				Staging.nFI_Partner_Deals_ErrorDuplicateDeals
FROM				Warehouse.Staging.nFI_Partner_Deals_Holding
WHERE				EndDate IS NULL
GROUP BY			ClubID
,					PartnerID
HAVING				COUNT(1) > 1