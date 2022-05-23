CREATE TABLE [dbo].[PartnerOffer] (
    [ID]        INT           IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [PartnerID] INT           NOT NULL,
    [Offertype] NVARCHAR (50) NOT NULL,
    CONSTRAINT [PK_PartnerOffer] PRIMARY KEY CLUSTERED ([ID] ASC)
);

