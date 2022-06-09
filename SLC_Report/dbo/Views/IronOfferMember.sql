
CREATE VIEW [dbo].[IronOfferMember]
AS
SELECT IronOfferID, CompositeID, StartDate, EndDate, ImportDate, IsControl,

	CAST(NULL as bit) as AutoAddToNewRegistrants, -- these are all from [Staging].[WarehouseLoad_IronOffer_V1_2]
	Cast(NULL as bit) as AreEligibleMembersCommitted,
	Cast(NULL as bit) as AreControlMembersCommitted,
	Cast(NULL as bit) as IsTriggerOffer

FROM SLC_Snapshot.dbo.IronOfferMember

GO
GRANT SELECT
    ON OBJECT::[dbo].[IronOfferMember] TO [Rory]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[dbo].[IronOfferMember] TO [Analyst]
    AS [dbo];

