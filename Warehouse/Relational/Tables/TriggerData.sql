CREATE TABLE [Relational].[TriggerData] (
    [FanID]                INT           NOT NULL,
    [CompositeID]          BIGINT        NULL,
    [CINID]                INT           NULL,
    [MerchantCategoryCode] VARCHAR (4)   NOT NULL,
    [TransactionAmount]    MONEY         NOT NULL,
    [TransactionDate]      SMALLDATETIME NULL,
    [LocationName]         VARCHAR (50)  NOT NULL,
    [Neg_Trans]            INT           NOT NULL,
    [TriggerLetter]        VARCHAR (1)   NOT NULL
);

