CREATE TABLE [InsightArchive].[affn_trans] (
    [fileid]                INT          NOT NULL,
    [rownum]                INT          NOT NULL,
    [consumercombinationid] INT          NOT NULL,
    [fanid]                 INT          NOT NULL,
    [locationid]            INT          NOT NULL,
    [spend]                 MONEY        NOT NULL,
    [cardholderpresentdata] TINYINT      NOT NULL,
    [brandid]               SMALLINT     NOT NULL,
    [location]              VARCHAR (50) NULL,
    [trandate]              DATE         NOT NULL,
    PRIMARY KEY CLUSTERED ([fileid] ASC, [rownum] ASC)
);

