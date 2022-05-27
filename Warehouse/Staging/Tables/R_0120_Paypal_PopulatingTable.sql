CREATE TABLE [Staging].[R_0120_Paypal_PopulatingTable] (
    [BrandID]           SMALLINT     NOT NULL,
    [Narrative]         VARCHAR (50) NOT NULL,
    [MCCID]             SMALLINT     NOT NULL,
    [Transactions]      INT          NULL,
    [TransactionAmount] MONEY        NULL
);

