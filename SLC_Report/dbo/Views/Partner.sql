
CREATE VIEW [dbo].[Partner]
AS
SELECT ID, Name, PartnerType, [Status], Country, CommissionRate, MerchantID, RegisteredName, MerchantAcquirer, CompanyWebsite, Matcher, ShowMaps, FanID
FROM SLC_Snapshot.dbo.[Partner]
