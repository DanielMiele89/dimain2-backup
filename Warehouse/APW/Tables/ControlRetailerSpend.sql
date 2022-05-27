CREATE TABLE [APW].[ControlRetailerSpend] (
    [ID]                     INT        IDENTITY (1, 1) NOT NULL,
    [PartnerID]              INT        NOT NULL,
    [PseudoActivatedMonthID] INT        NOT NULL,
    [IsOnline]               BIT        NULL,
    [SpenderCount]           FLOAT (53) NOT NULL,
    [TranCount]              FLOAT (53) NOT NULL,
    [Spend]                  MONEY      NOT NULL,
    [adj_Spend]              MONEY      NULL,
    [adj_Spenders]           FLOAT (53) NULL,
    [adj_Txns]               FLOAT (53) NULL,
    CONSTRAINT [PK_APW_ControlRetailerSpend] PRIMARY KEY CLUSTERED ([ID] ASC)
);

