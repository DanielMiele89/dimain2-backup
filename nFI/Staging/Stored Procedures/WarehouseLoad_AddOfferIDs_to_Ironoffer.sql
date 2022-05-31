/*
		Author:			Stuart Barnley

		Date:			3rd March 2016

		Purpose:		This is to create Campaign and Offer Entries where needed and then link
						Unlinked offers to these entries

						The portal requires all IronOfferIDs to be linked to an entry in Offer

*/

CREATE Procedure [Staging].[WarehouseLoad_AddOfferIDs_to_Ironoffer] as

Truncate Table Staging.JobLog_Temp

Declare @Count int
------------------------------------------------------------------------------------------------------
----------------------------------Write Entry to JobLog_Temp------------------------------------------
------------------------------------------------------------------------------------------------------
INSERT INTO Staging.JobLog_Temp
SELECT	StoredProcedureName = 'WarehouseLoad_AddOfferIDs_to_Ironoffer',
	TableSchemaName = 'Relational',
	TableName = 'Campaign',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'A'


Set @Count = (Select Count(*) From Relational.Campaign)
------------------------------------------------------------------------------------------------------
--------------------Create Campaign Entry for any partner where this does not exist-------------------
------------------------------------------------------------------------------------------------------
Insert into  Relational.Campaign 
select	Cast(p.PartnerID as varchar)+'_Unk' as CampaignRef,  --Creates entry such as '2396_Unk'
		3 as CampaignTypeID									 --Marks as Non Roc,
from Relational.Partner as p with (nolock)
Left Outer join Relational.Campaign as c with (nolock)
	on Cast(p.PartnerID as varchar) = Left(c.CampaignRef,Len(Cast(p.PartnerID as varchar))) and
		CampaignRef like '%_Unk'
Where c.ID is null

------------------------------------------------------------------------------------------------------
----------------------------------Update Entry to JobLog_Temp------------------------------------------
------------------------------------------------------------------------------------------------------

UPDATE Staging.JobLog_Temp
SET EndDate = GETDATE(),
	TableRowCount = (Select Count(*) From Relational.Campaign)-@Count
WHERE	StoredProcedureName = 'WarehouseLoad_AddOfferIDs_to_Ironoffer' 
	AND TableSchemaName = 'Relational'
	AND TableName = 'Campaign' 
	AND EndDate IS NULL

------------------------------------------------------------------------------------------------------
----------------------------------Write Entry to JobLog_Temp------------------------------------------
------------------------------------------------------------------------------------------------------
INSERT INTO Staging.JobLog_Temp
SELECT	StoredProcedureName = 'WarehouseLoad_AddOfferIDs_to_Ironoffer',
	TableSchemaName = 'Relational',
	TableName = 'Offer',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'A'


Set @Count = (Select Count(*) From Relational.Offer)

------------------------------------------------------------------------------------------------------
----------------------Create Offer Entry for any partner where this does not exist--------------------
------------------------------------------------------------------------------------------------------
Insert into  Relational.Offer 
Select	13 as OfferTypeID,						-- Marks Offer as Offer Type Unknown
		c.ID as CampaignID,
		NULL as EngagementID,
		0 as IsRoc
From Relational.Campaign as c
Left Outer Join Relational.Offer as o
	on c.ID = o.CampaignID
Where	o.ID is null and
		c.CampaignRef like '%_Unk'

------------------------------------------------------------------------------------------------------
----------------------------------Update Entry to JobLog_Temp-----------------------------------------
------------------------------------------------------------------------------------------------------

UPDATE Staging.JobLog_Temp
SET EndDate = GETDATE(),
	TableRowCount = (Select Count(*) From Relational.Offer)-@Count
WHERE	StoredProcedureName = 'WarehouseLoad_AddOfferIDs_to_Ironoffer' 
	AND TableSchemaName = 'Relational'
	AND TableName = 'Offer' 
	AND EndDate IS NULL

------------------------------------------------------------------------------------------------------
----------------------------------Write Entry to JobLog_Temp------------------------------------------
------------------------------------------------------------------------------------------------------
INSERT INTO Staging.JobLog_Temp
SELECT	StoredProcedureName = 'WarehouseLoad_AddOfferIDs_to_Ironoffer',
	TableSchemaName = 'Relational',
	TableName = 'IronOffer',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'U'

------------------------------------------------------------------------------------------------------
-------------------------------------Find IronOffers with no OfferIDs---------------------------------
------------------------------------------------------------------------------------------------------
Select	i.ID as IronOfferID,
		PartnerID
Into #EmptyOffers
from Relational.IronOffer as i
Where OfferID is null
------------------------------------------------------------------------------------------------------
--------------------------------------------Find OfferIDs to assign-----------------------------------
------------------------------------------------------------------------------------------------------
Select	a.IronOfferID,
		o.ID as OfferID,
		c.CampaignRef
Into #OfferIDs
from #EmptyOffers as a
inner join Relational.Campaign as c with (nolock)
	on Cast(a.PartnerID as varchar) = Left(c.CampaignRef,Len(Cast(a.PartnerID as varchar))) and
		c.CampaignRef like '%_Unk'
inner join Relational.Offer as o
	on c.id = o.CampaignID
------------------------------------------------------------------------------------------------------
------------------------------------------------Update OfferIDs---------------------------------------
------------------------------------------------------------------------------------------------------
Update I
Set OfferID =o.OfferID
From Relational.IronOffer as i
inner join #OfferIDs as o
	on i.ID = o.IronOfferID

------------------------------------------------------------------------------------------------------
----------------------------------Update Entry to JobLog_Temp-----------------------------------------
------------------------------------------------------------------------------------------------------

UPDATE Staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'WarehouseLoad_AddOfferIDs_to_Ironoffer' 
	AND TableSchemaName = 'Relational'
	AND TableName = 'IronOffer' 
	AND EndDate IS NULL

------------------------------------------------------------------------------------------------------
------------------------------------Insert Entry to JobLog--------------------------------------------
------------------------------------------------------------------------------------------------------

INSERT INTO Staging.JobLog
SELECT	StoredProcedureName,
	TableSchemaName,
	TableName,
	StartDate,
	EndDate,
	TableRowCount,
	AppendReload
FROM Staging.JobLog_Temp

TRUNCATE TABLE Staging.JobLog_Temp