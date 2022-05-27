CREATE TABLE [InsightArchive].[coffeetrans] (
    [fileid]   INT      NOT NULL,
    [rownum]   INT      NOT NULL,
    [brandid]  SMALLINT NOT NULL,
    [Amount]   MONEY    NOT NULL,
    [trandate] DATE     NOT NULL,
    CONSTRAINT [pk_coffeetrans] PRIMARY KEY CLUSTERED ([fileid] ASC, [rownum] ASC)
);

