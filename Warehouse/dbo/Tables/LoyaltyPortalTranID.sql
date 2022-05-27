CREATE TABLE [dbo].[LoyaltyPortalTranID] (
    [ID] INT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_lppt]
    ON [dbo].[LoyaltyPortalTranID]([ID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);

