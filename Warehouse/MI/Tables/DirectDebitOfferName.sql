CREATE TABLE [MI].[DirectDebitOfferName] (
    [AdditionalCashbackAwardTypeID] TINYINT      NOT NULL,
    [DDOfferName]                   VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_MI_DirectDebitOfferName] PRIMARY KEY CLUSTERED ([AdditionalCashbackAwardTypeID] ASC)
);

