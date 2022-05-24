CREATE TABLE [InsightArchive].[Italy_ComboSpend] (
    [ConsumerCombinationID] INT          NOT NULL,
    [OriginalBrandID]       INT          NOT NULL,
    [SiloBrandID]           INT          NULL,
    [MID]                   VARCHAR (50) NOT NULL,
    [Narrative]             VARCHAR (50) NOT NULL,
    [MCC]                   VARCHAR (4)  NOT NULL,
    [MCCDesc]               VARCHAR (50) NOT NULL,
    [SectorID]              TINYINT      NOT NULL,
    [Brand]                 VARCHAR (50) NOT NULL,
    [Sector]                VARCHAR (50) NOT NULL,
    [CountryCode]           VARCHAR (3)  NOT NULL,
    [Spend]                 MONEY        NOT NULL,
    [iscreditorigin]        BIT          NOT NULL,
    [LastProcessed]         DATETIME     NULL,
    PRIMARY KEY CLUSTERED ([ConsumerCombinationID] ASC)
);

