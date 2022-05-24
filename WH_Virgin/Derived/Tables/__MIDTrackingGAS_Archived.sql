CREATE TABLE [Derived].[__MIDTrackingGAS_Archived] (
    [ID]             INT           IDENTITY (1, 1) NOT NULL,
    [PartnerID]      INT           NULL,
    [RetailOutletID] INT           NULL,
    [MID_GAS]        NVARCHAR (50) NULL,
    [MID_Join]       NVARCHAR (50) NULL,
    [StartDate]      DATE          NULL,
    [EndDate]        DATE          NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

