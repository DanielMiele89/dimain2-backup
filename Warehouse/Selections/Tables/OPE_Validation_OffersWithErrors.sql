CREATE TABLE [Selections].[OPE_Validation_OffersWithErrors] (
    [IronOfferID]   INT            NOT NULL,
    [IronOfferName] NVARCHAR (200) NULL,
    [StartDate]     DATETIME       NULL,
    [EndDate]       DATETIME       NULL,
    [PartnerID]     INT            NULL,
    [NewOffer]      VARCHAR (14)   NULL,
    [Status]        VARCHAR (175)  NULL
);

