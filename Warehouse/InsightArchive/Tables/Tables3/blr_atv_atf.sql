CREATE TABLE [InsightArchive].[blr_atv_atf] (
    [years]          INT          NULL,
    [quarters]       INT          NULL,
    [brandname]      VARCHAR (50) NOT NULL,
    [marketshare]    MONEY        NULL,
    [spend]          MONEY        NULL,
    [previous_sales] MONEY        NULL,
    [customers]      INT          NULL,
    [transactions]   INT          NULL,
    [growth]         MONEY        NULL
);

