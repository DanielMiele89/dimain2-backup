CREATE VIEW dbo.Club
AS
SELECT ID, Name, Nickname, Abbreviation, FolderName, [Status], AccountNumberPrefix, LastAccountNumber, LastCallCentreCardNumber, Pointsname, DataAName, DataBName, DataCName
	, username, [password], sessionid, ContactEmail, DGMID, DGMPassword, EditDetailsPoints, PointsPerPound, ClubSplit, FanSplit, BaseVATID, FirstSwipePoints, FirstSwipeSpendMinimum
	, InitialFanCount, InitialGoneawayCount, InitialDeceasedCount, EmailFromName, OnlineLaunchDate, OfflineLaunchDate, Trial, ClubUrl, OnlineOnly, RewardUrl, AdvancePoints
	, ReferralPoints, IsProxy, ShowVouchers, ShowScratchCards, IsCardRegistrationMandatory, MaximumPTPR, ColourPrimary, DefaultCountry, RegistrationEnabled, ReferAFanEnabled
	, FirstSpendBonus, MinimumAge, BankAccountEnabled, RedemptionOrderEmail, DefaultLanguage, Languages, RewardsPerPage, OnlinePartnersPerPage, DefaultShoppingCountryID
	, CardRegistrationBonus, RewardShowcaseEnabled, SignedOutRewardsShowcaseEnabled, SignedInRewardsShowcaseEnabled, ClubTypeID, HomeNotSignedInShowcaseEnabled, RewardsEnabled
	, ClubCash, PrepayProviderID, IncludeInEmailUpload, SignedInOnlineShoppingShowcaseEnabled, RssUrl, GoogleAnalyticsId, DefaultCurrency, ClubCashName, GiftcardsEnabled
	, CashCardEnabled, CashCardMinThreshold, CashCardMaxThreshold, CashCardAllowDebitCards, CashCardAllowCreditCards, AutoEmailEnabled, CashCardDayLimit, ForcePasswordEnabled
	, AutoRedeemEnabled, DefaultAutoRedeemID, eVoucherDayLimit, ProgrammeUID, IsOfferBased, APISecretKey, AllowPublisherToUpdateBalance, LogOutRedirectUrl
FROM SLC_Snapshot.dbo.Club