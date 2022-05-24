CREATE TABLE [Staging].[OPE_Validation_Reviewed] (
    [PartnerName]       VARCHAR (50)   NULL,
    [AccountManager]    VARCHAR (50)   NULL,
    [ClientServicesRef] VARCHAR (8)    NULL,
    [IronOfferName]     VARCHAR (50)   NULL,
    [OfferSegment]      VARCHAR (50)   NULL,
    [IronOfferID]       INT            NULL,
    [CashbackRate]      DECIMAL (5, 2) NULL,
    [CoreBaseOffer]     VARCHAR (50)   NULL,
    [EndDate]           DATE           NULL,
    [Status]            VARCHAR (100)  NULL,
    [Weighting]         BIGINT         NULL
);

