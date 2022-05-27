CREATE TABLE [Relational].[Reward3Point0_Accounts] (
    [ID]              INT          IDENTITY (1, 1) NOT NULL,
    [CalculationDate] DATE         NULL,
    [PeriodType]      VARCHAR (50) NOT NULL,
    [EndDate]         DATE         NULL,
    [PublisherID]     INT          NULL,
    [PublisherName]   VARCHAR (50) NULL,
    [AccountTypeCode] VARCHAR (20) NULL,
    [AccountType]     VARCHAR (40) NULL,
    [Accounts]        INT          NULL,
    CONSTRAINT [PK_Reward3Point0_Accounts] PRIMARY KEY CLUSTERED ([ID] ASC)
);

