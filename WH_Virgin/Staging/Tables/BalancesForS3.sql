CREATE TABLE [Staging].[BalancesForS3] (
    [customerid]        INT           NULL,
    [cashbackavailable] NVARCHAR (50) NULL,
    [cashbackpending]   NVARCHAR (50) NULL,
    [cashbackltv]       NVARCHAR (50) NULL,
    [FileDate]          DATE          NULL
);

