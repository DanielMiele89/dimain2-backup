CREATE TABLE [Staging].[WRBA_Reward_Insight] (
    [Transaction Date]          VARCHAR (50) NULL,
    [Customer ID]               VARCHAR (50) NULL,
    [Card ID   Pan]             VARCHAR (50) NULL,
    [Credit Card Transaction]   VARCHAR (50) NULL,
    [Transaction ID]            VARCHAR (50) NULL,
    [Merchant ID]               VARCHAR (50) NULL,
    [Transaction Amount in KWD] VARCHAR (50) NULL,
    [Source Currency]           VARCHAR (50) NULL,
    [Source Amount]             VARCHAR (50) NULL,
    [Country Code]              VARCHAR (50) NULL,
    [Merchant Category Code]    VARCHAR (50) NULL,
    [Transaction Narrative]     VARCHAR (50) NULL
);




GO
GRANT SELECT
    ON OBJECT::[Staging].[WRBA_Reward_Insight] TO [New_Insight]
    AS [dbo];

