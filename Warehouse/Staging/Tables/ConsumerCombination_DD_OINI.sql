CREATE TABLE [Staging].[ConsumerCombination_DD_OINI] (
    [ID]                       BIGINT       IDENTITY (1, 1) NOT NULL,
    [ConsumerCombinationID_DD] BIGINT       NOT NULL,
    [OIN]                      INT          NOT NULL,
    [Narrative_RBS]            VARCHAR (50) NULL,
    [Narrative_VF]             VARCHAR (50) NULL,
    [BrandID]                  INT          NOT NULL
);

