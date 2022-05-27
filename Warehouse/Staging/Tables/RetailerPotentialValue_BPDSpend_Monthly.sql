CREATE TABLE [Staging].[RetailerPotentialValue_BPDSpend_Monthly] (
    [StartDate]  DATE  NULL,
    [EndDate]    DATE  NULL,
    [RetailerID] INT   NULL,
    [Spend]      MONEY NULL
);


GO
CREATE CLUSTERED INDEX [CIX_RetailerPotentialValue_BPDSpend_Monthly]
    ON [Staging].[RetailerPotentialValue_BPDSpend_Monthly]([RetailerID] ASC, [StartDate] ASC, [EndDate] ASC);

