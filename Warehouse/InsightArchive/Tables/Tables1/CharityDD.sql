CREATE TABLE [InsightArchive].[CharityDD] (
    [FileID]    INT          NOT NULL,
    [RowNum]    INT          NOT NULL,
    [Amount]    MONEY        NOT NULL,
    [OIN]       INT          NOT NULL,
    [Date]      DATE         NOT NULL,
    [FanID]     INT          NULL,
    [BrandID]   SMALLINT     NOT NULL,
    [sourceuid] VARCHAR (20) NOT NULL,
    CONSTRAINT [PK_InsightArchive_CharityDD] PRIMARY KEY CLUSTERED ([FileID] ASC, [RowNum] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);

