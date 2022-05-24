CREATE TABLE [MI].[ConsumerCombination_DM_Case] (
    [ConsumerCombinationID] INT          NOT NULL,
    [BrandID]               SMALLINT     NOT NULL,
    [MID]                   VARCHAR (50) NOT NULL,
    [LocationCountry]       VARCHAR (3)  NOT NULL,
    [MCCID]                 SMALLINT     NOT NULL,
    [OriginatorID]          VARCHAR (11) NOT NULL,
    [AcquirerID]            TINYINT      NOT NULL,
    CONSTRAINT [PK_MI_ConsumerCombination_DM_Case] PRIMARY KEY CLUSTERED ([ConsumerCombinationID] ASC)
);

