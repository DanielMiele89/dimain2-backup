CREATE TABLE [Zoe].[Affinity_TransToBeAssessed] (
    [ProxyUserID]           INT             NOT NULL,
    [AuthorisationDate]     DATE            NOT NULL,
    [MerchantID]            VARCHAR (20)    NOT NULL,
    [BrandName]             VARCHAR (50)    NULL,
    [MerchantDescriptor]    VARCHAR (50)    NULL,
    [MCCCode]               INT             NOT NULL,
    [MerchantLocation]      VARCHAR (50)    NULL,
    [MerchantPostcode]      VARCHAR (15)    NULL,
    [TransactionAmount]     DECIMAL (10, 2) NOT NULL,
    [CurrencyCode]          VARCHAR (5)     NOT NULL,
    [CardholderPresentFlag] VARCHAR (3)     NOT NULL,
    [CardType]              VARCHAR (10)    NOT NULL,
    [PerturbedAmount]       DECIMAL (15, 8) NULL,
    [Variance]              DECIMAL (12, 5) NULL,
    [RandomNumber]          DECIMAL (7, 5)  NULL,
    [CardholderPostcode]    VARCHAR (10)    NULL,
    [CINID]                 INT             NULL
);

