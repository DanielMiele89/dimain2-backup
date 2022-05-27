CREATE TABLE [Selections].[OPE_Validation_Reviewed] (
    [PartnerName]       VARCHAR (50)  NULL,
    [AccountManager]    VARCHAR (50)  NULL,
    [ClientServicesRef] VARCHAR (10)  NULL,
    [IronOfferName]     VARCHAR (50)  NULL,
    [OfferSegment]      VARCHAR (50)  NULL,
    [IronOfferID]       INT           NULL,
    [CashbackRate]      INT           NULL,
    [BaseOffer]         VARCHAR (50)  NULL,
    [Status]            VARCHAR (100) NULL,
    [Weighting]         BIGINT        NULL
);


GO
CREATE CLUSTERED INDEX [CIX_OPEValidationReviewed_Weighting]
    ON [Selections].[OPE_Validation_Reviewed]([Weighting] DESC);

