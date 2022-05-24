CREATE TABLE [APW].[DirectLoad_RetailOutlet] (
    [OutletID]               INT           NOT NULL,
    [PartnerID]              INT           NOT NULL,
    [Channel]                TINYINT       NOT NULL,
    [PartnerOutletReference] NVARCHAR (20) NULL,
    CONSTRAINT [PK_APW_DirectLoad_RetailOutlet] PRIMARY KEY CLUSTERED ([OutletID] ASC)
);

