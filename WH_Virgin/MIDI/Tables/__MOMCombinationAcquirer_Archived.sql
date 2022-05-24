CREATE TABLE [MIDI].[__MOMCombinationAcquirer_Archived] (
    [ConsumerCombinationID] INT          NOT NULL,
    [BrandID]               SMALLINT     NOT NULL,
    [MID]                   VARCHAR (50) NOT NULL,
    [Narrative]             VARCHAR (50) NOT NULL,
    [LastTranDate]          DATE         NOT NULL,
    [OriginatorID]          VARCHAR (11) NOT NULL,
    [LocationAddress]       VARCHAR (50) NOT NULL,
    [MCCID]                 SMALLINT     NOT NULL,
    [AcquirerID]            TINYINT      NOT NULL,
    CONSTRAINT [PK_MI_MOMCombinationAcquirer] PRIMARY KEY CLUSTERED ([ConsumerCombinationID] ASC)
);

