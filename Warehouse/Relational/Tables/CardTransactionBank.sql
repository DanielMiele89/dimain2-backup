CREATE TABLE [Relational].[CardTransactionBank] (
    [BankID]         TINYINT      IDENTITY (1, 1) NOT NULL,
    [BankIdentifier] VARCHAR (4)  NULL,
    [BankName]       VARCHAR (50) NULL,
    [IsRainbow]      BIT          CONSTRAINT [DF_CTBank_Rainbow] DEFAULT ((0)) NOT NULL,
    [IsRBS]          BIT          CONSTRAINT [DF_CardTransactionBank_IsRBS] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CardTransactionBank] PRIMARY KEY CLUSTERED ([BankID] ASC)
);

