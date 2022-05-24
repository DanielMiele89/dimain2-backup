CREATE TABLE [Relational].[__Reward3Point0_AccountEarnings_Archived] (
    [ID]                        INT          IDENTITY (1, 1) NOT NULL,
    [CalculationDate]           DATE         NULL,
    [PeriodType]                VARCHAR (50) NOT NULL,
    [StartDate]                 DATE         NOT NULL,
    [EndDate]                   DATE         NOT NULL,
    [IsCurrentMonth]            BIT          NOT NULL,
    [BankAccountID]             INT          NULL,
    [PublisherID]               INT          NULL,
    [PublisherName]             VARCHAR (50) NULL,
    [MostRecentAccountTypeCode] VARCHAR (20) NULL,
    [MostRecentAccountType]     VARCHAR (40) NULL,
    [AccountStartDate]          DATE         NULL,
    [AccountEndDate]            DATE         NULL,
    [IsJointAccount]            BIT          NULL,
    [NomineeFanID]              INT          NULL,
    [Gender]                    VARCHAR (1)  NULL,
    [AgeBucketName]             VARCHAR (6)  NULL,
    [PostcodeDistrict]          VARCHAR (10) NULL,
    [Region]                    VARCHAR (30) NULL,
    [DDMinEarningDate]          DATE         NULL,
    [MobileLoginMinEarningDate] DATE         NULL,
    [DDMaxEarningDate]          DATE         NULL,
    [MobileLoginMaxEarningDate] DATE         NULL,
    [DDEarnings]                MONEY        NULL,
    [MobileLoginEarnings]       MONEY        NULL,
    CONSTRAINT [__PK_Reward3Point0_AccountEarnings_Archived] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [NCIX_Reward3Point0_AccountEarnings]
    ON [Relational].[__Reward3Point0_AccountEarnings_Archived]([StartDate] ASC, [EndDate] ASC, [PublisherID] ASC)
    INCLUDE([BankAccountID]) WITH (FILLFACTOR = 80);


GO
ALTER INDEX [NCIX_Reward3Point0_AccountEarnings]
    ON [Relational].[__Reward3Point0_AccountEarnings_Archived] DISABLE;

