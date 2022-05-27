CREATE TABLE [Staging].[WRBA_Reward_Insight_DUMP_V2] (
    [Transaction Date]          DATETIME      NULL,
    [Customer ID]               VARCHAR (50)  NULL,
    [Card ID   Pan]             VARCHAR (50)  NULL,
    [Credit Card Transaction]   NUMERIC (18)  NULL,
    [Transaction ID]            VARCHAR (50)  NULL,
    [Merchant ID]               VARCHAR (50)  NULL,
    [Transaction Amount in KWD] NUMERIC (18)  NULL,
    [Source Currency]           VARCHAR (10)  NULL,
    [Source Amount]             VARCHAR (50)  NULL,
    [Country Code]              VARCHAR (10)  NULL,
    [Cardholder Present Value]  VARCHAR (5)   NULL,
    [Merchant Category Code]    NUMERIC (18)  NULL,
    [Transaction Narrative]     VARCHAR (100) NULL
);




GO
GRANT SELECT
    ON OBJECT::[Staging].[WRBA_Reward_Insight_DUMP_V2] TO [Vernon]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[Staging].[WRBA_Reward_Insight_DUMP_V2] TO [SamH]
    AS [dbo];

