CREATE TABLE [MI].[DataCleanseIdentification] (
    [ConsumerCombinationID] INT           NOT NULL,
    [prDescription]         BIT           NULL,
    [prSector]              BIT           NULL,
    [prNarrative]           BIT           NULL,
    [Brandid]               SMALLINT      NOT NULL,
    [BrandName]             VARCHAR (50)  NOT NULL,
    [BrGroup]               VARCHAR (50)  NULL,
    [BrSector]              VARCHAR (50)  NULL,
    [McGroup]               VARCHAR (50)  NULL,
    [McSector]              VARCHAR (50)  NULL,
    [MCCCategory]           VARCHAR (50)  NOT NULL,
    [AssumedMCCDesc]        VARCHAR (200) NULL,
    [MCCDesc]               VARCHAR (200) NOT NULL,
    [MID]                   VARCHAR (50)  NOT NULL,
    [MIDFreq]               INT           NULL,
    [AssumedMID]            VARCHAR (50)  NULL,
    [Narrative]             VARCHAR (50)  NOT NULL,
    [BrandMatch]            VARCHAR (50)  NULL,
    [LocationCountry]       VARCHAR (3)   NOT NULL,
    [AcquirerID]            TINYINT       NULL
);

