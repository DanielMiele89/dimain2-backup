CREATE TABLE [Staging].[Cards_20200108] (
    [ID]                  BIGINT           IDENTITY (1, 1) NOT NULL,
    [CardGUID]            UNIQUEIDENTIFIER NOT NULL,
    [ExternalCardID]      NVARCHAR (255)   NOT NULL,
    [PrimaryCustomerGUID] UNIQUEIDENTIFIER NOT NULL,
    [AccountGUID]         UNIQUEIDENTIFIER NULL,
    [BinRange]            VARCHAR (255)    NULL,
    [PanLastFour]         CHAR (4)         NULL,
    [HashedPan]           VARCHAR (255)    NULL,
    [NameOnCard]          NVARCHAR (255)   NULL,
    [CardTypeID]          INT              NOT NULL,
    [CreditOrDebit]       CHAR (16)        NOT NULL,
    [CardStatusID]        INT              NULL,
    [Expiry]              DATE             NULL,
    [CardStopCode]        INT              NULL,
    [ExternalCustomerID]  NVARCHAR (255)   NOT NULL,
    [ExternalCardSource]  NVARCHAR (255)   NULL,
    [LoadDate]            DATETIME2 (7)    NOT NULL,
    [FileName]            NVARCHAR (320)   NOT NULL
);

