CREATE TABLE [InsightArchive].[customer_insuranceswitch] (
    [ID]             INT          NOT NULL,
    [fanid]          INT          NOT NULL,
    [brandid_from]   SMALLINT     NOT NULL,
    [startdate_from] DATE         NOT NULL,
    [enddate_from]   DATE         NOT NULL,
    [brandid_to]     SMALLINT     NOT NULL,
    [startdate_to]   DATE         NOT NULL,
    [enddate_to]     DATE         NOT NULL,
    [brand_from]     VARCHAR (50) NOT NULL,
    [brand_to]       VARCHAR (50) NOT NULL,
    [switch_month]   DATE         NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

