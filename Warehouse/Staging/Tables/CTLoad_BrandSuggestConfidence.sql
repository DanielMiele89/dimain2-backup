CREATE TABLE [Staging].[CTLoad_BrandSuggestConfidence] (
    [MatchTypeID] TINYINT      NOT NULL,
    [Confidence]  VARCHAR (5)  NOT NULL,
    [MatchType]   VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_Staging_CTLoad_BrandSuggestConfidence] PRIMARY KEY CLUSTERED ([MatchTypeID] ASC)
);

