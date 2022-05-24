CREATE TABLE [InsightArchive].[Intern_CustomerTable_v2] (
    [FanID]            INT            NOT NULL,
    [CINID]            INT            NOT NULL,
    [ActivatedMonth]   DATE           NULL,
    [DeactivatedMonth] DATE           NULL,
    [Gender]           CHAR (1)       NULL,
    [AgeBand]          VARCHAR (10)   NOT NULL,
    [SocialClass]      NVARCHAR (255) NOT NULL
);

