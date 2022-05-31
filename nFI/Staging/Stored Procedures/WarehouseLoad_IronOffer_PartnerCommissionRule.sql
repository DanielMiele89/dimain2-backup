/**********************************************************
Author:	Suraj Chahal
Date:	01-02-2016
Purpose: Reload PartnerCommissionRule data from
	SLC report for all nFI offers.
**********************************************************/
CREATE PROCEDURE [Staging].[WarehouseLoad_IronOffer_PartnerCommissionRule]
AS
BEGIN

/******************************************************************
******************Write entry to JobLog Table**********************
******************************************************************/
INSERT INTO Staging.JobLog_Temp
SELECT	StoredProcedureName = 'WarehouseLoad_IronOffer_PartnerCommissionRule',
	TableSchemaName = 'Relational',
	TableName = 'IronOffer_PartnerCommissionRule',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'R'


/**********************************************
*********Truncate table before reload**********
**********************************************/
TRUNCATE TABLE Relational.IronOffer_PartnerCommissionRule


/**********************************
****Create Temp Publisher Table****
**********************************/
IF OBJECT_ID ('tempdb..#Clubs') IS NOT NULL DROP TABLE #Clubs
SELECT	ROW_NUMBER() OVER(ORDER BY ClubID) as RowNo,
	*
INTO #Clubs
FROM Relational.Club

CREATE CLUSTERED INDEX IDX_CID ON #Clubs (ClubID)



/***************************************************
*********Reload PartnerCommissionRule Data**********
***************************************************/
DECLARE @RowNo SMALLINT
SET @RowNo = 1

WHILE @RowNo <= (SELECT MAX(RowNo) FROM #Clubs)

BEGIN

INSERT INTO Relational.IronOffer_PartnerCommissionRule
SELECT	pcr.ID,
	PartnerID,
	TypeID,
	CommissionRate,
	Status,
	Priority,
	DeletionDate,
	MaximumUsesPerFan as MaximumUsesPerFan,
	RequiredNumberOfPriorTransactions as NumberofPriorTransactions,
	RequiredMinimumBasketSize as MinimumBasketSize,
	RequiredMaximumBasketSize as MaximumBasketSize,
	RequiredChannel,
	RequiredClubID,
	RequiredIronOfferID as IronOfferID,
	RequiredRetailOutletID,
	RequiredCardholderPresence
FROM SLC_Report..PartnerCommissionRule pcr
INNER JOIN SLC_Report..IronOfferClub ioc
	ON pcr.RequiredIronOfferID = ioc.IronOfferID
INNER JOIN #Clubs cl
	ON ioc.ClubID = cl.ClubID
	AND cl.RowNo = @RowNo
WHERE RequiredIronOfferID IS NOT NULL
ORDER BY IronOfferID, TypeID

SET @RowNo = @RowNo+1

END

ALTER INDEX ALL ON Relational.IronOffer_PartnerCommissionRule REBUILD

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
UPDATE  Staging.JobLog_Temp
SET	EndDate = GETDATE()
WHERE	StoredProcedureName = 'WarehouseLoad_IronOffer_PartnerCommissionRule' AND
	TableSchemaName = 'Relational' AND
	TableName = 'IronOffer_PartnerCommissionRule' AND
	EndDate IS NULL
		
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
UPDATE  Staging.JobLog_Temp
SET	TableRowCount = (Select COUNT(*) from Relational.IronOffer_PartnerCommissionRule)
WHERE	StoredProcedureName = 'WarehouseLoad_IronOffer_PartnerCommissionRule' and
	TableSchemaName = 'Relational' and
	TableName = 'IronOffer_PartnerCommissionRule' and
	TableRowCount IS NULL


INSERT INTO Staging.JobLog
SELECT	[StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
FROM Staging.JobLog_Temp

TRUNCATE TABLE Staging.JobLog_Temp


END

