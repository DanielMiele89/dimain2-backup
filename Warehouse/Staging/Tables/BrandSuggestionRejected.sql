CREATE TABLE [Staging].[BrandSuggestionRejected] (
    [ID]                    INT          IDENTITY (1, 1) NOT NULL,
    [MID]                   VARCHAR (50) NULL,
    [ConsumerCombinationID] INT          NULL,
    [BrandID]               SMALLINT     NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [I_BrandSuggestionRejected_BrandID]
    ON [Staging].[BrandSuggestionRejected]([BrandID] ASC);


GO
CREATE NONCLUSTERED INDEX [I_BrandSuggestionRejected_CCID]
    ON [Staging].[BrandSuggestionRejected]([ConsumerCombinationID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [I_BrandSuggestionRejected_MID]
    ON [Staging].[BrandSuggestionRejected]([MID] ASC);

