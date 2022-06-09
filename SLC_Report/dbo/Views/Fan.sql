
	CREATE VIEW [dbo].[Fan]
	AS
	SELECT ID, ClubID, Title, Email, FirstName, LastName, Sex, DOB, Address1, Address2, City, Postcode, County, RegistrationDate
		, [Status], Telephone, MobileTelephone, SourceUID, Country, Unsubscribed, HardBounced, ContactByEmail_old, ContactByPhone
		, ContactBySMS, EmailFormatHTML, OnlineOnly, UserName, ClubCashPending, ClubCashAvailable, CompositeID, ContactByPost
		, AgreedTCs, AgreedTCsDate, OfflineOnly, DeceasedDate, OptOut, ActivationChannel
		, PointsPending, PointsAvailable
	FROM SLC_Snapshot.dbo.Fan

GO
GRANT SELECT
    ON OBJECT::[dbo].[Fan] TO [Analyst]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([SourceUID]) TO [virgin_etl_user]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([ID]) TO [virgin_etl_user]
    AS [dbo];


GO
GRANT SELECT
    ON [dbo].[Fan] ([ClubID]) TO [virgin_etl_user]
    AS [dbo];

