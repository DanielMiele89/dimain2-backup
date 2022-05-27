CREATE TABLE [Staging].[BrandExistingCombinations_DD] (
    [ID]                       INT           IDENTITY (1, 1) NOT NULL,
    [ConsumerCombinationID_DD] BIGINT        NULL,
    [DataSource]               VARCHAR (50)  NULL,
    [OIN]                      INT           NULL,
    [BrandID]                  INT           NULL,
    [Narrative_RBS]            VARCHAR (250) NULL,
    [Narrative_VF]             VARCHAR (250) NULL
);

