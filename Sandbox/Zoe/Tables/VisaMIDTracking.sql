CREATE TABLE [Zoe].[VisaMIDTracking] (
    [PartnerID]                   INT            NOT NULL,
    [PartnerName]                 NVARCHAR (100) NOT NULL,
    [EverHadOffer]                INT            NOT NULL,
    [HasLiveOffer]                INT            NOT NULL,
    [HasLiveOfferWithMemberships] INT            NOT NULL,
    [MIDs]                        INT            NULL
);

