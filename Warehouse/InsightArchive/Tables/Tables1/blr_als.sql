CREATE TABLE [InsightArchive].[blr_als] (
    [brandname]        VARCHAR (1)  NULL,
    [month_commencing] DATETIME     NULL,
    [final_segment]    VARCHAR (16) NOT NULL,
    [isonline]         INT          NOT NULL,
    [spend]            MONEY        NULL,
    [transactions]     INT          NULL,
    [customers]        INT          NULL
);

