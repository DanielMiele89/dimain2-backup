CREATE TABLE [Staging].[MIDOriginMatch] (
    [BrandMIDID]      INT          NOT NULL,
    [BrandID]         SMALLINT     NOT NULL,
    [LastTranDate]    DATE         NOT NULL,
    [FileID]          INT          NOT NULL,
    [RowNum]          INT          NOT NULL,
    [MID]             VARCHAR (50) NOT NULL,
    [Narrative]       VARCHAR (50) NOT NULL,
    [LocationAddress] VARCHAR (50) NOT NULL,
    [OriginatorID]    VARCHAR (11) NOT NULL,
    [MCC]             VARCHAR (4)  NOT NULL,
    [AcquirerID]      TINYINT      NOT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_Staging_MIDOriginMatch_BrandID]
    ON [Staging].[MIDOriginMatch]([BrandID] ASC)
    INCLUDE([BrandMIDID], [LastTranDate], [MID], [Narrative], [LocationAddress], [OriginatorID], [MCC], [AcquirerID]);

