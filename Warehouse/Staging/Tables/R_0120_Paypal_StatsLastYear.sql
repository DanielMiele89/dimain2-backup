CREATE TABLE [Staging].[R_0120_Paypal_StatsLastYear] (
    [BrandID]           SMALLINT      NOT NULL,
    [Narrative]         VARCHAR (50)  NOT NULL,
    [MCCID]             SMALLINT      NOT NULL,
    [Transactions]      INT           NULL,
    [TransactionAmount] MONEY         NULL,
    [MCCDesc]           VARCHAR (200) NOT NULL
);

