CREATE TABLE [APW].[SpendPurchaseCount_RetailerSPS] (
    [ID]         INT   IDENTITY (1, 1) NOT NULL,
    [RetailerID] INT   NOT NULL,
    [IsControl]  BIT   NOT NULL,
    [SPS]        MONEY NOT NULL,
    CONSTRAINT [PK_APW_SpendPurchaseCount_RetailerSPS] PRIMARY KEY CLUSTERED ([ID] ASC)
);

