CREATE TABLE [Staging].[MIDOriginInfo] (
    [BrandMIDID]      INT          NOT NULL,
    [BrandID]         SMALLINT     NOT NULL,
    [LastTranDate]    DATE         NOT NULL,
    [MaxFileID]       INT          NULL,
    [RowNum]          INT          NULL,
    [MID]             VARCHAR (50) NULL,
    [Narrative]       VARCHAR (50) NULL,
    [LocationAddress] VARCHAR (50) NULL,
    [OriginatorID]    VARCHAR (11) NULL,
    [MCC]             VARCHAR (4)  NULL
);

