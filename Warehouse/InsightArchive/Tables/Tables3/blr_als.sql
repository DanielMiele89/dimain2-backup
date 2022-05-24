CREATE TABLE [InsightArchive].[blr_als] (
    [brandname]       VARCHAR (500) NULL,
    [week_commencing] DATE          NULL,
    [final_segment]   VARCHAR (16)  NOT NULL,
    [isonline]        INT           NOT NULL,
    [spend]           MONEY         NULL,
    [transactions]    INT           NULL,
    [customers]       INT           NULL
);

