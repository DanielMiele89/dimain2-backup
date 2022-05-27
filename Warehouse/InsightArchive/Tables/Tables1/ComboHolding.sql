CREATE TABLE [InsightArchive].[ComboHolding] (
    [ConsumerCombinationID] INT          NOT NULL,
    [PostCode]              VARCHAR (50) DEFAULT ('') NOT NULL,
    [MatchType]             TINYINT      DEFAULT ((0)) NOT NULL,
    [LocationCountry]       VARCHAR (2)  DEFAULT ('') NOT NULL,
    [Latitude]              VARCHAR (50) DEFAULT ('') NOT NULL,
    [Longitude]             VARCHAR (50) DEFAULT ('') NOT NULL,
    PRIMARY KEY CLUSTERED ([ConsumerCombinationID] ASC)
);

