CREATE TABLE [Staging].[Shaun_Combos] (
    [ConsumerCombinationID] INT NULL,
    [BrandID]               INT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_CCID]
    ON [Staging].[Shaun_Combos]([ConsumerCombinationID] ASC);

