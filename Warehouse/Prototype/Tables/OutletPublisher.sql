CREATE TABLE [Prototype].[OutletPublisher] (
    [ID]             INT          IDENTITY (1, 1) NOT NULL,
    [RetailOutletID] INT          NULL,
    [PartnerID]      INT          NULL,
    [MerchantID]     VARCHAR (50) NULL,
    [PublisherID]    INT          NULL,
    [OutletStatusID] INT          NULL,
    [StartDate]      DATE         NULL,
    [EndDate]        DATE         NULL
);

