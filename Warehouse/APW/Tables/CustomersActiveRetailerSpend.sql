CREATE TABLE [APW].[CustomersActiveRetailerSpend] (
    [ID]           INT        IDENTITY (1, 1) NOT NULL,
    [PartnerID]    INT        NOT NULL,
    [IsOnline]     BIT        NULL,
    [SpenderCount] FLOAT (53) NOT NULL,
    [TranCount]    FLOAT (53) NOT NULL,
    [Spend]        MONEY      NOT NULL,
    CONSTRAINT [PK_APW_CustomersActiveRetailerSpend] PRIMARY KEY CLUSTERED ([ID] ASC)
);

