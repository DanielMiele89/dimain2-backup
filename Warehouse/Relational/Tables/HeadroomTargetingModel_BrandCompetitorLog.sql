CREATE TABLE [Relational].[HeadroomTargetingModel_BrandCompetitorLog] (
    [ID]             INT            IDENTITY (1, 1) NOT NULL,
    [HeadroomID]     INT            NOT NULL,
    [CompetitorID]   INT            NOT NULL,
    [CompetitorName] NVARCHAR (150) NOT NULL
);

