CREATE TABLE [InsightArchive].[GAS_MID_Tracker] (
    [RetailOutletID] INT           NOT NULL,
    [PartnerID]      INT           NOT NULL,
    [GAS_MID]        NVARCHAR (50) NOT NULL,
    [GAS_START_DATE] DATE          NULL,
    [MID]            VARCHAR (50)  NOT NULL,
    [Hashed_Dates]   DATETIME      NULL
);

