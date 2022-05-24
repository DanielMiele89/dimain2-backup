CREATE TABLE [InsightArchive].[LoyaltyCustomers_20160302] (
    [IronOfferID] INT    NOT NULL,
    [CompositeID] BIGINT NOT NULL
);


GO
DENY SELECT
    ON OBJECT::[InsightArchive].[LoyaltyCustomers_20160302] TO [New_PIIRemoved]
    AS [dbo];

