CREATE TABLE [Prototype].[retailer_email_stats_calculation] (
    [partnerID]   INT          NOT NULL,
    [senddate]    DATE         NULL,
    [CSRef]       VARCHAR (20) NULL,
    [ironofferid] INT          NULL,
    [fanid]       INT          NULL,
    [opened]      TINYINT      DEFAULT ((0)) NULL,
    [spent]       TINYINT      DEFAULT ((0)) NULL
);

