CREATE TABLE [Relational].[MIDTrackingGAS] (
    [ID]             INT           IDENTITY (1, 1) NOT NULL,
    [PartnerID]      INT           NULL,
    [RetailOutletID] INT           NULL,
    [MID_GAS]        NVARCHAR (50) NULL,
    [MID_Join]       NVARCHAR (50) NULL,
    [StartDate]      DATE          NULL,
    [EndDate]        DATE          NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);




GO
CREATE NONCLUSTERED INDEX [CIX_MIDTrackingGAS_PartnerStartDateMID]
    ON [Relational].[MIDTrackingGAS]([PartnerID] ASC, [StartDate] ASC, [MID_Join] ASC)
    INCLUDE([EndDate]);


GO
CREATE NONCLUSTERED INDEX [IX_MIDTrackingGAS_OuletMIDEndDate]
    ON [Relational].[MIDTrackingGAS]([RetailOutletID] ASC, [MID_GAS] ASC, [MID_Join] ASC, [EndDate] ASC);


GO
GRANT SELECT
    ON OBJECT::[Relational].[MIDTrackingGAS] TO [visa_etl_user]
    AS [dbo];

