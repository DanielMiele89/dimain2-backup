CREATE TABLE [dbo].[DirectDebitOfferOINs] (
    [IronOfferID]             INT NOT NULL,
    [OIN]                     INT NOT NULL,
    [DirectDebitOriginatorID] INT NOT NULL,
    CONSTRAINT [pk_DirectDebitOfferOINs_IOID_DDOID] PRIMARY KEY CLUSTERED ([IronOfferID] ASC, [DirectDebitOriginatorID] ASC)
);

