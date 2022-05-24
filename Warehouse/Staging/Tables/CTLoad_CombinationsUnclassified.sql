CREATE TABLE [Staging].[CTLoad_CombinationsUnclassified] (
    [CaseID]             INT          IDENTITY (1, 1) NOT NULL,
    [MID]                VARCHAR (50) NOT NULL,
    [Narrative]          VARCHAR (50) NOT NULL,
    [MCC]                VARCHAR (4)  NOT NULL,
    [MCCDesc]            VARCHAR (50) NOT NULL,
    [LocationAddress]    VARCHAR (50) NOT NULL,
    [OriginatorID]       VARCHAR (11) NOT NULL,
    [SuggestedBrandID]   SMALLINT     NOT NULL,
    [SuggestedBrandName] VARCHAR (50) NOT NULL,
    [BrandSectorID]      TINYINT      NOT NULL,
    [BrandSector]        VARCHAR (50) NOT NULL,
    [MCCSectorID]        TINYINT      NOT NULL,
    [MCCSector]          VARCHAR (50) NOT NULL,
    [HighRisk]           VARCHAR (10) NOT NULL,
    [MCCStatus]          VARCHAR (10) NOT NULL,
    [OriginatorStatus]   VARCHAR (10) NOT NULL,
    CONSTRAINT [PK_Staging_CTLoad_CombinationsUnclassified] PRIMARY KEY CLUSTERED ([CaseID] ASC)
);

