CREATE TABLE [Selections].[BOPE_BrandCompetitor] (
    [ID]                INT  IDENTITY (1, 1) NOT NULL,
    [BrandID]           INT  NOT NULL,
    [CompetitorBrandID] INT  NOT NULL,
    [StartDate]         DATE NOT NULL,
    [EndDate]           DATE NULL
);


GO
CREATE CLUSTERED INDEX [CIX_BOPEBrandCompetitor_BrandCompetitorStartEnd]
    ON [Selections].[BOPE_BrandCompetitor]([BrandID] ASC, [StartDate] ASC, [EndDate] ASC, [CompetitorBrandID] ASC) WITH (FILLFACTOR = 70);

