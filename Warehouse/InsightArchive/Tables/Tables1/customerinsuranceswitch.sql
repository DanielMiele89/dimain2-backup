CREATE TABLE [InsightArchive].[customerinsuranceswitch] (
    [ID]             INT      IDENTITY (1, 1) NOT NULL,
    [fanid]          INT      NOT NULL,
    [brandid_from]   SMALLINT NOT NULL,
    [startdate_from] DATE     NOT NULL,
    [enddate_from]   DATE     NOT NULL,
    [brandid_to]     SMALLINT NOT NULL,
    [startdate_to]   DATE     NOT NULL,
    [enddate_to]     DATE     NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

