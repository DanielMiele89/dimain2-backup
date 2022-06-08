CREATE TABLE [dbo].[MemberOfferAssociation] (
    [offerID]     INT            NULL,
    [Priority]    INT            NULL,
    [PartnerID]   INT            NULL,
    [PartnerName] NVARCHAR (200) NULL,
    [SourceUID]   VARCHAR (20)   NULL,
    [StartDate]   DATETIME       NULL,
    [EndDate]     DATETIME       NULL,
    [Chunk]       INT            NULL,
    [ID]          INT            IDENTITY (1, 1) NOT NULL
);

