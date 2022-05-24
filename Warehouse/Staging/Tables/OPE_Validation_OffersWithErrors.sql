CREATE TABLE [Staging].[OPE_Validation_OffersWithErrors] (
    [IronOfferID]   INT            NOT NULL,
    [IronOfferName] NVARCHAR (200) NOT NULL,
    [StartDate]     DATETIME       NULL,
    [EndDate]       DATETIME       NULL,
    [PartnerID]     INT            NOT NULL,
    [ClubID]        INT            NULL,
    [OfferType]     VARCHAR (14)   NOT NULL,
    [Status]        VARCHAR (100)  NULL
);

