CREATE TABLE [Staging].[BrandMatch] (
    [BrandMatchID] INT          IDENTITY (1, 1) NOT NULL,
    [BrandID]      SMALLINT     NOT NULL,
    [Narrative]    VARCHAR (50) NOT NULL,
    PRIMARY KEY CLUSTERED ([BrandMatchID] ASC),
    CONSTRAINT [UQ_BrandMatch_Narrative] UNIQUE NONCLUSTERED ([Narrative] ASC) WITH (FILLFACTOR = 80)
);


GO
CREATE NONCLUSTERED INDEX [IX_BrandMatch_BrandIDNarrative]
    ON [Staging].[BrandMatch]([BrandID] ASC, [Narrative] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff]
    ON [Staging].[BrandMatch]([Narrative] ASC)
    INCLUDE([BrandID]) WITH (FILLFACTOR = 80);

