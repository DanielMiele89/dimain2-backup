CREATE TABLE [MI].[CBP_CustomerSpend] (
    [ID]              INT     IDENTITY (1, 1) NOT NULL,
    [FanID]           INT     NOT NULL,
    [PaymentMethodID] TINYINT NOT NULL,
    [TransCount]      INT     NOT NULL,
    [TransAmount]     MONEY   NOT NULL,
    CONSTRAINT [PK_MI_CBP_CustomerDebit] PRIMARY KEY CLUSTERED ([ID] ASC)
);

