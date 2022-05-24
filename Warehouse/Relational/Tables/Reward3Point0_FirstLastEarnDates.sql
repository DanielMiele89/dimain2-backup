CREATE TABLE [Relational].[Reward3Point0_FirstLastEarnDates] (
    [ID]                        INT          IDENTITY (1, 1) NOT NULL,
    [CalculationDate]           DATE         NULL,
    [PublisherID]               INT          NULL,
    [PublisherName]             VARCHAR (50) NULL,
    [IssuerBankAccountID]       INT          NULL,
    [MostRecentAccountTypeCode] VARCHAR (20) NULL,
    [MostRecentAccountType]     VARCHAR (40) NULL,
    [AccountStartDate]          DATE         NULL,
    [AccountEndDate]            DATE         NULL,
    [DDMinEarningDate]          DATE         NULL,
    [MobileLoginMinEarningDate] DATE         NULL,
    [DDMaxEarningDate]          DATE         NULL,
    [MobileLoginMaxEarningDate] DATE         NULL,
    CONSTRAINT [PK_Reward3Point0_FirstLastEarnDates] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UNCIX_Reward3Point0_FirstLastEarnDates]
    ON [Relational].[Reward3Point0_FirstLastEarnDates]([IssuerBankAccountID] ASC);

