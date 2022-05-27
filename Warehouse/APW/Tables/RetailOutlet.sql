CREATE TABLE [APW].[RetailOutlet] (
    [OutletID]  INT     NOT NULL,
    [PartnerID] INT     NOT NULL,
    [Channel]   TINYINT NOT NULL,
    CONSTRAINT [PK_APW_RetailOutlet] PRIMARY KEY CLUSTERED ([OutletID] ASC)
);

