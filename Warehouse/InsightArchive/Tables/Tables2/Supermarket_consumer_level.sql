CREATE TABLE [InsightArchive].[Supermarket_consumer_level] (
    [ConsumerCombinationID] INT         NOT NULL,
    [First_tran]            DATE        NULL,
    [Last_tran]             DATE        NULL,
    [Amount]                MONEY       NULL,
    [No_trans]              INT         NULL,
    [No_customers]          INT         NULL,
    [LocationCountry]       VARCHAR (3) NOT NULL
);


GO
CREATE CLUSTERED INDEX [CC_IDX]
    ON [InsightArchive].[Supermarket_consumer_level]([ConsumerCombinationID] ASC);

