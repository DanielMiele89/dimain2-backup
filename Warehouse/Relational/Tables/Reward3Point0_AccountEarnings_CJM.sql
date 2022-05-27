CREATE TABLE [Relational].[Reward3Point0_AccountEarnings_CJM] (
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
    CONSTRAINT [PK_Reward3Point0_AccountEarnings_CJM] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [ix_BankAccountID]
    ON [Relational].[Reward3Point0_AccountEarnings_CJM]([BankAccountID] ASC)
    INCLUDE([AccountEndDate], [StartDate]) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];

