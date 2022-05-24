CREATE TABLE [InsightArchive].[customerenergyspend] (
    [id]        INT      IDENTITY (1, 1) NOT NULL,
    [fanid]     INT      NOT NULL,
    [brandid]   SMALLINT NOT NULL,
    [startdate] DATE     NOT NULL,
    [enddate]   DATE     NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);

