CREATE TABLE [Staging].[IronOffer_Campaign_HTM_PreLaunch] (
    [ClientServicesRef]   VARCHAR (40)    NULL,
    [PartnerID]           INT             NULL,
    [EPOCU]               VARCHAR (1)     NULL,
    [HTMSegment]          INT             NULL,
    [IronOfferID]         INT             NULL,
    [CashbackRate]        REAL            NULL,
    [CommissionRate]      NUMERIC (32, 2) NULL,
    [BaseOfferID]         INT             NULL,
    [Base_CashbackRate]   REAL            NULL,
    [Base_CommissionRate] NUMERIC (32, 2) NULL,
    [AboveBase]           INT             NULL,
    [isConditionalOffer]  BIT             NULL
);

