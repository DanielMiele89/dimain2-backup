CREATE TABLE [Staging].[ellis] (
    [BrandMIDID]      INT           NOT NULL,
    [MID]             VARCHAR (50)  NULL,
    [FileID]          INT           NOT NULL,
    [RowNum]          INT           NULL,
    [Narrative]       VARCHAR (50)  NULL,
    [LastTranDate]    SMALLDATETIME NULL,
    [LocationAddress] VARCHAR (50)  NULL,
    [MCC]             VARCHAR (4)   NULL,
    [OriginatorID]    VARCHAR (11)  NULL
);

