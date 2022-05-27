CREATE TABLE [Staging].[MIDAssessment] (
    [OutletID]              INT           NULL,
    [Mid]                   VARCHAR (50)  NOT NULL,
    [Narrative]             VARCHAR (50)  NOT NULL,
    [LocationCountry]       VARCHAR (3)   NOT NULL,
    [MCCID]                 SMALLINT      NOT NULL,
    [MCCDesc]               VARCHAR (200) NOT NULL,
    [ConsumerCombinationID] INT           NOT NULL,
    [FirstTran]             DATE          NULL,
    [LastTranDate]          DATE          NULL,
    [Tranx]                 INT           NULL,
    [RowNo]                 BIGINT        NULL
);

