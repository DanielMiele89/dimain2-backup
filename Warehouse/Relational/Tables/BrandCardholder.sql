CREATE TABLE [Relational].[BrandCardholder] (
    [BrandID]               SMALLINT    NOT NULL,
    [CardholderPresentData] VARCHAR (1) NOT NULL,
    [Frequency]             INT         NULL,
    CONSTRAINT [PK_BrandCardholder] PRIMARY KEY CLUSTERED ([BrandID] ASC, [CardholderPresentData] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_BrandCardholder_Frequency]
    ON [Relational].[BrandCardholder]([Frequency] ASC);

