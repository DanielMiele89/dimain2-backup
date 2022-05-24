CREATE TABLE [Relational].[BrandCompetitor] (
    [BrandCompetitorID] INT      IDENTITY (1, 1) NOT NULL,
    [BrandID]           SMALLINT NULL,
    [CompetitorID]      SMALLINT NULL,
    CONSTRAINT [PK_BrandCompetitor] PRIMARY KEY CLUSTERED ([BrandCompetitorID] ASC),
    CONSTRAINT [UQ_BrandCompetitor_BrandIDCompetitorID] UNIQUE NONCLUSTERED ([BrandID] ASC, [CompetitorID] ASC) WITH (FILLFACTOR = 80)
);


GO
CREATE NONCLUSTERED INDEX [IX_BrandCompetitor_Brand]
    ON [Relational].[BrandCompetitor]([BrandID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [IX_BrandCompetitor_Competitor]
    ON [Relational].[BrandCompetitor]([CompetitorID] ASC) WITH (FILLFACTOR = 80);

