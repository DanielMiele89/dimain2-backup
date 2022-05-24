CREATE TABLE [Relational].[MIDTrackingGAS_V2] (
    [ID]             INT           IDENTITY (1, 1) NOT NULL,
    [PartnerID]      INT           NULL,
    [RetailOutletID] INT           NULL,
    [MerchantID]     NVARCHAR (50) NULL,
    [StartDate]      DATE          NULL,
    [EndDate]        DATE          NULL
);

