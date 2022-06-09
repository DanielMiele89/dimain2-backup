CREATE VIEW [dbo].[IronOffer]
AS
SELECT ID, Name, StartDate, EndDate, PartnerID, IsAboveTheLine, IsDefaultCollateral, IsSignedOff, IsTriggerOffer, DisplaySuppressed, IsAppliedToAllMembers,
      Cast(NULL as bit) as AutoAddToNewRegistrants, 
      Cast(NULL as bit)	as AreEligibleMembersCommitted, 
      Cast(NULL as bit)	as AreControlMembersCommitted
FROM SLC_Snapshot.dbo.IronOffer

GO
GRANT SELECT
    ON OBJECT::[dbo].[IronOffer] TO [virgin_etl_user]
    AS [dbo];

