CREATE TABLE [InsightArchive].[curveclean] (
    [ID]                    INT           NOT NULL,
    [CustomerID]            INT           NOT NULL,
    [TranDate]              DATETIME      NOT NULL,
    [DateProcessed]         DATETIME      NOT NULL,
    [PointOfSaleCurrency]   VARCHAR (5)   NOT NULL,
    [Amount]                MONEY         NOT NULL,
    [ForeignSpendAmount]    MONEY         NOT NULL,
    [DoingBusiness]         VARCHAR (50)  NOT NULL,
    [DoingBusiness_Verbose] VARCHAR (50)  NOT NULL,
    [MCC]                   VARCHAR (4)   NOT NULL,
    [MerchantAddress]       VARCHAR (100) NOT NULL,
    [MerchantPostCode]      VARCHAR (10)  NOT NULL,
    [Category]              VARCHAR (20)  NOT NULL,
    [AgeBracket]            VARCHAR (10)  NOT NULL,
    [CustomerPostCode]      VARCHAR (20)  NOT NULL,
    [ConsumerCombinationID] INT           NULL,
    [BrandID]               SMALLINT      NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

