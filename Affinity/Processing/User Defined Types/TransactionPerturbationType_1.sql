CREATE TYPE [Processing].[TransactionPerturbationType] AS TABLE (
    [FileID]                     INT            NOT NULL,
    [RowNum]                     INT            NOT NULL,
    [ConsumerCombinationID]      INT            NULL,
    [CardholderPresentData]      TINYINT        NOT NULL,
    [TranDate]                   DATE           NOT NULL,
    [Amount]                     MONEY          NOT NULL,
    [FanID]                      INT            NOT NULL,
    [ProxyUserID]                VARBINARY (32) NOT NULL,
    [ProxyMIDTupleID]            BINARY (32)    NULL,
    [CurrencyCode]               VARCHAR (3)    NOT NULL,
    [CardholderPresentFlag]      VARCHAR (1)    NOT NULL,
    [CardType]                   VARCHAR (1)    NOT NULL,
    [CardholderPostalArea]       VARCHAR (4)    NULL,
    [SourceUID]                  VARCHAR (20)   NOT NULL,
    [CardholderPostcodeDistrict] VARCHAR (10)   NULL,
    [TransSequenceID]            BINARY (32)    NOT NULL,
    [Prefix]                     VARCHAR (4)    NOT NULL);

