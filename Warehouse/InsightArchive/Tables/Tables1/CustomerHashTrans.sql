CREATE TABLE [InsightArchive].[CustomerHashTrans] (
    [ID]                          INT           IDENTITY (1, 1) NOT NULL,
    [HashIdentifier]              VARCHAR (500) NOT NULL,
    [ProxyUserID]                 INT           NOT NULL,
    [AuthorisationDate]           DATE          NOT NULL,
    [MerchantMIDNumber]           VARCHAR (50)  NOT NULL,
    [MerchantDescriptor]          VARCHAR (52)  NOT NULL,
    [MCCCode]                     VARCHAR (4)   NOT NULL,
    [MerchantLocation]            VARCHAR (52)  NOT NULL,
    [TransactionAmount]           MONEY         NOT NULL,
    [CurrencyCode]                VARCHAR (3)   NOT NULL,
    [CardholderPresentFlag]       TINYINT       NOT NULL,
    [CardType]                    VARCHAR (5)   NOT NULL,
    [CardholderLocationIndicator] VARCHAR (4)   NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

