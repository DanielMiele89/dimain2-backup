CREATE TABLE [WilliamA].[BrandAudit] (
    [idRow]                BIGINT       NULL,
    [BrandID]              SMALLINT     NOT NULL,
    [BrandName]            VARCHAR (50) NOT NULL,
    [Narrative]            VARCHAR (60) NULL,
    [LocationCountry]      VARCHAR (3)  NOT NULL,
    [MCCID]                SMALLINT     NOT NULL,
    [MCCGroup]             VARCHAR (50) NOT NULL,
    [AlternativeBrandName] VARCHAR (50) NOT NULL,
    [ConfidenceRating]     FLOAT (53)   NULL,
    [SuggestedBrandID]     SMALLINT     NOT NULL,
    [SuggestedBrandName]   VARCHAR (50) NOT NULL
);

