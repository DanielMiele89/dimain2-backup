CREATE TABLE [Staging].[Customer_FirstEarnDDPhase2] (
    [ID]             INT          IDENTITY (1, 1) NOT NULL,
    [FanID]          INT          NOT NULL,
    [FirstEarnValue] SMALLMONEY   NOT NULL,
    [FirstEarnDate]  DATE         NOT NULL,
    [BankAccountID]  INT          NOT NULL,
    [AccountName]    VARCHAR (40) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_Customer_FirstEarnDDPhase2_Combined]
    ON [Staging].[Customer_FirstEarnDDPhase2]([FanID] ASC, [FirstEarnDate] ASC) WITH (FILLFACTOR = 80);

