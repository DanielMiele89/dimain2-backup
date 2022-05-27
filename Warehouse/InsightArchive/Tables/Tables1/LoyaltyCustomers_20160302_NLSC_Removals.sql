CREATE TABLE [InsightArchive].[LoyaltyCustomers_20160302_NLSC_Removals] (
    [ID]          INT      NOT NULL,
    [LionSendID]  INT      NULL,
    [CompositeId] BIGINT   NOT NULL,
    [TypeID]      INT      NULL,
    [ItemRank]    INT      NULL,
    [ItemID]      INT      NULL,
    [Date]        DATETIME NULL
);




GO
DENY SELECT
    ON OBJECT::[InsightArchive].[LoyaltyCustomers_20160302_NLSC_Removals] TO [New_PIIRemoved]
    AS [dbo];

