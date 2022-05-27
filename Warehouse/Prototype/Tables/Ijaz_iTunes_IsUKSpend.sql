CREATE TABLE [Prototype].[Ijaz_iTunes_IsUKSpend] (
    [BrandID]               SMALLINT     NULL,
    [ConsumerCombinationID] INT          NULL,
    [MID]                   VARCHAR (50) NULL,
    [Narrative]             VARCHAR (50) NULL,
    [LocationCountry]       VARCHAR (3)  NULL,
    [IsUKSpend]             BIT          NULL
);


GO
CREATE NONCLUSTERED INDEX [IDX_CCID]
    ON [Prototype].[Ijaz_iTunes_IsUKSpend]([ConsumerCombinationID] ASC);

