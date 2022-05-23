CREATE TABLE [dbo].[PublisherManagedRetailers] (
    [ClubID]    INT      NOT NULL,
    [PartnerID] INT      NOT NULL,
    [StartDate] DATETIME NOT NULL,
    [EndDate]   DATETIME NULL,
    [ID]        INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    CONSTRAINT [pk_PublisherManagedRetailers_ClubIDPartnerIDStartDate] PRIMARY KEY CLUSTERED ([ClubID] ASC, [PartnerID] ASC, [StartDate] ASC)
);

