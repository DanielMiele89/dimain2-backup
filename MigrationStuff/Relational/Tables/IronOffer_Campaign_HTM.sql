CREATE TABLE [Relational].[IronOffer_Campaign_HTM] (
    [ID]                  INT             IDENTITY (1, 1) NOT NULL,
    [ClientServicesRef]   VARCHAR (40)    NOT NULL,
    [PartnerID]           INT             NULL,
    [EPOCU]               VARCHAR (1)     NULL,
    [HTMSegment]          INT             NULL,
    [IronOfferID]         INT             NOT NULL,
    [CashbackRate]        REAL            NULL,
    [CommissionRate]      NUMERIC (32, 2) NULL,
    [BaseOfferID]         INT             NULL,
    [Base_CashbackRate]   REAL            NULL,
    [Base_CommissionRate] NUMERIC (32, 2) NULL,
    [AboveBase]           INT             NULL,
    [isConditionalOffer]  BIT             NULL,
    [isExtension]         BIT             NULL
);

