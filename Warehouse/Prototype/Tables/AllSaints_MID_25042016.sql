CREATE TABLE [Prototype].[AllSaints_MID_25042016] (
    [ConsumerCombinationID] INT          NOT NULL,
    [BrandID]               SMALLINT     NOT NULL,
    [MID]                   VARCHAR (50) NOT NULL,
    [Narrative]             VARCHAR (50) NOT NULL,
    [TransactionDate]       DATE         NOT NULL,
    [TransactionAmount]     MONEY        NOT NULL,
    [LocationCountry]       VARCHAR (3)  NOT NULL,
    [IsOnline]              BIT          NOT NULL,
    [IsUKSpend]             BIT          NOT NULL
);

